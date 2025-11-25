import 'secure_storage.dart';

/// Provide in-memory Credentials.
abstract class CredentialStore {
  /*
  * AccessToken and RefreshToken Store
  */
  String? _accessToken;
  Future<String?> get accessToken => Future.value(_accessToken);
  set accessToken(dynamic token) => _accessToken = token;

  String? _refreshToken;
  Future<String?> get refreshToken => Future.value(_refreshToken);
  set refreshToken(dynamic token) => _refreshToken = token;

  Future<bool> hasValidTokens() async {
    return await accessToken != null && await refreshToken != null;
  }

  /*
  * Username and password Store
  */
  String? _username;
  Future<String?> get username => Future.value(_username);
  set username(dynamic uname) => _username = uname;

  String? _password;
  Future<String?> get password => Future.value(_password);
  set password(dynamic pwd) => _password = pwd;
}

///
/// Persist Credentials in SecureStorage.
/// [SecureStorage] store data in Keychain/Keystore.
///
class CredentialStoreImpl extends CredentialStore {
  CredentialStoreImpl(SecureStorage secureStorage)
    : _secureStorage = secureStorage;

  late final SecureStorage _secureStorage;

  ///======================== [AccessToken & RefreshToken] ===========================///
  @override
  set accessToken(dynamic token) {
    super.accessToken = token;
    _secureStorage.write('key-access-token', token);
  }

  @override
  Future<String?> get accessToken async {
    final token = await super.accessToken;
    if (token == null || token.isEmpty) {
      final String? newToken = await _secureStorage.read('key-access-token');
      super.accessToken = newToken;
    }
    return super.accessToken;
  }

  @override
  set refreshToken(dynamic token) {
    super.refreshToken = token;
    _secureStorage.write('key-refresh-token', token);
  }

  @override
  Future<String?> get refreshToken async {
    final token = await super.refreshToken;
    if (token == null || token.isEmpty) {
      final String? newToken = await _secureStorage.read('key-refresh-token');
      super.refreshToken = newToken;
    }
    return super.refreshToken;
  }

  ///===================== [Username & Password] ================================///
  @override
  set username(dynamic uname) {
    super.username = uname;
    _secureStorage.write('key-user-name', uname);
  }

  @override
  Future<String?> get username async {
    final uname = await super.username;
    if (uname == null || uname.isEmpty) {
      final savedUsername = await _secureStorage.read('key-user-name');
      super.username = savedUsername;
    }
    return super.username;
  }

  @override
  set password(dynamic pwd) {
    super.password = pwd;
    _secureStorage.write('key-password', pwd);
  }

  @override
  Future<String?> get password async {
    final pwd = await super.password;
    if (pwd == null || pwd.isEmpty) {
      final savedPassword = await _secureStorage.read('key-password');
      super.password = savedPassword;
    }
    return super.password;
  }
}
