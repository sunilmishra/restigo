import 'dart:developer';
import 'package:http/http.dart';
import 'restigo_interceptor.dart';

class LoggingInterceptor implements RestigoInterceptor {
  const LoggingInterceptor({this.logHeaders = false, this.logBody = false});

  final bool logHeaders;
  final bool logBody;

  @override
  Future<BaseRequest> onRequest(BaseRequest request) async {
    log('➡️ Request: [${request.method}] ${request.url}');
    if (logHeaders) {
      log('Headers: ${request.headers}');
    }
    if (logBody && request is Request) {
      log('Body: ${request.body}');
    } else if (logBody) {
      log('Body: <not available>');
    }
    return request;
  }

  @override
  Future<StreamedResponse> onResponse(StreamedResponse response) async {
    log('⬅️ Response: ${response.statusCode} for ${response.request?.url}');
    if (logHeaders) {
      log('Response Headers: ${response.headers}');
    }
    if (logBody) {
      try {
        final bytes = await response.stream.toBytes();
        final body = String.fromCharCodes(bytes);
        log('Response Body: $body');
        // Re-create the StreamedResponse so the body can be read again downstream
        return StreamedResponse(
          Stream.fromIterable([bytes]),
          response.statusCode,
          contentLength: response.contentLength,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase,
        );
      } catch (e) {
        log('Response Body: <not available> ($e)');
        return response;
      }
    }
    return response;
  }
}
