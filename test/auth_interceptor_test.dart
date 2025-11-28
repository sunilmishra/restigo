import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:restigo/src/interceptors/auth_interceptor.dart';
import 'mocks/mock_token_manager.dart';
import 'mocks/mock_client.dart';

class BaseRequestFake extends Fake implements BaseRequest {}

class StreamedResponseFake extends Fake implements StreamedResponse {}

void main() {
  setUpAll(() {
    registerFallbackValue(BaseRequestFake());
    registerFallbackValue(StreamedResponseFake());
  });

  late MockTokenManager mockTokenManager;
  late MockClient mockClient;
  late AuthInterceptor interceptor;

  setUp(() {
    mockTokenManager = MockTokenManager();
    mockClient = MockClient();
    interceptor = AuthInterceptor(
      tokenManager: mockTokenManager,
      client: mockClient,
    );
  });

  test('adds Authorization header if token exists', () async {
    final request = Request('GET', Uri.https('api.example.com', '/test'));
    when(() => mockTokenManager.tokenUri).thenReturn(fakeTokenUri);
    when(
      () => mockTokenManager.getAccessToken(),
    ).thenAnswer((_) async => 'token123');

    final result = await interceptor.onRequest(request);
    expect(result.headers[HttpHeaders.authorizationHeader], 'Bearer token123');
  });

  test('does not add Authorization header for token endpoint', () async {
    final request = Request('POST', fakeTokenUri);
    when(() => mockTokenManager.tokenUri).thenReturn(fakeTokenUri);
    final result = await interceptor.onRequest(request);
    expect(result.headers[HttpHeaders.authorizationHeader], isNull);
  });

  test('onResponse retries request after successful token refresh', () async {
    final request = Request('GET', Uri.https('api.example.com', '/data'));
    final response = StreamedResponse(Stream.value([]), 401, request: request);
    when(() => mockTokenManager.refreshToken()).thenAnswer((_) async => true);
    when(
      () => mockClient.send(any()),
    ).thenAnswer((_) async => StreamedResponse(Stream.value([]), 200));

    final result = await interceptor.onResponse(response);
    expect(result.statusCode, 200);
    verify(() => mockClient.send(any())).called(1);
  });

  test(
    'onResponse calls onUnauthorized and clears tokens if refresh fails',
    () async {
      final request = Request('GET', Uri.https('api.example.com', '/data'));
      final response = StreamedResponse(
        Stream.value([]),
        401,
        request: request,
      );
      var unauthorizedCalled = false;
      interceptor = AuthInterceptor(
        tokenManager: mockTokenManager,
        client: mockClient,
        onUnauthorized: () async {
          unauthorizedCalled = true;
        },
      );
      when(
        () => mockTokenManager.refreshToken(),
      ).thenAnswer((_) async => false);
      when(() => mockTokenManager.clearTokens()).thenAnswer((_) async {});

      final result = await interceptor.onResponse(response);
      expect(result.statusCode, 401);
      expect(unauthorizedCalled, isTrue);
      verify(() => mockTokenManager.clearTokens()).called(1);
    },
  );
}
