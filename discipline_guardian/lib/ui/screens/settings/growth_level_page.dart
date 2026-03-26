import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/growth/growth_rank_assets.dart';
import '../../../core/growth/growth_rules.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';

class GrowthLevelPage extends StatefulWidget {
  const GrowthLevelPage({super.key});

  @override
  State<GrowthLevelPage> createState() => _GrowthLevelPageState();
}

class _GrowthLevelPageState extends State<GrowthLevelPage> {
  final LocalBackendService _backendService = LocalBackendService();

  GrowthDetailData? _detailData;
  bool _isLoading = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _backendService.getGrowthDetailData();
      if (!mounted) {
        return;
      }
      setState(() {
        _detailData = data;
        _isLoading = false;
        _errorText = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorText = '成长数据加载失败，请稍后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '成长等级',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorText != null
                ? Center(
                    child: Text(
                      _errorText!,
                      style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.72)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(_detailData!.card),
                          const SizedBox(height: 28),
                          _buildTodayRecordPanel(_detailData!),
                          const SizedBox(height: 24),
                          _buildSectionTitle('阶位规则'),
                          const SizedBox(height: 12),
                          ...GrowthRules.ranks.map(
                            (rank) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRankTile(
                                rank,
                                _detailData!.card.rankIndex == rank.index,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle('经验来源'),
                          const SizedBox(height: 12),
                          _buildRuleSummaryCard(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeroCard(GrowthCardData card) {
    final textColor = Colors.white;
    final progressLabel = card.isMaxRank
        ? '满阶后继续累积守护点'
        : '距离下一阶还差 ${card.expToNextRank} EXP';
    final progressValue = card.isMaxRank ? 1.0 : card.progress;
    final currentSpan = card.currentRankEndExp - card.currentRankStartExp;
    final currentProgress = (card.totalExp - card.currentRankStartExp).clamp(
      0,
      currentSpan,
    );
    final settlementLabel = card.lastSettlementDate == null
        ? '尚未生成首个结算日'
        : '最近结算日 ${card.lastSettlementDate}';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppTheme.gradientColors.first,
            AppTheme.gradientColors.last,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Text(
                        '第 ${card.rankIndex} 阶',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white.withValues(alpha: 0.14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _buildRankAsset(
                          path: GrowthRankAssets.pathForRank(
                            card.rankIndex,
                            isMaxRank: card.isMaxRank,
                          ),
                          fallbackIcon: card.isMaxRank
                              ? Icons.auto_awesome
                              : _fallbackIconForRank(card.rankIndex),
                          tintColor: Colors.white,
                          borderRadius: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  card.rankName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.rankDescription,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildHeroStat('总经验', '${card.totalExp}'),
                    const SizedBox(width: 12),
                    _buildHeroStat('今日入账', '+${card.todayGainedExp}'),
                    const SizedBox(width: 12),
                    _buildHeroStat('连胜', '${card.currentStreakDays} 天'),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  progressLabel,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 12,
                    color: Colors.white.withValues(alpha: 0.18),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween<double>(begin: 0, end: progressValue),
                      builder: (context, value, child) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card.isMaxRank
                      ? '守护点 ${card.guardPoints} · 守护星 ${card.guardStars}'
                      : '$currentProgress / $currentSpan',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.84),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '今日预计可得 ${card.todayEstimatedExp} EXP',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        settlementLabel,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.76),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayRecordSection(GrowthDetailData detailData) {
    if (detailData.todayRecords.isEmpty) {
      return AnimeCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '今天还没有新的经验入账',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '每日首次进入 App 时会先结算昨天的表现。保持今天的使用节奏，明天这里就会出现新的记录。',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: detailData.todayRecords.map((record) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimeCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: record.isPlanRelated
                        ? const Color(0xFFFFB300).withValues(alpha: 0.14)
                        : AppTheme.primaryColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    record.isSystemReward
                        ? Icons.local_fire_department_outlined
                        : record.isPlanRelated
                            ? Icons.workspace_premium_outlined
                            : Icons.shield_outlined,
                    color: record.isPlanRelated
                        ? const Color(0xFFFFA000)
                        : AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('HH:mm').format(record.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${record.exp}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: record.isPlanRelated
                        ? const Color(0xFFFF9800)
                        : AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Widget _buildTodayRecordPanel(GrowthDetailData detailData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF09101D).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('今日经验'),
                    const SizedBox(height: 6),
                    Text(
                      '这里展示今天首次进入后入账的经验记录，与上方主成长卡分开呈现，方便快速查看。',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${detailData.card.todayGainedExp}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '今日入账',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTodayRecordSection(detailData),
        ],
      ),
    );
  }

  Widget _buildRankTile(GrowthRankDefinition rank, bool isCurrent) {
    final accentColor =
        isCurrent ? AppTheme.primaryColor : const Color(0xFFB0BEC5);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildRankAsset(
                  path: GrowthRankAssets.pathForRank(rank.index),
                  fallbackIcon: _fallbackIconForRank(rank.index),
                  tintColor: accentColor,
                  borderRadius: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rank.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '当前',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${rank.minExpInclusive} - ${rank.maxExpInclusive} EXP',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rank.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankAsset({
    required String path,
    required IconData fallbackIcon,
    required Color tintColor,
    required double borderRadius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.white.withValues(alpha: 0.12),
            child: Icon(
              fallbackIcon,
              color: tintColor,
              size: 28,
            ),
          );
        },
      ),
    );
  }

  IconData _fallbackIconForRank(int rankIndex) {
    switch (rankIndex) {
      case 1:
        return Icons.visibility_outlined;
      case 2:
        return Icons.directions_walk_outlined;
      case 3:
        return Icons.shield_outlined;
      case 4:
        return Icons.psychology_outlined;
      case 5:
      default:
        return Icons.workspace_premium_outlined;
    }
  }

  Widget _buildRuleSummaryCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _RuleLine(
            title: '普通受控应用',
            description: '完美 18 / 优秀 12 / 达标 6 / 失败 0，再加每日坚持奖励 2 EXP',
          ),
          SizedBox(height: 12),
          _RuleLine(
            title: '100 天计划',
            description: '极佳 25 / 达标 16 / 勉强通过 10 / 失败 0，再加每日坚持奖励 4 EXP',
          ),
          SizedBox(height: 12),
          _RuleLine(
            title: '加入与连胜奖励',
            description: '普通受控满一自然日 +20，计划满一自然日 +30；连胜 3/7/14/30 天额外 +5/+10/+15/+20',
          ),
          SizedBox(height: 12),
          _RuleLine(
            title: '经验上限',
            description: '单个 App 每日最多贡献 30 EXP，单日总经验上限 120 EXP',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFF333333),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String title;
  final String description;

  const _RuleLine({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
