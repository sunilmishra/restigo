import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:restigo/restigo.dart';
import 'package:test/test.dart';

void main() {
  final fakeTokenUrl = Uri.https('fake.example', 'oauth2/token');

  final fakeUrl = Uri.https('fake.example', '/');

  test('has bearer header when authorized', () {
    final callback = expectAsync1<Future<Response>, Request>((request) async {
      expect(request.headers['Authorization'], 'Bearer mock-access-token');
      return Response('', 200);
    });

    final client = Restigo(
      httpClient: MockClient(callback),
      credentialStore: MockCredentialStore(),
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    client.post(fakeUrl);
  });

  test('token refresh calls have a special authorization-less path', () {
    final callback = expectAsync1<Future<Response>, Request>((request) async {
      expect(request.headers['Authorization'], isNull);
      return Response('', 200);
    });

    final client = Restigo(
      httpClient: MockClient(callback),
      credentialStore: MockCredentialStore(),
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    client.post(fakeTokenUrl);
  });

  test('refresh that returns 401 unauthorizes', () async {
    final callback = expectAsync1<Future<Response>, Request>((request) async {
      return Response('', 401);
    }, count: 2);
    final unauthorizedCallback = expectAsync0(() {});

    final client = Restigo(
      httpClient: MockClient(callback),
      credentialStore: MockCredentialStore(),
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      unAuthorizedCallback: unauthorizedCallback,
    );
    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isException);
    }
  });

  test('http 401 will refresh an access token, basic request', () async {
    /// Three calls are made to this mock client:
    /// 1. The initial call, which returns an unauthorized 401
    /// 2. The second call to the token endpoint (fakeTokenUrl)
    /// 3. The repeat initial call, which no longer is unauthorized.
    bool latch = false;
    final callback = expectAsync1<Future<Response>, Request>((request) async {
      if (!latch) {
        latch = !latch;
        return Response('expect_me', 401);
      }

      if (request.url == fakeTokenUrl) {
        request.headers.addAll({
          'Content-Type': 'application/x-www-form-urlencoded',
        });

        expect(request.bodyFields['refresh_token'], 'mock-refresh-token');
        // Return some fake token
        final fake = {'id_token': 'blah'};

        return Response(json.encode(fake), 200, headers: fake);
      }

      // The body, previously intended to be sent by the original POST, should
      // continue to be here after the reauth.
      expect(request.body, 'expect_me');
      return Response('intended_response', 200);
    }, count: 3);

    final tokenStore = MockCredentialStore();
    final client = Restigo(
      httpClient: MockClient(callback),
      credentialStore: tokenStore,
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );
    final response = await client.post(fakeUrl, body: 'expect_me');

    // Verify the fake 'blah' token was taken
    expect(await tokenStore.accessToken, 'mock-access-token');

    // Verify that the intended response is received
    expect(response.body, 'intended_response');
  });

  test('throws formatting errors', () async {
    final client = Restigo(
      tokenUrl: fakeTokenUrl,
      credentialStore: MockCredentialStore(),
      configuration: const ServerConfiguration(url: '', clientId: ''),
      httpClient: MockClient((request) async {
        throw const FormatException('This thing looks funny.');
      }),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isA<ApiException>());
      final exception = e as ApiException;
      expect(exception.error, GenericAPIError.serializer);
    }
  });

  test('throws timeout errors, socket exception', () async {
    final client = Restigo(
      tokenUrl: fakeTokenUrl,
      credentialStore: MockCredentialStore(),
      configuration: const ServerConfiguration(url: '', clientId: ''),
      httpClient: MockClient((request) async {
        throw const SocketException('Uh-oh');
      }),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isA<ApiException>());
      final exception = e as ApiException;
      expect(exception.error, GenericAPIError.connectionFailure);
    }
  });

  test('throws timeout errors, timeout exception', () async {
    final client = Restigo(
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      credentialStore: MockCredentialStore(),
      httpClient: MockClient((request) async {
        throw TimeoutException('Uh-oh');
      }),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isA<ApiException>());
      final exception = e as ApiException;
      expect(exception.error, GenericAPIError.connectionFailure);
    }
  });

  test('throws unknown errors, http exception', () async {
    final client = Restigo(
      tokenUrl: fakeTokenUrl,
      configuration: const ServerConfiguration(url: '', clientId: ''),
      credentialStore: MockCredentialStore(),
      httpClient: MockClient((request) async {
        throw const HttpException('Failed.');
      }),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isA<ApiException>());
      final exception = e as ApiException;
      expect(exception.error, GenericAPIError.unknown);
    }
  });

  test('throws unknown errors, client exception', () async {
    final client = Restigo(
      tokenUrl: fakeTokenUrl,
      credentialStore: MockCredentialStore(),
      configuration: const ServerConfiguration(url: '', clientId: ''),
      httpClient: MockClient((request) async {
        throw ClientException('Failed.');
      }),
      unAuthorizedCallback: () {
        log('UnAuthorized Callback Happened');
      },
    );

    try {
      await client.post(fakeUrl);
    } catch (e) {
      expect(e, isA<ApiException>());
      final exception = e as ApiException;
      expect(exception.error, GenericAPIError.unknown);
    }
  });
}

class MockCredentialStore extends Mock implements CredentialStore {
  @override
  Future<String?> get accessToken => Future.value('mock-access-token');

  @override
  Future<String?> get refreshToken => Future.value('mock-refresh-token');
}
