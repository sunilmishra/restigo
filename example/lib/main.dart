import 'package:example/post_notifier.dart';
import 'package:example/post_page.dart';
import 'package:flutter/material.dart';
import 'package:restigo/restigo.dart';

void main() {
  final builder = RestigoBuilder(baseUrl: 'dummyjson.com')
    ..enableLogging()
    ..enableAuth(
      tokenUrl: '/auth/token',
      onUnauthorized: () async {
        // Handle unauthorized access, e.g., navigate to login screen
      },
    );

  final client = builder.build();

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
