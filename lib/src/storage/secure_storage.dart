import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecureStorage {
  /// Writes a value to secure storage. Throws if key is empty or null.
  Future<void> write(String key, String? value);

  /// Reads a value from secure storage. Throws if key is empty or null.
  Future<String?> read(String key);

  /// Deletes a value from secure storage. Throws if key is empty or null.
  Future<void> delete(String key);

  /// Deletes all values from secure storage.
  Future<void> deleteAll();
}

/// https://pub.dev/packages/flutter_secure_storage
/// [flutter_secure_storage] store data in Keychain/Keystore.
class SecureStorageImpl extends SecureStorage {
  SecureStorageImpl({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> write(String key, String? value) async {
    if (key.isEmpty) {
      throw Exception('Key cannot be empty.');
    }
    await _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    if (key.isEmpty) {
      throw Exception('Key cannot be empty.');
    }
    return await _secureStorage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    if (key.isEmpty) {
      throw Exception('Key cannot be empty.');
    }
    await _secureStorage.delete(key: key);
  }

  @override
  Future<void> deleteAll() async {
    await _secureStorage.deleteAll();
  }
}
