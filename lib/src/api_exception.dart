import 'dart:convert';

import 'package:http/http.dart';

enum GenericAPIError { connectionFailure, unauthorized, serializer, unknown }

/// Represent failure exception from the API Provider.
class ApiException implements Exception {
  const ApiException({
    this.statusCode = -1,
    this.error = GenericAPIError.unknown,
    this.parent,
  });

  final int statusCode;
  final GenericAPIError error;

  /// Represent a parent exception, if any found
  final dynamic parent;

  /// Timeout exception or connection failure
  ApiException.timeout()
    : statusCode = -1,
      error = GenericAPIError.connectionFailure,
      parent = null;

  /// Json Data Serialized exception
  ApiException.serializer(FormatException exception)
    : statusCode = -1,
      error = GenericAPIError.serializer,
      parent = null;

  /// unknown error
  ApiException.unknown(this.parent)
    : statusCode = -1,
      error = GenericAPIError.unknown;

  /// status code
  ApiException.statusCode(BaseResponse response)
    : statusCode = response.statusCode,
      error = response.statusCode == 401
          ? GenericAPIError.unauthorized
          : GenericAPIError.unknown,
      parent = response;

  String get message {
    final buffer = StringBuffer('ApiException');
    if (statusCode != -1) {
      buffer.write('($statusCode)');
    }

    buffer.write(': $error');

    if (parent != null) {
      buffer.writeln(', caused by:');
      if (parent is Response) {
        final response = parent as Response;
        final responseBody = response.body;
        if (responseBody.isNotEmpty) {
          buffer.write('Rest: ');

          /// Do not assume response body will be a proper json object.
          dynamic jsonData;
          try {
            jsonData = jsonDecode(responseBody);
            if (jsonData['message'] != null) {
              buffer.write(jsonData['message']);
              if (jsonData['debugMessage'] != null) {
                buffer.write(', ');
                buffer.write(jsonData['debugMessage']);
              }
            }
          } catch (e) {
            buffer.write(responseBody);
          }
          buffer.writeln();
        }
      }
    } else {
      buffer.write('');
    }
    return buffer.toString();
  }
}
