import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:restigo/src/storage/secure_storage.dart';
import 'package:test/test.dart';

void main() {
  group(SecureStorage, () {
    late SecureStorage secureStorage;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      secureStorage = SecureStorageImpl(
        secureStorage: const FlutterSecureStorage(),
      );
    });

    test('allows reading and writing data', () async {
      const key = 'test_key';
      const value = 'A Test Value';
      await secureStorage.write(key, value);
      String? readValue = await secureStorage.read(key);
      expect(readValue, value);
    });

    test('allows deleting data', () async {
      const key = 'key_to_delete';
      const value = 'A Value to delete';
      await secureStorage.write(key, value);
      String? readValue = await secureStorage.read(key);
      expect(readValue, value);
      await secureStorage.delete(key);
      readValue = await secureStorage.read(key);
      expect(readValue, null);
    });

    test('does not allow empty keys and values', () async {
      const key = '';
      const value = 'A Test Value';
      try {
        await secureStorage.write(key, value);
      } catch (e) {
        expect(e, isA<Exception>());
      }
      try {
        await secureStorage.write('key', '');
      } catch (e) {
        expect(e, isA<Exception>());
      }
      try {
        await secureStorage.read(key);
      } catch (e) {
        expect(e, isA<Exception>());
      }
      try {
        await secureStorage.delete(key);
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
