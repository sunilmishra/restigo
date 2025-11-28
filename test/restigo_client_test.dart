import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:restigo/src/restigo_client.dart';
import 'package:restigo/src/error/api_exception.dart';
import 'mocks/mock_interceptor.dart';
import 'mocks/mock_client.dart';

class BaseRequestFake extends Fake implements BaseRequest {}

class StreamedResponseFake extends Fake implements StreamedResponse {}

void main() {
  setUpAll(() {
    registerFallbackValue(BaseRequestFake());
    registerFallbackValue(StreamedResponseFake());
  });

  late MockClient mockClient;
  late MockInterceptor mockInterceptor;
  late RestigoClient client;

  setUp(() {
    mockClient = MockClient();
    mockInterceptor = MockInterceptor();
    final builder = RestigoBuilder(
      baseUrl: 'api.example.com',
      client: mockClient,
    )..addMockInterceptor(mockInterceptor);
    client = builder.build();
  });

  test('applies request and response interceptors', () async {
    final request = Request('GET', Uri.https('api.example.com', '/test'));
    final response = StreamedResponse(Stream.value([]), 200);
    when(
      () => mockInterceptor.onRequest(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);
    when(() => mockClient.send(any())).thenAnswer((_) async => response);
    when(
      () => mockInterceptor.onResponse(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);

    final result = await client.send(request);
    expect(result.statusCode, 200);
    verify(() => mockInterceptor.onRequest(any())).called(1);
    verify(() => mockInterceptor.onResponse(any())).called(1);
  });

  test('throws ApiException.timeout on TimeoutException', () async {
    final request = Request('GET', Uri.https('api.example.com', '/timeout'));
    when(
      () => mockInterceptor.onRequest(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);
    when(() => mockClient.send(any())).thenThrow(TimeoutException('timeout'));

    expect(
      () async => await client.send(request),
      throwsA(isA<ApiException>()),
    );
  });

  test('throws ApiException.timeout on SocketException', () async {
    final request = Request('GET', Uri.https('api.example.com', '/socket'));
    when(
      () => mockInterceptor.onRequest(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);
    when(
      () => mockClient.send(any()),
    ).thenThrow(const SocketException('socket'));

    expect(
      () async => await client.send(request),
      throwsA(isA<ApiException>()),
    );
  });

  test('throws ApiException.serializer on FormatException', () async {
    final request = Request('GET', Uri.https('api.example.com', '/format'));
    when(
      () => mockInterceptor.onRequest(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);
    when(
      () => mockClient.send(any()),
    ).thenThrow(const FormatException('bad format'));

    expect(
      () async => await client.send(request),
      throwsA(isA<ApiException>()),
    );
  });

  test('throws ApiException.unknown on unknown error', () async {
    final request = Request('GET', Uri.https('api.example.com', '/unknown'));
    when(
      () => mockInterceptor.onRequest(any()),
    ).thenAnswer((inv) async => inv.positionalArguments[0]);
    when(() => mockClient.send(any())).thenThrow(Exception('unknown'));

    expect(
      () async => await client.send(request),
      throwsA(isA<ApiException>()),
    );
  });

  test('resolve returns correct Uri', () {
    final uri = client.resolve('/foo', {'bar': 'baz'});
    expect(uri.toString(), 'https://api.example.com/foo?bar=baz');
  });
}
