import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/token_storage.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
      ),
    );

    // 🔥 Interceptor to attach token automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  Future<Response> login(String email, String password) async {
    final formData = FormData.fromMap({
      "username": email,
      "password": password,
    });

    return await _dio.post(
      "/login",
      data: formData,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
  }

  Future<Response> getMe() async {
    return await _dio.get("/me");
  }
}