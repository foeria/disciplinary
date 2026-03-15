import 'package:flutter/material.dart';
import '../../../core/events/app_events.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_button.dart';

/// 统计页面
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LocalBackendService _backendService = LocalBackendService();
  String _selectedPeriod = 'week';
  bool _isLoading = true;
  StatsPageData? _statsData;

  final List<String> _periods = ['week', 'month'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    AppEvents.statsRefreshTick.addListener(_onStatsRefreshRequested);
    _loadStats();
  }

  void _onStatsRefreshRequested() {
    if (!mounted) {
      return;
    }
    _loadStats();
  }

  @override
  void dispose() {
    AppEvents.statsRefreshTick.removeListener(_onStatsRefreshRequested);
    _tabController.dispose();
    super.dispose();
  }

  int get _maxUsage {
    final data = _buildUsageSeries();
    return data.isEmpty ? 1 : data.reduce((a, b) => a > b ? a : b);
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });
    final statsData = await _backendService.getStatsData(period: _selectedPeriod);
    if (!mounted) {
      return;
    }
    setState(() {
      _statsData = statsData;
      _isLoading = false;
    });
  }

  List<int> _buildUsageSeries() {
    final data = _statsData;
    final days = _selectedPeriod == 'month' ? 30 : 7;
    if (data == null) {
      return List<int>.filled(days, 0, growable: false);
    }

    final now = DateTime.now();
    final start = now.subtract(Duration(days: days - 1));
    return List<int>.generate(days, (index) {
      final date = start.add(Duration(days: index));
      return data.usageByDate[_formatDate(date)] ?? 0;
    }, growable: false);
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double _getBarHeight(int value) {
    return (_maxUsage > 0) ? (value / _maxUsage) * 100 : 0;
  }

  String _getDayLabel(int index) {
    if (_selectedPeriod == 'week') {
      final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return days[index % 7];
    } else {
      // 月视图只显示 1、5、10、15、20、25、30 日的标签，避免文字过密溢出
      final day = index + 1;
      return (day == 1 || day % 5 == 0) ? '$day日' : '';
    }
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部
            _buildHeader(),
            // 时间选择
            _buildPeriodSelector(),
            // Tab 栏
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: const Color(0xFF666666),
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(text: '使用趋势'),
                Tab(text: '应用排行'),
              ],
            ),
            // 内容
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTrendChart(),
                        _buildRankingList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Row(
        children: [
          Text(
            '统计',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _periods.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _loadStats();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  period == 'week' ? '本周' : '本月',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart() {
    final data = _buildUsageSeries();
    final totalMinutes = _statsData?.totalUsedMinutes ?? 0;
    final avgMinutes = data.isEmpty ? 0 : totalMinutes ~/ data.length;
    final totalLockCount = _statsData?.totalLockCount ?? 0;
    final totalUnlockCount = _statsData?.totalUnlockCount ?? 0;
    final avgUnlockMinutes = _statsData?.averageUnlockMinutes ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 统计摘要
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '总使用',
                  _formatMinutes(totalMinutes),
                  const Color(0xFFFF6B9D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '日均',
                  _formatMinutes(avgMinutes),
                  const Color(0xFF7EB8DA),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '最长',
                  _formatMinutes(_statsData?.maxUsedMinutes ?? 0),
                  const Color(0xFF9B8FD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '锁定次数',
                  '$totalLockCount',
                  const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '解锁次数',
                  '$totalUnlockCount',
                  const Color(0xFF43A047),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '解锁均时',
                  _formatMinutes(avgUnlockMinutes),
                  const Color(0xFFFB8C00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 图表
          AnimeCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '使用时长趋势',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(data.length, (index) {
                      final isToday = index == data.length - 1;
                      // 周视图每格显示数值标签；月视图柱子极窄，隐藏数值标签
                      final showValueLabel = _selectedPeriod == 'week';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (showValueLabel)
                                Text(
                                  _formatMinutes(data[index]),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isToday
                                        ? AppTheme.primaryColor
                                        : const Color(0xFF999999),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: _getBarHeight(data[index]),
                                decoration: BoxDecoration(
                                  gradient: isToday
                                      ? LinearGradient(
                                          colors: AppTheme.gradientColors,
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        )
                                      : null,
                                  color: isToday
                                      ? null
                                      : const Color(0xFFEEEEEE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getDayLabel(index),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isToday
                                      ? AppTheme.primaryColor
                                      : const Color(0xFF999999),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 导出按钮
          SizedBox(
            width: double.infinity,
            child: AnimeOutlinedButton(
              text: '导出数据',
              icon: Icons.download_outlined,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('导出功能将在正式版本中开放')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      borderColor: color,
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList() {
    final ranking = _statsData?.ranking ?? const <AppRankingItem>[];
    if (ranking.isEmpty) {
      return Center(
        child: Text(
          '暂无统计数据',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final app = ranking[index];
        final icon = _resolveIcon(app.packageName);
        final color = _resolveColor(app.packageName);
        // 计算比例 (0.0–1.0)；注意 Dart 中 as 优先级低于 /，需要明确括号
        final double percentage = app.totalUsedMinutes /
            (ranking.first.totalUsedMinutes == 0 ? 1 : ranking.first.totalUsedMinutes);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimeCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: index < 3
                        ? const Color(0xFFFF6B9D).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: index < 3
                            ? const Color(0xFFFF6B9D)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatMinutes(app.totalUsedMinutes),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _resolveIcon(String packageName) {
    if (packageName.contains('tencent') || packageName.contains('game')) {
      return Icons.games_outlined;
    }
    if (packageName.contains('ugc') || packageName.contains('video')) {
      return Icons.smart_display_outlined;
    }
    if (packageName.contains('chat') || packageName.contains('qq')) {
      return Icons.chat_bubble_outline;
    }
    return Icons.apps_outlined;
  }

  Color _resolveColor(String packageName) {
    if (packageName.contains('tencent')) {
      return const Color(0xFFE53935);
    }
    if (packageName.contains('ugc') || packageName.contains('video')) {
      return const Color(0xFF1E88E5);
    }
    if (packageName.contains('chat') || packageName.contains('qq')) {
      return const Color(0xFF43A047);
    }
    return const Color(0xFFFF6B9D);
  }
}
