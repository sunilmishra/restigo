import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';

import 'api_exception.dart';
import 'server_config.dart';
import 'storage/credential_store.dart';

/// A Generic Http client.
class Restigo extends BaseClient {
  Restigo({
    Client? httpClient,
    required CredentialStore credentialStore,
    this.timeout = const Duration(seconds: 15),
    required this.configuration,
    required this.tokenUrl,
    required this.unAuthorizedCallback,
    this.shouldLog = true,
  }) : _client = httpClient ?? Client(),
       _credentialStore = credentialStore;

  final Client _client;
  final CredentialStore _credentialStore;
  final Duration timeout;
  final ServerConfiguration configuration;

  final Uri tokenUrl;
  final Function() unAuthorizedCallback;
  final bool shouldLog;

  /// Required when server returns different key for the accessToken or refreshToken.
  String _accessTokenKey = 'access_token';
  set accessTokenKey(String key) => _accessTokenKey = key;
  String _refreshTokenKey = 'refresh_token';
  set refreshTokenKey(String key) => _refreshTokenKey = key;

  /// Required when LoginAPI expect requestbody keys otherthan [username] and [password].
  String _usernameKey = 'username';
  set usernameKey(String key) => _usernameKey = key;
  String _passwordKey = 'password';
  set passwordKey(String key) => _passwordKey = key;

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    _logRequest(url, method: 'GET', headers: headers);
    final response = await super.get(url, headers: headers);
    _logResponse(url, response);
    return response;
  }

  @override
  Future<Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    _logRequest(url, method: 'POST', headers: headers, body: body);
    final response = await super.post(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    _logResponse(url, response);
    return response;
  }

  @override
  Future<Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    _logRequest(url, method: 'PUT', headers: headers, body: body);
    final response = await super.post(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    _logResponse(url, response);
    return response;
  }

  @override
  Future<Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    _logRequest(url, method: 'DELETE', headers: headers, body: body);
    final response = await super.delete(
      url,
      headers: headers,
      body: body,
      encoding: encoding,
    );
    _logResponse(url, response);
    return response;
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers[HttpHeaders.contentTypeHeader] = 'application/json';

    /// Special code path for refresh tokens only.
    /// Prevent Looping
    if (request.url == tokenUrl) {
      return _client.send(request).timeout(timeout);
    }

    try {
      final accessToken = await _credentialStore.accessToken;

      /// set the headers data
      if (accessToken != null) {
        request.headers[HttpHeaders.authorizationHeader] =
            'Bearer $accessToken';
      }

      final streamedResponse = await _client.send(request).timeout(timeout);

      /// Refresh the token
      if (streamedResponse.statusCode == HttpStatus.unauthorized) {
        final existingRefreshToken = await _credentialStore.refreshToken;
        final success = existingRefreshToken != null
            ? await _refreshTokenUsingOuth()
            : await _refreshToken();

        if (!success) {
          _credentialStore.accessToken = null;
          _credentialStore.refreshToken = null;

          final response = await Response.fromStream(streamedResponse);
          throw ApiException.statusCode(response);
        }

        /// if Success, Re-send the intended request again!
        late BaseRequest copy;
        if (request is Request) {
          copy = Request(request.method, request.url)
            ..encoding = request.encoding
            ..bodyBytes = request.bodyBytes;
        } else {
          throw Exception('$request does not support retry');
        }

        copy
          ..persistentConnection = request.persistentConnection
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects
          ..headers.addAll(request.headers);

        return send(copy);
      }

      /// Throw Exception if not success
      if (streamedResponse.statusCode >= 300) {
        final response = await Response.fromStream(streamedResponse);
        throw ApiException.statusCode(response);
      }

      /// finally return sucess.
      return streamedResponse;
    } on ClientException catch (e) {
      throw ApiException.unknown(e);
    } on HttpException catch (e) {
      throw ApiException.unknown(e);
    } on FormatException catch (e) {
      throw ApiException.serializer(e);
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.timeout();
    }
  }

  /// Refresh the token using Outh2.0 mechanism.
  Future<bool> _refreshTokenUsingOuth() async {
    final refreshToken = await _credentialStore.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      log('No Refresh required....');
      return false;
    }

    final response = await super.post(
      tokenUrl,
      body: {_refreshTokenKey: refreshToken},
    );
    if (response.statusCode != 200) {
      log('failed to refresh the token ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 400) {
        /// Logout the user
        unAuthorizedCallback();
      }
      return false;
    }

    final Map<String, dynamic> refreshBody = jsonDecode(response.body);
    _credentialStore.accessToken = refreshBody[_accessTokenKey];
    log('Token refreshed successfully....');
    return true;
  }

  /// Refreshing the token with existing username and password.
  Future<bool> _refreshToken() async {
    final userName = await _credentialStore.username;
    if (userName == null) {
      log('No Refresh required using Credential....');
      return false;
    }

    /// create credential request object.
    final password = await _credentialStore.password;
    var userCredential = {_usernameKey: userName, _passwordKey: password};

    final response = await super.post(tokenUrl, body: userCredential);
    if (response.statusCode != 200) {
      log('failed to refresh the token using credential: ${response.body}');

      if (response.statusCode == 401 || response.statusCode == 400) {
        /// Logout the user
        unAuthorizedCallback();
      }
      return false;
    }

    final Map<String, dynamic> refreshBody = jsonDecode(response.body);
    _credentialStore.accessToken = refreshBody[_accessTokenKey];
    log('Token has been refreshed successfully using credentials.....');
    return true;
  }

  void _logRequest(
    Uri url, {
    String? method,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!shouldLog) return;
    final logMessage =
        '''
------------------------ API REQUEST -------------------------------------------
API REQUEST:
  * Request: $method $url
  * Headers: $headers
  * Body: $body
--------------------------------------------------------------------------------
\n''';
    log(logMessage);
  }

  void _logResponse(Uri url, Response response) {
    if (!shouldLog) return;
    final logMessage =
        '''
-------------------------API RESPONSE:-----------------------------------------
  * Request URL: $url
  * Status: ${response.statusCode}
  * Headers: ${response.headers}
  * Body: ${response.body}
--------------------------------------------------------------------------------
\n''';
    log(logMessage);
  }

  /// Resolves a REST endpoint given a [path].
  ///
  /// The returned [Uri] has an authority defined by [configuration]
  /// Can optionally specify a Map containing query parameters.
  Uri resolveEndpoint(String path, [Map<String, String>? queryParams]) {
    return Uri.https(configuration.url, path, queryParams);
  }
}
