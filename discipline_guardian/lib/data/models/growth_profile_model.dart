class GrowthProfileModel {
  final String id;
  final int totalExp;
  final int currentRankIndex;
  final String currentRankName;
  final int guardPoints;
  final int guardStars;
  final int currentStreakDays;
  final int bestStreakDays;
  final String? lastSettlementDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GrowthProfileModel({
    required this.id,
    required this.totalExp,
    required this.currentRankIndex,
    required this.currentRankName,
    required this.guardPoints,
    required this.guardStars,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.lastSettlementDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GrowthProfileModel.fromMap(Map<String, dynamic> map) {
    return GrowthProfileModel(
      id: map['id'] as String,
      totalExp: (map['total_exp'] as int?) ?? 0,
      currentRankIndex: (map['current_rank_index'] as int?) ?? 1,
      currentRankName: (map['current_rank_name'] as String?) ?? '初醒者',
      guardPoints: (map['guard_points'] as int?) ?? 0,
      guardStars: (map['guard_stars'] as int?) ?? 0,
      currentStreakDays: (map['current_streak_days'] as int?) ?? 0,
      bestStreakDays: (map['best_streak_days'] as int?) ?? 0,
      lastSettlementDate: map['last_settlement_date'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_exp': totalExp,
      'current_rank_index': currentRankIndex,
      'current_rank_name': currentRankName,
      'guard_points': guardPoints,
      'guard_stars': guardStars,
      'current_streak_days': currentStreakDays,
      'best_streak_days': bestStreakDays,
      'last_settlement_date': lastSettlementDate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GrowthProfileModel copyWith({
    String? id,
    int? totalExp,
    int? currentRankIndex,
    String? currentRankName,
    int? guardPoints,
    int? guardStars,
    int? currentStreakDays,
    int? bestStreakDays,
    String? lastSettlementDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GrowthProfileModel(
      id: id ?? this.id,
      totalExp: totalExp ?? this.totalExp,
      currentRankIndex: currentRankIndex ?? this.currentRankIndex,
      currentRankName: currentRankName ?? this.currentRankName,
      guardPoints: guardPoints ?? this.guardPoints,
      guardStars: guardStars ?? this.guardStars,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      lastSettlementDate: lastSettlementDate ?? this.lastSettlementDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
