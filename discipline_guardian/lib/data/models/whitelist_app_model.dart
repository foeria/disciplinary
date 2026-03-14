/// 白名单应用模型。
class WhitelistAppModel {
  final String id;
  final String appName;
  final String packageName;
  final DateTime createdAt;

  const WhitelistAppModel({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.createdAt,
  });

  factory WhitelistAppModel.fromMap(Map<String, dynamic> map) {
    return WhitelistAppModel(
      id: map['id'] as String,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_name': appName,
      'package_name': packageName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
