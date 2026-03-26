class GrowthRankAssets {
  static const String baseDir = 'assets/images/growth_ranks';

  static const String rank01Awakener = '$baseDir/rank_01_chu_xing_zhe.png';
  static const String rank02Walker = '$baseDir/rank_02_jie_zhi_xing_zhe.png';
  static const String rank03Guard = '$baseDir/rank_03_zhuan_zhu_shou_wei.png';
  static const String rank04Controller =
      '$baseDir/rank_04_qing_xing_zhang_kong_zhe.png';
  static const String rank05Guardian =
      '$baseDir/rank_05_zi_lv_shou_hu_zhe.png';
  static const String rank06GuardStar = '$baseDir/rank_06_guard_star.png';

  static String pathForRank(int rankIndex, {bool isMaxRank = false}) {
    if (isMaxRank) {
      return rank06GuardStar;
    }

    switch (rankIndex) {
      case 1:
        return rank01Awakener;
      case 2:
        return rank02Walker;
      case 3:
        return rank03Guard;
      case 4:
        return rank04Controller;
      case 5:
      default:
        return rank05Guardian;
    }
  }
}
