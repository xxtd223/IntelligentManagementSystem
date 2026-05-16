import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class DioClient {
  static final Dio _dio = _createDio();

  static Dio get instance => _dio;

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await LocalStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final body = response.data;
        if (body is Map && body['code'] != null && body['code'] != 200) {
          final msg = body['message'] as String? ?? '操作失败';
          handler.reject(DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: msg,
          ));
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) {
        // 尝试从响应体提取业务错误信息
        final body = error.response?.data;
        if (body is Map && body['message'] != null) {
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            type: error.type,
            message: body['message'] as String,
          ));
          return;
        }
        handler.next(error);
      },
    ));

    return dio;
  }

  static Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams}) async {
    final resp = await _dio.get(path, queryParameters: queryParams);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(String path,
      {dynamic data}) async {
    final resp = await _dio.post(path, data: data);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> put(String path,
      {dynamic data}) async {
    final resp = await _dio.put(path, data: data);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(String path,
      {dynamic data}) async {
    final resp = await _dio.patch(path, data: data);
    return resp.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final resp = await _dio.delete(path);
    return resp.data as Map<String, dynamic>;
  }
}
