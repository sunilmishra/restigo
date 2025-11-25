import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  Future<void> write(String key, dynamic value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// https://pub.dev/packages/flutter_secure_storage
/// [flutter_secure_storage] store data in Keychain/Keystore.
class SecureStorageImpl extends SecureStorage {
  SecureStorageImpl({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> write(String key, dynamic value) async {
    if (key.isEmpty) {
      assert(key.isEmpty);
      throw Exception('Key can not be empty.');
    }
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}
