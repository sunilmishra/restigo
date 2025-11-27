part of 'restigo_client.dart';

class RestigoBuilder {
  RestigoBuilder({required this.baseUrl});

  /// Base URL for the API.
  final String baseUrl;

  /// Custom HTTP client.
  Client? _client;

  /// Custom timeout duration.
  Duration? _timeout;

  /// List of interceptors to apply.
  final List<RestigoInterceptor> _interceptors = [];

  /// Callback for unauthorized access.
  Future<void> Function()? _onUnauthorized;

  /// Sets a custom HTTP client.
  RestigoBuilder setClient(Client client) {
    _client = client;
    return this;
  }

  /// Sets a custom timeout duration for requests.
  RestigoBuilder setTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// Enables logging of requests and responses.
  RestigoBuilder enableLogging() {
    _interceptors.add(LoggingInterceptor());
    return this;
  }

  /// Adds a custom interceptor, such as for mocking in tests.
  @visibleForTesting
  RestigoBuilder addMockInterceptor(RestigoInterceptor interceptor) {
    _interceptors.add(interceptor);
    return this;
  }

  /// Internal token manager used for authentication.
  TokenManager? _tokenManager;
  RestigoBuilder enableAuth({
    required Uri tokenUrl,
    Future<void> Function()? onUnauthorized,
  }) {
    final SecureStorage secureStorage = SecureStorageImpl();
    final CredentialStore credentialStore = CredentialStoreImpl(secureStorage);
    final manager = DefaultTokenManager(
      tokenUrl: tokenUrl,
      credentialStore: credentialStore,
    );
    _tokenManager = manager;
    _onUnauthorized = onUnauthorized;
    return this;
  }

  /// Builds and returns the [RestigoClient] instance.
  RestigoClient build() {
    if (_tokenManager != null) {
      // Remove any existing AuthInterceptor before adding a new one
      _interceptors.removeWhere((i) => i is AuthInterceptor);
      _interceptors.add(
        AuthInterceptor(
          tokenManager: _tokenManager!,
          client: _client ?? Client(),
          onUnauthorized: _onUnauthorized,
        ),
      );
    }

    return RestigoClient._internal(
      baseUrl: baseUrl,
      http: _client,
      timeout: _timeout,
      interceptors: _interceptors,
    );
  }
}
