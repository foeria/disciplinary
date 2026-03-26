class GrowthRankDefinition {
  final int index;
  final String name;
  final String description;
  final int minExpInclusive;
  final int maxExpInclusive;

  const GrowthRankDefinition({
    required this.index,
    required this.name,
    required this.description,
    required this.minExpInclusive,
    required this.maxExpInclusive,
  });

  int get span => maxExpInclusive - minExpInclusive + 1;
}

class GrowthRules {
  static const int maxDailyExp = 120;
  static const int maxPerAppExp = 30;
  static const int maxTotalExp = 28800;
  static const int guardStarExp = 7200;

  static const List<GrowthRankDefinition> ranks = <GrowthRankDefinition>[
    GrowthRankDefinition(
      index: 1,
      name: '初醒者',
      description: '开始意识到自己需要管理上瘾 App。',
      minExpInclusive: 0,
      maxExpInclusive: 199,
    ),
    GrowthRankDefinition(
      index: 2,
      name: '节制行者',
      description: '已经能主动减少冲动使用。',
      minExpInclusive: 200,
      maxExpInclusive: 1499,
    ),
    GrowthRankDefinition(
      index: 3,
      name: '专注守卫',
      description: '可以稳定守住自己的限制规则。',
      minExpInclusive: 1500,
      maxExpInclusive: 4499,
    ),
    GrowthRankDefinition(
      index: 4,
      name: '清醒掌控者',
      description: '不再被使用冲动轻易带走节奏。',
      minExpInclusive: 4500,
      maxExpInclusive: 10799,
    ),
    GrowthRankDefinition(
      index: 5,
      name: '自律守护者',
      description: '已形成长期、稳定、自主的克制能力。',
      minExpInclusive: 10800,
      maxExpInclusive: 28799,
    ),
  ];

  static GrowthRankDefinition rankForExp(int totalExp) {
    for (final rank in ranks) {
      if (totalExp <= rank.maxExpInclusive) {
        return rank;
      }
    }
    return ranks.last;
  }

  static GrowthRankDefinition rankByIndex(int index) {
    return ranks.firstWhere(
      (rank) => rank.index == index,
      orElse: () => ranks.first,
    );
  }

  static int expToNextRank(int totalExp) {
    if (totalExp >= maxTotalExp) {
      return 0;
    }

    final current = rankForExp(totalExp);
    final nextIndex = current.index + 1;
    if (nextIndex > ranks.length) {
      return maxTotalExp - totalExp;
    }
    return rankByIndex(nextIndex).minExpInclusive - totalExp;
  }

  static int currentRankStartExp(int totalExp) => rankForExp(totalExp).minExpInclusive;

  static int currentRankEndExp(int totalExp) {
    if (totalExp >= maxTotalExp) {
      return maxTotalExp;
    }
    return rankForExp(totalExp).maxExpInclusive + 1;
  }

  static double progressWithinRank(int totalExp) {
    if (totalExp >= maxTotalExp) {
      return 1;
    }

    final start = currentRankStartExp(totalExp);
    final end = currentRankEndExp(totalExp);
    final span = end - start;
    if (span <= 0) {
      return 1;
    }
    final progress = totalExp - start;
    return (progress / span).clamp(0.0, 1.0);
  }
}
