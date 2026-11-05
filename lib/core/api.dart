import 'package:dio/dio.dart';

import 'config.dart';

class ApiError implements Exception {
  ApiError(this.message, {this.code, this.status});
  final String message;
  final String? code;
  final int? status;

  /// true when the server could not be reached at all (offline, server restarting)
  bool get isNetwork => status == null;

  @override
  String toString() => message;
}

/// Thin JSON client for the Yara backend (same API the website uses).
class Api {
  Api() {
    dio = Dio(BaseOptions(
      baseUrl: Config.baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 25),
      headers: {'x-client': 'app'},
      validateStatus: (_) => true,
    ));
  }

  late final Dio dio;
  String? token;
  String deviceId = '';

  /// Called only when the server really rejected our token (not on network errors).
  void Function()? onUnauthorized;

  static const _authCodes = ['INVALID_TOKEN', 'UNAUTHENTICATED', 'ACCOUNT_DISABLED'];

  Future<dynamic> request(String method, String path, {Map<String, dynamic>? query, Object? body, FormData? form}) async {
    try {
      final r = await dio.request<dynamic>(
        path,
        data: form ?? body,
        queryParameters: query,
        options: Options(method: method, headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'x-device-id': deviceId,
        }),
      );
      final status = r.statusCode ?? 0;
      if (status == 204) return null;
      if (status >= 200 && status < 300) return r.data;
      final err = r.data is Map ? (r.data as Map)['error'] : null;
      final e = ApiError(
        (err is Map ? err['message'] as String? : null) ?? 'حدث خطأ',
        code: err is Map ? err['code'] as String? : null,
        status: status,
      );
      if (status == 401 && token != null && _authCodes.contains(e.code)) onUnauthorized?.call();
      throw e;
    } on DioException {
      throw ApiError('لا يوجد اتصال بالخادم، تحقق من الإنترنت');
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => request('GET', path, query: query);
  Future<dynamic> post(String path, {Object? body}) => request('POST', path, body: body ?? <String, dynamic>{});
  Future<dynamic> put(String path, {Object? body}) => request('PUT', path, body: body ?? <String, dynamic>{});
  Future<dynamic> patch(String path, {Object? body}) => request('PATCH', path, body: body ?? <String, dynamic>{});
  Future<dynamic> delete(String path) => request('DELETE', path);

  /// Resolves "/uploads/x.png" to a full URL.
  String absolute(String path) => path.startsWith('http') ? path : '${Config.baseUrl}$path';
}
