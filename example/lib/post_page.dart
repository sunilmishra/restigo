import 'package:example/post_notifier.dart';
import 'package:flutter/material.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key, required this.notifier});
  final PostNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: AnimatedBuilder(
        animation: notifier,
        builder: (context, child) {
          if (notifier.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (notifier.error != null) {
            return Center(child: Text('Error: ${notifier.error}'));
          } else {
            return ListView.builder(
              itemCount: notifier.posts.length,
              itemBuilder: (context, index) {
                final post = notifier.posts[index];
                return ListTile(
                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post.body),
                );
              },
            );
          }
        },
      ),
    );
  }
}
