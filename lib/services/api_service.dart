import 'package:dio/dio.dart';
import '../core/config.dart';
import 'supabase_service.dart';

/// Singleton Dio client for Railway backend API
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Dio? _dio;

  void initialize() {
    if (_dio != null) return;
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.railwayApiUrl.replaceAll(RegExp(r'/+$'), ''),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Auth interceptor — injects Supabase JWT on every request with proactive refresh
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final session = SupabaseService.auth.currentSession;
            if (session != null) {
              String? token = session.accessToken;
              // Proactively refresh if session is expired or within 60s of expiring
              if (session.isExpired) {
                try {
                  final refreshRes = await SupabaseService.auth.refreshSession();
                  token = refreshRes.session?.accessToken ?? token;
                } catch (_) {}
              }
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
          } catch (_) {}
          handler.next(options);
        },
        onError: (error, handler) async {
          // If 401 or token expired, attempt to refresh session before rejecting
          if (error.response?.statusCode == 401) {
            final respStr = error.response?.data?.toString().toLowerCase() ?? '';
            final msgStr = error.message?.toLowerCase() ?? '';
            final isExpiredOrInvalid = respStr.contains('expired') ||
                respStr.contains('token') ||
                msgStr.contains('expired') ||
                error.response?.statusCode == 401;

            final hasRetried = error.requestOptions.extra['retried'] == true;
            if (isExpiredOrInvalid && !hasRetried) {
              try {
                final refreshRes = await SupabaseService.client.auth.refreshSession();
                final newToken = refreshRes.session?.accessToken;
                if (newToken != null && newToken.isNotEmpty) {
                  final retryOptions = error.requestOptions;
                  retryOptions.extra['retried'] = true;
                  retryOptions.headers['Authorization'] = 'Bearer $newToken';
                  final cloneResponse = await _dio!.fetch(retryOptions);
                  return handler.resolve(cloneResponse);
                }
              } catch (_) {
                // If refresh failed, session is genuinely expired. Clear local session.
                await SupabaseService.signOut().catchError((_) {});
              }
            }
          }

          // Convert to ApiException and reject through the handler
          if (error.response != null) {
            final data = error.response?.data;
            final detail = data is Map ? data['detail'] : error.message;
            final msg = detail?.toString() ?? error.message ?? 'Unknown error';
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                message: msg,
                error: ApiException(
                  statusCode: error.response?.statusCode ?? 0,
                  message: msg,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  Dio get dio {
    if (_dio == null) initialize();
    return _dio!;
  }

  // ─── Convenience wrappers ─────────────────────────────────────────────────

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    final response = await dio.get(path, queryParameters: params);
    return response.data;
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    final response = await dio.post(path, data: data);
    return response.data;
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    final response = await dio.put(path, data: data);
    return response.data;
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    final response = await dio.patch(path, data: data);
    return response.data;
  }

  Future<dynamic> delete(String path) async {
    final response = await dio.delete(path);
    return response.data;
  }

  Future<dynamic> postMultipart(String path, FormData formData) async {
    final response = await dio.post(
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
  String toString() => message;
}

/// Helper to extract clean user-friendly message from any Exception / DioException
String extractErrorMessage(dynamic error) {
  if (error == null) return 'An unexpected error occurred.';
  if (error is DioException) {
    if (error.error is ApiException) {
      return (error.error as ApiException).message;
    }
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  if (error is ApiException) {
    return error.message;
  }
  final str = error.toString();
  if (str.startsWith('Exception: ')) {
    return str.substring('Exception: '.length);
  }
  return str;
}

/// Global singleton instance
final apiService = ApiService();
