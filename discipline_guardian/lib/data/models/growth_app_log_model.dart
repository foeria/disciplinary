class GrowthAppLogModel {
  final String id;
  final String date;
  final String? appId;
  final String appName;
  final String packageName;
  final String? planId;
  final bool isHundredDayPlan;
  final int limitMinutes;
  final int usedMinutes;
  final int expGained;
  final String status;
  final String reason;
  final DateTime createdAt;

  const GrowthAppLogModel({
    required this.id,
    required this.date,
    required this.appId,
    required this.appName,
    required this.packageName,
    required this.planId,
    required this.isHundredDayPlan,
    required this.limitMinutes,
    required this.usedMinutes,
    required this.expGained,
    required this.status,
    required this.reason,
    required this.createdAt,
  });

  factory GrowthAppLogModel.fromMap(Map<String, dynamic> map) {
    return GrowthAppLogModel(
      id: map['id'] as String,
      date: map['date'] as String,
      appId: map['app_id'] as String?,
      appName: map['app_name'] as String,
      packageName: map['package_name'] as String,
      planId: map['plan_id'] as String?,
      isHundredDayPlan: ((map['is_hundred_day_plan'] as int?) ?? 0) == 1,
      limitMinutes: (map['limit_minutes'] as int?) ?? 0,
      usedMinutes: (map['used_minutes'] as int?) ?? 0,
      expGained: (map['exp_gained'] as int?) ?? 0,
      status: map['status'] as String,
      reason: map['reason'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'app_id': appId,
      'app_name': appName,
      'package_name': packageName,
      'plan_id': planId,
      'is_hundred_day_plan': isHundredDayPlan ? 1 : 0,
      'limit_minutes': limitMinutes,
      'used_minutes': usedMinutes,
      'exp_gained': expGained,
      'status': status,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GrowthAppLogModel copyWith({
    int? expGained,
    String? status,
    String? reason,
  }) {
    return GrowthAppLogModel(
      id: id,
      date: date,
      appId: appId,
      appName: appName,
      packageName: packageName,
      planId: planId,
      isHundredDayPlan: isHundredDayPlan,
      limitMinutes: limitMinutes,
      usedMinutes: usedMinutes,
      expGained: expGained ?? this.expGained,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      createdAt: createdAt,
    );
  }
}
