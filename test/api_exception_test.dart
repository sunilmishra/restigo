import 'package:restigo/src/api_exception.dart';
import 'package:test/test.dart';

void main() {
  test('displays a message', () {
    const exception = ApiException();
    expect(exception.message, 'ApiException: GenericAPIError.unknown');
  });

  test('displays a status code', () {
    const exception = ApiException(statusCode: 404);
    expect(exception.message, 'ApiException(404): GenericAPIError.unknown');
  });
}
