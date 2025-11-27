# Restigo

**REST APIs, ready to go.**

Restigo is a lightweight, modular REST client for **Flutter & Dart**. It simplifies HTTP API interactions with built-in authentication, secure credential storage, logging, and robust error handling.

---

## Features

- ✅ Simple and intuitive API
- ✅ Supports GET, POST, PUT, DELETE requests
- ✅ Interceptor support (logging, authentication, custom)
- ✅ Optional Secure Storage for tokens (JWT, API keys, etc.)
- ✅ Handles JSON encoding/decoding automatically
- ✅ Configurable headers and timeouts
- ✅ Lightweight and fast
- ✅ Works with both Flutter and Dart projects
- ✅ Structured error handling

---

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  restigo: ^0.0.1
```

---

## Example Usage

```dart
import 'package:restigo/restigo.dart';

void main() async {
  final builder = RestigoBuilder(baseUrl: 'dummyjson.com')
    ..enableLogging();
  final client = builder.build();

  final uri = _client.resolveEndpoint('/posts');
  // GET request
  final posts = await client.get(uri);
  print(posts);

  // POST request
  final newPost = await client.post(uri, {
    "title": "Hello",
    "body": "This is a test",
    "userId": 1
  });
  print(newPost);
}

```

---

## Design & Structure

- **RestigoClient**: The core HTTP client, supporting interceptors and error handling.
- **RestigoBuilder**: Fluent builder for configuring the client (base URL, interceptors, auth, etc.).
- **Interceptors**: Easily add logging, authentication, or custom logic to requests/responses.
- **CredentialStore**: Secure and abstract implementations for storing tokens, username, and password.
- **SecureStorage**: Abstracts platform-specific secure storage (e.g., Keychain, Keystore).
- **ApiException**: Rich error class with types for connection, serialization, unauthorized, and unknown errors.

---

## Testing

- Comprehensive unit tests for all major components (client, interceptors, credential store, exceptions).
- Uses `mocktail` for mocking dependencies.
- Test suite runner included.

---

**Summary:**  
Restigo is a well-structured, extensible, and secure REST client for Dart/Flutter, suitable for modern app development. It’s easy to use, robust, and ready for production with minor documentation and polish improvements.

