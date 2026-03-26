class PlanModel {
  final String id;
  final String name;
  final int durationDays;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PlanModel({
    required this.id,
    required this.name,
    this.durationDays = 100,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlanModel.fromMap(Map<String, dynamic> map) {
    return PlanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      durationDays: (map['duration_days'] as int?) ?? 100,
      startDate: DateTime.parse(map['start_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'duration_days': durationDays,
      'start_date': startDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlanModel copyWith({
    String? id,
    String? name,
    int? durationDays,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
