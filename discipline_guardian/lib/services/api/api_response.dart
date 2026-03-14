/// 统一 API 响应结构。
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromMap(
    Map<String, dynamic> map,
    T Function(Object?) parseData,
  ) {
    return ApiResponse<T>(
      success: (map['success'] as bool?) ?? false,
      data: map.containsKey('data') ? parseData(map['data']) : null,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap(Object? Function(T value)? encodeData) {
    return {
      'success': success,
      'data': data != null && encodeData != null ? encodeData(data as T) : data,
      'error': error,
    };
  }
}
