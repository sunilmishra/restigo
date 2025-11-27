import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:restigo/src/storage/credential_store.dart';
import 'package:restigo/src/storage/secure_storage.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late CredentialStoreImpl store;

  setUp(() {
    mockStorage = MockSecureStorage();
    store = CredentialStoreImpl(mockStorage);
  });

  test('sets and gets accessToken', () async {
    when(
      () => mockStorage.write('key-access-token', 'abc'),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.read('key-access-token'),
    ).thenAnswer((_) async => 'abc');
    store.accessToken = 'abc';
    expect(await store.accessToken, 'abc');
  });

  test('sets and gets refreshToken', () async {
    when(
      () => mockStorage.write('key-refresh-token', 'xyz'),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.read('key-refresh-token'),
    ).thenAnswer((_) async => 'xyz');
    store.refreshToken = 'xyz';
    expect(await store.refreshToken, 'xyz');
  });

  test('sets and gets username', () async {
    when(
      () => mockStorage.write('key-user-name', 'user'),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.read('key-user-name'),
    ).thenAnswer((_) async => 'user');
    store.username = 'user';
    expect(await store.username, 'user');
  });

  test('sets and gets password', () async {
    when(
      () => mockStorage.write('key-password', 'pass'),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.read('key-password'),
    ).thenAnswer((_) async => 'pass');
    store.password = 'pass';
    expect(await store.password, 'pass');
  });

  test('hasValidTokens returns true if both tokens exist', () async {
    when(
      () => mockStorage.write('key-access-token', 'abc'),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.write('key-refresh-token', 'xyz'),
    ).thenAnswer((_) async {});
    store.accessToken = 'abc';
    store.refreshToken = 'xyz';
    expect(await store.hasValidTokens(), isTrue);
  });

  test('clear removes all credentials', () async {
    when(
      () => mockStorage.write('key-access-token', any()),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.write('key-refresh-token', any()),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.write('key-user-name', any()),
    ).thenAnswer((_) async {});
    when(
      () => mockStorage.write('key-password', any()),
    ).thenAnswer((_) async {});
    when(() => mockStorage.deleteAll()).thenAnswer((_) async {});
    when(
      () => mockStorage.read('key-access-token'),
    ).thenAnswer((_) async => null);
    when(
      () => mockStorage.read('key-refresh-token'),
    ).thenAnswer((_) async => null);
    when(() => mockStorage.read('key-user-name')).thenAnswer((_) async => null);
    when(() => mockStorage.read('key-password')).thenAnswer((_) async => null);
    store.accessToken = 'abc';
    store.refreshToken = 'xyz';
    store.username = 'user';
    store.password = 'pass';
    await store.clear();
    expect(await store.accessToken, isNull);
    expect(await store.refreshToken, isNull);
    expect(await store.username, isNull);
    expect(await store.password, isNull);
    verify(() => mockStorage.deleteAll()).called(1);
  });
}
