import 'package:dio/dio.dart';

import 'api_response.dart';

/// 基础 HTTP 客户端。
class BackendApiClient {
  BackendApiClient({
    required String baseUrl,
    Dio? dio,
    String? accessToken,
  })  : _accessToken = accessToken,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                contentType: 'application/json',
              ),
            );

  final Dio _dio;
  String? _accessToken;

  void setAccessToken(String? accessToken) {
    _accessToken = accessToken;
  }

  Future<ApiResponse<Map<String, dynamic>>> get(String path) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      options: _withAuthHeaders(),
    );
    return ApiResponse.fromMap(response.data ?? <String, dynamic>{}, (raw) {
      return (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: _withAuthHeaders(),
    );
    return ApiResponse.fromMap(response.data ?? <String, dynamic>{}, (raw) {
      return (raw as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    });
  }

  Options _withAuthHeaders() {
    if (_accessToken == null || _accessToken!.isEmpty) {
      return Options();
    }
    return Options(
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );
  }
}
