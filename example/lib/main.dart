import 'package:example/post_notifier.dart';
import 'package:example/post_page.dart';
import 'package:flutter/material.dart';
import 'package:restigo/restigo.dart';

void main() {
  final credentialStore = CredentialStoreImpl(SecureStorageImpl());
  final client = Restigo(
    credentialStore: credentialStore,
    configuration: ServerConfiguration(url: 'dummyjson.com'),
    tokenUrl: Uri(),
    unAuthorizedCallback: () {},
  );

  final notifier = PostNotifier(client: client);
  runApp(MyApp(notifier: notifier));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.notifier});

  final PostNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: PostPage(notifier: notifier));
  }
}
