enum ServerEnvironment { dev, staging, prod }

class ServerConfiguration {
  const ServerConfiguration({
    required this.url,
    this.scheme = 'https',
    this.clientId = '',
    this.apiPrefix,
    this.environment = ServerEnvironment.dev,
  });

  /// Domain only (without https://)
  final String url;

  /// Default scheme
  final String scheme;

  /// Client identifier for authentication
  final String clientId;

  /// Optional prefix like `/api/v1`
  final String? apiPrefix;

  /// Environment type
  final ServerEnvironment environment;

  /// Base Uri for constructing endpoints
  Uri get baseUri => Uri(scheme: scheme, host: url, path: apiPrefix);

  bool get isProduction => environment == ServerEnvironment.prod;
  bool get isStaging => environment == ServerEnvironment.staging;
  bool get isDevelopment => environment == ServerEnvironment.dev;

  ServerConfiguration copyWith({
    String? url,
    String? scheme,
    String? clientId,
    String? apiPrefix,
    ServerEnvironment? environment,
  }) {
    return ServerConfiguration(
      url: url ?? this.url,
      scheme: scheme ?? this.scheme,
      clientId: clientId ?? this.clientId,
      apiPrefix: apiPrefix ?? this.apiPrefix,
      environment: environment ?? this.environment,
    );
  }

  @override
  String toString() {
    return 'ServerConfiguration(url: $url, scheme: $scheme, clientId: $clientId, apiPrefix: $apiPrefix, environment: $environment)';
  }
}
