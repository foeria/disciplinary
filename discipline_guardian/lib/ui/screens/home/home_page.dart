import 'package:flutter/material.dart';

import '../../../core/events/app_events.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/app_list_tile.dart';
import '../settings/system_permissions_page.dart';
import '../settings/theme_page.dart';
import 'plan_list_page.dart';

class HomePage extends StatefulWidget {
  final Function(int) onSwitchToTab;

  const HomePage({
    super.key,
    required this.onSwitchToTab,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalBackendService _backendService = LocalBackendService();

  HomeDashboardData? _dashboardData;
  bool _isLoading = true;
  String? _loadError;

  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _scaffoldBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get _surfaceColor => _scheme.surface;
  Color get _titleColor => _scheme.onSurface;
  Color get _bodyColor => _scheme.onSurface.withValues(alpha: 0.72);
  Color get _mutedColor => _scheme.onSurface.withValues(alpha: 0.58);
  Color get _outlineColor => _scheme.outline.withValues(alpha: 0.2);
  Color get _shadowColor => _scheme.onSurface.withValues(alpha: 0.05);
  Color get _primaryColor => _scheme.primary;

  @override
  void initState() {
    super.initState();
    AppEvents.homeRefreshTick.addListener(_onHomeRefreshRequested);
    _loadDashboard();
  }

  @override
  void dispose() {
    AppEvents.homeRefreshTick.removeListener(_onHomeRefreshRequested);
    super.dispose();
  }

  void _onHomeRefreshRequested() {
    if (!mounted) {
      return;
    }
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      await _backendService.syncTodayUsageFromDevice();
      final data = await _backendService.getHomeDashboardData();
      if (!mounted) {
        return;
      }
      setState(() {
        _dashboardData = data;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = '首页数据加载失败，请重试';
      });
    }
  }

  Future<void> _openPlanListPage() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PlanListPage()),
    );
    if (changed == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadDashboard();
      });
    }
  }

  Future<void> _handleControlledAppTap(HomeAppOverview app) async {
    final missingPermissions =
        await _backendService.getMissingSystemPermissionHubItems();
    if (!mounted) {
      return;
    }

    if (missingPermissions.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '系统权限中心仍有未开启项：${missingPermissions.join("、")}',
          ),
          action: SnackBarAction(
            label: '去开启',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SystemPermissionsPage(),
                ),
              );
            },
          ),
        ),
      );
      return;
    }

    widget.onSwitchToTab(1);
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
    return _primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _scaffoldBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: _scaffoldBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _loadError!,
                style: TextStyle(color: _bodyColor),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _loadError = null;
                  });
                  _loadDashboard();
                },
                child: Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlanEntry(),
                    const SizedBox(height: 20),
                    _buildProgressSection(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('受控应用'),
                    const SizedBox(height: 12),
                    _buildAppList(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '自律守护者',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              Text(
                '保持专注，慢慢把节奏拿回来',
                style: TextStyle(
                  fontSize: 12,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => widget.onSwitchToTab(3),
                icon: const Icon(Icons.settings_outlined),
                color: _bodyColor,
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemePage()),
                  );
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                },
                icon: const Icon(Icons.palette_outlined),
                color: _bodyColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanEntry() {
    return AnimeCard(
      onTap: _openPlanListPage,
      padding: const EdgeInsets.all(18),
      borderColor: _primaryColor,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.workspace_premium_outlined,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '自律100天',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _titleColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right,
            color: _scheme.onSurface.withValues(alpha: 0.45),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final apps = _dashboardData?.apps ?? const <HomeAppOverview>[];
    final normalCount = _dashboardData?.normalCount ?? 0;
    final warningCount = _dashboardData?.warningCount ?? 0;
    final lockedCount = _dashboardData?.lockedCount ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '今日概览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _titleColor,
                ),
              ),
              Text(
                '共 ${apps.length} 个应用',
                style: TextStyle(
                  fontSize: 13,
                  color: _mutedColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusChip('正常', normalCount, const Color(0xFF43A047)),
              const SizedBox(width: 10),
              _buildStatusChip('临近限制', warningCount, const Color(0xFFFF9800)),
              const SizedBox(width: 10),
              _buildStatusChip('已锁定', lockedCount, const Color(0xFFE53935)),
            ],
          ),
          if (apps.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...apps.map(_buildMiniAppProgress),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAppProgress(HomeAppOverview overview) {
    final app = overview.app;
    final usedMinutes = app.usedMinutesToday;
    final limitMinutes = overview.effectiveLimitMinutes;
    final progress = overview.progress.clamp(0.0, 1.0);
    final isLocked = overview.status == AppHealthStatus.locked;
    final isWarning = overview.status == AppHealthStatus.warning;
    final barColor = isLocked
        ? const Color(0xFFE53935)
        : isWarning
            ? const Color(0xFFFF9800)
            : const Color(0xFF43A047);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _resolveColor(app.packageName).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _resolveIcon(app.packageName),
                  color: _resolveColor(app.packageName),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  app.appName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _titleColor,
                  ),
                ),
              ),
              Text(
                '${_formatMinutes(usedMinutes)} / ${_formatMinutes(limitMinutes)}',
                style: TextStyle(
                  fontSize: 12,
                  color: _bodyColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLocked ? '已锁定' : isWarning ? '临近限制' : '正常',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: _outlineColor,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _titleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAppList() {
    final apps = _dashboardData?.apps ?? const <HomeAppOverview>[];
    if (apps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _outlineColor),
        ),
        child: Text(
          '还没有添加受控应用，前往“应用”页添加后会显示在这里。',
          style: TextStyle(
            color: _bodyColor,
            fontSize: 14,
          ),
        ),
      );
    }

    final planApps = apps
        .where((app) => app.isHundredDayPlan)
        .toList(growable: false);
    final regularApps = apps
        .where((app) => !app.isHundredDayPlan)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (planApps.isNotEmpty) ...[
          _buildAppGroupHeader(
            title: '计划中的应用',
            subtitle: '这些应用属于某个计划，计划时间与解锁规则独立计算',
            accentColor: _primaryColor,
          ),
          const SizedBox(height: 12),
          ...planApps.map(_buildControlledAppTile),
        ],
        if (planApps.isNotEmpty && regularApps.isNotEmpty) ...[
          const SizedBox(height: 20),
        ],
        if (regularApps.isNotEmpty) ...[
          _buildAppGroupHeader(
            title: '普通受控应用',
            subtitle: '这些应用继续按主控制规则计算使用时长与解锁要求',
            accentColor: _primaryColor,
          ),
          const SizedBox(height: 12),
          ...regularApps.map(_buildControlledAppTile),
        ],
      ],
    );
  }

  Widget _buildAppGroupHeader({
    required String title,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: accentColor,
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
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: _bodyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlledAppTile(HomeAppOverview overview) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppListTile(
        appName: overview.app.appName,
        packageName: overview.app.packageName,
        icon: _resolveIcon(overview.app.packageName),
        iconColor: _resolveColor(overview.app.packageName),
        usedMinutes: overview.app.usedMinutesToday,
        limitMinutes: overview.effectiveLimitMinutes,
        isLocked: overview.status == AppHealthStatus.locked,
        onTap: () => _handleControlledAppTap(overview),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.bar_chart_outlined,
            label: '统计',
            color: _primaryColor,
            onTap: () => widget.onSwitchToTab(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.lock_outline,
            label: '紧急锁定',
            color: const Color(0xFFE53935),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('紧急锁定'),
                  content: Text('确认要立即锁定所有受控应用吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('取消'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(dialogContext);
                        await _backendService.lockAllApps();
                        if (!mounted) {
                          return;
                        }
                        navigator.pop();
                        await _loadDashboard();
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已锁定所有受控应用'),
                            backgroundColor: Color(0xFFE53935),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                      ),
                      child: Text('锁定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


