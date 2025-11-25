# Restigo

**REST APIs, ready to go.**

Restigo is a lightweight, easy-to-use REST client for **Flutter & Dart**.  
It helps you make **GET, POST, PUT, DELETE** requests effortlessly with built-in **JSON parsing** and **error handling**. Perfect for building modern apps that communicate with REST APIs.

---

## Features

- ✅ Simple and intuitive API
- ✅ Supports GET, POST, PUT, DELETE requests
- ✅ Optional Secure Storage for tokens (JWT, API keys, etc.)  
- ✅ Handles JSON encoding/decoding automatically
- ✅ Configurable headers
- ✅ Lightweight and fast
- ✅ Works with both Flutter and Dart projects

---

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  restigo: ^0.0.1
```
## Example
```
import 'package:restigo/restigo.dart';

void main() async {
  final credentialStore = CredentialStoreImpl(SecureStorageImpl());
  final client = Restigo(
    credentialStore: credentialStore,
    configuration: ServerConfiguration(url: 'dummyjson.com'),
    tokenUrl: Uri(), // e.g "/login"
    unAuthorizedCallback: () {
      // if Refreshed Token get failed with 401
    },
  );

  // GET request
  final posts = await client.get('/posts');
  print(posts);

  // POST request
  final newPost = await client.post('/posts', {
    "title": "Hello",
    "body": "This is a test",
    "userId": 1
  });
  print(newPost);
}

```
