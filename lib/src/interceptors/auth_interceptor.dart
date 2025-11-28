import 'dart:io';
import 'package:http/http.dart';
import '../auth/token_manager.dart';
import 'restigo_interceptor.dart';

/// AuthInterceptor automatically adds an Authorization header to requests
/// and handles 401 Unauthorized responses by attempting token refresh.
///
/// It is designed to be used with [RestigoClient].
class AuthInterceptor implements RestigoInterceptor {
  /// Creates an AuthInterceptor
  ///
  /// [tokenManager] manages access/refresh tokens.
  /// [client] is used to retry requests after a successful token refresh.
  /// [onUnauthorized] is called when the refresh fails.
  AuthInterceptor({
    required this.tokenManager,
    required this.client,
    this.onUnauthorized,
  });

  final TokenManager tokenManager;

  /// The HTTP client to retry failed requests
  final Client client;

  /// Optional callback when token refresh fails
  final Future<void> Function()? onUnauthorized;

  /// Adds the access token to outgoing requests, except the token endpoint itself
  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    // Skip adding token to the token refresh request
    if (request.url == tokenManager.tokenUri) return request;

    final token = await tokenManager.getAccessToken();
    if (token != null) {
      request.headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    }
    return request;
  }

  /// Handles 401 responses:
  /// - Attempts to refresh the token
  /// - Retries the original request once if refresh succeeds
  /// - Calls [onUnauthorized] if refresh fails
  @override
  Future<StreamedResponse> onResponse(StreamedResponse response) async {
    if (response.statusCode != 401) return response;

    // Attempt token refresh
    final refreshed = await tokenManager.refreshToken();

    if (!refreshed) {
      // Refresh failed: clear tokens and call onUnauthorized
      await tokenManager.clearTokens();
      await onUnauthorized?.call();
      return response;
    }

    // Refresh succeeded: retry the original request
    final original = response.request;
    if (original == null) {
      throw StateError('Cannot retry: original request is missing.');
    }
    final cloned = await _clone(original);
    return client.send(cloned);
  }

  /// Clones an outgoing HTTP request
  ///
  /// Necessary for retrying requests after a 401 response.
  Future<BaseRequest> _clone(BaseRequest request) async {
    final clone = Request(request.method, request.url)
      ..headers.addAll(request.headers);

    // Copy request body if present
    final bytes = await request.finalize().toBytes();
    clone.bodyBytes = bytes;

    return clone;
  }
}
