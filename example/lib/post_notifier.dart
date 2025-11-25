import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:restigo/restigo.dart';

import 'post.dart';

class PostNotifier extends ChangeNotifier {
  PostNotifier({required Restigo client}) : _client = client {
    fetchPosts();
  }

  final Restigo _client;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Post> _posts = [];
  List<Post> get posts => _posts;

  Future<void> fetchPosts() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.get(_client.resolveEndpoint('/posts'));
      if (response.statusCode != 200) {
        throw ApiException.statusCode(response);
      }

      final data = jsonDecode(response.body)['posts'] as List<dynamic>;
      _posts = data.map((e) => Post.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
