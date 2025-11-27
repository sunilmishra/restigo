import 'package:http/http.dart';

abstract class RestigoInterceptor {
  /// Called before the request is sent.
  Future<BaseRequest> onRequest(BaseRequest request) async => request;

  /// Called after a response is received.
  Future<StreamedResponse> onResponse(StreamedResponse response) async =>
      response;
}
