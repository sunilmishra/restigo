import 'dart:developer';

import 'package:http/http.dart';
import 'dart:convert';

import '../storage/credential_store.dart';

abstract class TokenManager {
  Uri get tokenUri;

  Future<String?> getAccessToken();
  Future<bool> refreshToken();
  Future<void> clearTokens();
}

class DefaultTokenManager implements TokenManager {
  DefaultTokenManager({
    required this.tokenUri,
    required this.credentialStore,
    required this.httpClient,
  });

  @override
  final Uri tokenUri;
  final CredentialStore credentialStore;
  final Client httpClient;

  @override
  Future<String?> getAccessToken() async => await credentialStore.accessToken;

  @override
  Future<bool> refreshToken() async {
    final refresh = await credentialStore.refreshToken;
    if (refresh == null) return false;

    try {
      final response = await httpClient.post(
        tokenUri,
        body: {"refresh_token": refresh},
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);

      credentialStore.accessToken = data["access_token"];
      credentialStore.refreshToken = data["refresh_token"] ?? refresh;

      return true;
    } catch (e) {
      log('Error refreshing token: $e');
      return false;
    }
  }

  @override
  Future<void> clearTokens() async => credentialStore.clear();
}
