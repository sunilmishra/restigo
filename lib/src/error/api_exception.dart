import 'dart:convert';
import 'package:http/http.dart';

enum GenericAPIError { connectionFailure, unauthorized, serializer, unknown }

/// Represents an API failure with structured information.
class ApiException implements Exception {
  const ApiException({
    this.statusCode = -1,
    this.error = GenericAPIError.unknown,
    this.parent,
  });

  final int statusCode;
  final GenericAPIError error;
  final dynamic parent;

  /// Timeout / network failure
  ApiException.timeout()
    : statusCode = -1,
      error = GenericAPIError.connectionFailure,
      parent = null;

  /// JSON serialization error
  ApiException.serializer(FormatException e)
    : statusCode = -1,
      error = GenericAPIError.serializer,
      parent = e;

  /// Unknown error
  ApiException.unknown(this.parent)
    : statusCode = -1,
      error = GenericAPIError.unknown;

  /// Status-code based failure
  ApiException.statusCode(BaseResponse response)
    : statusCode = response.statusCode,
      error = response.statusCode == 401
          ? GenericAPIError.unauthorized
          : GenericAPIError.unknown,
      parent = response;

  /// Combined error message
  String get message {
    final sb = StringBuffer("ApiException");

    if (statusCode != -1) sb.write("($statusCode)");

    sb.write(": $error");

    if (parent is Response) {
      final body = (parent as Response).body;
      if (body.isNotEmpty) {
        try {
          final json = jsonDecode(body);
          sb.write(" → ${json['message'] ?? body}");
        } catch (_) {
          sb.write(" → $body");
        }
      }
    }

    return sb.toString();
  }

  @override
  String toString() => message;
}
