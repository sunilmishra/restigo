part of 'restigo_client.dart';

class RestigoBuilder {
  RestigoBuilder({required this.baseUrl, Client? client})
    : _client = client ?? Client();

  /// Base URL for the API.
  final String baseUrl;

  /// Custom HTTP client.
  final Client _client;

  /// Headers to include in every request.
  Map<String, String>? _defaultHeaders;

  /// Custom timeout duration.
  Duration? _timeout;

  /// List of interceptors to apply.
  final List<RestigoInterceptor> _interceptors = [];

  /// Callback for unauthorized access.
  Future<void> Function()? _onUnauthorized;

  /// Sets default headers to include in every request.
  /// These can be overridden by request-specific headers.
  RestigoBuilder setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = headers;
    return this;
  }

  /// Sets a custom timeout duration for requests.
  RestigoBuilder setTimeout(Duration timeout) {
    _timeout = timeout;
    return this;
  }

  /// Enables logging of requests and responses.
  RestigoBuilder enableLogging({
    bool logHeaders = false,
    bool logBody = false,
  }) {
    _interceptors.add(
      LoggingInterceptor(logHeaders: logHeaders, logBody: logBody),
    );
    return this;
  }

  /// Adds a custom interceptor, such as for mocking in tests.
  @visibleForTesting
  RestigoBuilder addMockInterceptor(RestigoInterceptor interceptor) {
    _interceptors.add(interceptor);
    return this;
  }

  /// Resolve given token URL
  Uri _resolveTokenUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    return Uri.https(baseUrl, path);
  }

  /// Internal token manager used for authentication.
  TokenManager? _tokenManager;
  RestigoBuilder enableAuth({
    /// The token full URL or path(e.g: /auth/token) to obtain tokens
    required String tokenUrl,
    Future<void> Function()? onUnauthorized,
  }) {
    final SecureStorage secureStorage = SecureStorageImpl();
    final CredentialStore credentialStore = CredentialStoreImpl(secureStorage);
    final manager = DefaultTokenManager(
      tokenUri: _resolveTokenUrl(tokenUrl),
      credentialStore: credentialStore,
      httpClient: _client,
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
          client: _client,
          onUnauthorized: _onUnauthorized,
        ),
      );
    }

    return RestigoClient._internal(
      baseUrl: baseUrl,
      httpClient: _client,
      defaultHeaders: _defaultHeaders,
      timeout: _timeout,
      interceptors: _interceptors,
    );
  }
}
