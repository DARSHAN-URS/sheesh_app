import 'package:dio/dio.dart';
import '../core/config.dart';
import 'supabase_service.dart';

/// Singleton Dio client for Railway backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.railwayApiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor — injects Supabase JWT on every request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SupabaseService.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Log errors in dev
          if (error.response != null) {
            final data = error.response?.data;
            final detail = data is Map ? data['detail'] : error.message;
            throw ApiException(
              statusCode: error.response?.statusCode ?? 0,
              message: detail?.toString() ?? 'Unknown error',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ─── Convenience wrappers ─────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final response = await _dio.get(path, queryParameters: params);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await _dio.delete(path);
    return response.data;
  }

  Future<dynamic> postMultipart(String path, FormData formData) async {
    final response = await _dio.post(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data;
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Global singleton instance
final apiService = ApiService();
