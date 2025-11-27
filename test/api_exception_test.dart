import 'dart:convert';
import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:restigo/src/error/api_exception.dart';

void main() {
  group('ApiException', () {
    test('timeout constructor sets error to connectionFailure', () {
      final ex = ApiException.timeout();
      expect(ex.error, GenericAPIError.connectionFailure);
      expect(ex.statusCode, -1);
      expect(ex.parent, isNull);
    });

    test('serializer constructor sets error to serializer', () {
      final fe = FormatException('bad json');
      final ex = ApiException.serializer(fe);
      expect(ex.error, GenericAPIError.serializer);
      expect(ex.statusCode, -1);
      expect(ex.parent, fe);
    });

    test('unknown constructor sets error to unknown', () {
      final ex = ApiException.unknown('foo');
      expect(ex.error, GenericAPIError.unknown);
      expect(ex.statusCode, -1);
      expect(ex.parent, 'foo');
    });

    test('statusCode constructor sets error to unauthorized for 401', () {
      final response = Response('unauthorized', 401);
      final ex = ApiException.statusCode(response);
      expect(ex.error, GenericAPIError.unauthorized);
      expect(ex.statusCode, 401);
      expect(ex.parent, response);
    });

    test('statusCode constructor sets error to unknown for non-401', () {
      final response = Response('not found', 404);
      final ex = ApiException.statusCode(response);
      expect(ex.error, GenericAPIError.unknown);
      expect(ex.statusCode, 404);
      expect(ex.parent, response);
    });

    test('message includes status code, error, and parent message', () {
      final response = Response(jsonEncode({'message': 'fail'}), 400);
      final ex = ApiException.statusCode(response);
      expect(ex.message, contains('400'));
      expect(ex.message, contains('unknown'));
      expect(ex.message, contains('fail'));
    });

    test('message falls back to body if not JSON', () {
      final response = Response('plain error', 500);
      final ex = ApiException.statusCode(response);
      expect(ex.message, contains('plain error'));
    });
  });
}
