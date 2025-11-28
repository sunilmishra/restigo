import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:restigo/src/storage/credential_store.dart';
import 'package:restigo/src/storage/secure_storage.dart';
import 'auth/token_manager.dart';
import 'error/api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/restigo_interceptor.dart';

part 'restigo_builder.dart';

/// A REST client that supports interceptors and error handling.
class RestigoClient extends BaseClient {
  RestigoClient._internal({
    required this.baseUrl,
    this.interceptors = const [],
    Client? httpClient,
    this.defaultHeaders,
    Duration? timeout,
  }) : _httpClient = httpClient ?? Client(),
       _timeout = timeout ?? const Duration(seconds: 15);

  final String baseUrl;
  final List<RestigoInterceptor> interceptors;
  final Client _httpClient;
  final Map<String, String>? defaultHeaders;
  final Duration _timeout;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    /// Add default headers if provided otherwise set common json headers
    if (defaultHeaders != null) {
      request.headers.addAll(defaultHeaders!);
    } else {
      request.headers[HttpHeaders.contentTypeHeader] = 'application/json';
      request.headers[HttpHeaders.acceptHeader] = 'application/json';
    }

    /// Handle the request with interceptors and error handling
    try {
      // 1. Apply request interceptors
      for (final i in interceptors) {
        request = await i.onRequest(request);
      }

      // 2. Perform network call
      var response = await _httpClient.send(request).timeout(_timeout);

      // 3. Apply response interceptors
      for (final i in interceptors) {
        response = await i.onResponse(response);
      }

      return response;
    } on TimeoutException {
      throw ApiException.timeout();
    } on SocketException {
      throw ApiException.timeout();
    } on FormatException catch (e) {
      throw ApiException.serializer(e);
    } catch (e) {
      throw ApiException.unknown(e);
    }
  }

  /// Resolves the full URI for the given [path] and optional [query] parameters.
  Uri resolve(String path, [Map<String, String>? query]) {
    return Uri.https(baseUrl, path, query);
  }
}
