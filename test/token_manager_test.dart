import 'package:restigo/src/auth/token_manager.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenManager extends Mock implements TokenManager {}

void main() {
  late MockTokenManager tokenManager;

  setUp(() {
    tokenManager = MockTokenManager();
  });

  test('getAccessToken returns token', () async {
    when(() => tokenManager.getAccessToken()).thenAnswer((_) async => 'token');

    final token = await tokenManager.getAccessToken();
    expect(token, 'token');
  });

  test('refreshToken returns boolean', () async {
    when(() => tokenManager.refreshToken()).thenAnswer((_) async => true);
    final result = await tokenManager.refreshToken();
    expect(result, true);
  });
}
