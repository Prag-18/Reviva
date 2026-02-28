import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../events/session_events.dart';
import '../utils/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  final http.Client _client = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = Uri.parse(AppConfig.baseUrl);
    return base.replace(
      path: '${base.path}$path',
      queryParameters:
          queryParameters?.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _headers({
    bool authorized = true,
    String? contentType,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    if (authorized) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<http.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authorized = true,
  }) {
    return _retryable(() async {
      final response = await _client
          .get(
            _uri(path, queryParameters),
            headers: await _headers(authorized: authorized),
          )
          .timeout(const Duration(seconds: 20));
      return _handle(response);
    });
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    bool authorized = true,
    bool formUrlEncoded = false,
  }) {
    return _retryable(() async {
      final response = await _client
          .post(
            _uri(path, queryParameters),
            headers: await _headers(
              authorized: authorized,
              contentType: formUrlEncoded
                  ? 'application/x-www-form-urlencoded'
                  : 'application/json',
            ),
            body: formUrlEncoded && body is Map<String, String>
                ? body
                : body == null
                    ? null
                    : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handle(response);
    });
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    bool authorized = true,
  }) {
    return _retryable(() async {
      final response = await _client
          .put(
            _uri(path, queryParameters),
            headers: await _headers(
              authorized: authorized,
              contentType: 'application/json',
            ),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      return _handle(response);
    });
  }

  dynamic decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    return jsonDecode(response.body);
  }

  Future<T> _retryable<T>(Future<T> Function() task) async {
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await task();
      } on SocketException {
        if (attempt == maxAttempts) {
          throw const ApiException('No internet connection');
        }
      } on TimeoutException {
        if (attempt == maxAttempts) {
          throw const ApiException('Request timed out');
        }
      }
      await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
    }
    throw const ApiException('Unexpected network error');
  }

  http.Response _handle(http.Response response) {
    if (response.statusCode == 401) {
      TokenStorage.clearToken();
      SessionEvents.emitUnauthorized();
      throw const ApiException('Session expired', statusCode: 401);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = 'Request failed';
      try {
        final decoded = decodeBody(response);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    }

    return response;
  }
}
