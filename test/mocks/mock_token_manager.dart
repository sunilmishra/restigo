import 'package:mocktail/mocktail.dart';
import 'package:restigo/src/auth/token_manager.dart';

class MockTokenManager extends Mock implements TokenManager {}

final fakeTokenUri = Uri.parse('https://api.example.com/auth/token');


