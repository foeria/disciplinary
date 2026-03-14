import 'package:flutter/material.dart';

import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';

class SystemPermissionsPage extends StatefulWidget {
  const SystemPermissionsPage({super.key});

  @override
  State<SystemPermissionsPage> createState() => _SystemPermissionsPageState();
}

class _SystemPermissionsPageState extends State<SystemPermissionsPage>
    with WidgetsBindingObserver {
  final LocalBackendService _backendService = LocalBackendService();

  bool _loading = true;
  bool _usageStatsGranted = false;
  bool _accessibilityGranted = false;
  bool _overlayGranted = false;
  bool _notificationGranted = false;
  bool _batteryOptimizationIgnored = false;
  bool _keepAliveEnabled = false;
  bool _keepAliveRunning = false;
  String _engineStatusText = '未初始化';
  String _engineDetailText = '';
  String _recentInterceptText = '-';
  String _recentLockText = '-';
  String _recentUnlockText = '-';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    final usageStats = await _backendService.isUsageStatsPermissionGranted();
    final accessibility =
        await _backendService.isAccessibilityPermissionGranted();
    final overlay = await _backendService.isOverlayPermissionGranted();
    final notification = await _backendService.areNotificationsEnabled();
    final batteryOptimization =
        await _backendService.isBatteryOptimizationIgnored();
    final keepAliveEnabled = await _backendService.isKeepAliveEnabled();
    final keepAliveRunning = await _backendService.isKeepAliveRunning();
    final status = await _backendService.getInterceptionStatus();
    final diagnostics = await _backendService.getSystemDiagnosticsData();

    if (!mounted) {
      return;
    }

    setState(() {
      _usageStatsGranted = usageStats;
      _accessibilityGranted = accessibility;
      _overlayGranted = overlay;
      _notificationGranted = notification;
      _batteryOptimizationIgnored = batteryOptimization;
      _keepAliveEnabled = keepAliveEnabled;
      _keepAliveRunning = keepAliveRunning;
      _engineStatusText = status.enabled ? '拦截引擎已启用' : '拦截引擎未启用';
      _engineDetailText =
          '规则包数: ${status.blockedPackageCount}  前台: ${status.lastForegroundPackage ?? '-'}  最近拦截: ${status.lastInterceptedPackage ?? '-'}';
      _recentInterceptText = diagnostics.recentInterceptedPackage ?? '-';
      _recentLockText = _buildRecordText(
        diagnostics.recentLockAppName,
        diagnostics.recentLockAt,
      );
      _recentUnlockText = _buildRecordText(
        diagnostics.recentUnlockAppName,
        diagnostics.recentUnlockAt,
      );
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '系统权限中枢',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 16),
                  _buildPermissionCard(
                    title: '使用统计权限',
                    subtitle: '用于读取应用真实使用时长并触发超限判定。',
                    granted: _usageStatsGranted,
                    onTap: _backendService.openUsageStatsPermissionSettings,
                  ),
                  _buildPermissionCard(
                    title: '无障碍权限',
                    subtitle: '用于下一阶段实现系统级实时拦截（后台也可生效）。',
                    granted: _accessibilityGranted,
                    onTap: _backendService.openAccessibilityPermissionSettings,
                  ),
                  _buildPermissionCard(
                    title: '悬浮窗权限',
                    subtitle: '用于在受限应用上层展示拦截遮罩和提示。',
                    granted: _overlayGranted,
                    onTap: _backendService.openOverlayPermissionSettings,
                  ),
                  _buildPermissionCard(
                    title: '通知权限',
                    subtitle: '用于提前提醒和锁定后状态通知。',
                    granted: _notificationGranted,
                    onTap: _openNotificationPermissionFlow,
                  ),
                  _buildPermissionCard(
                    title: '电池优化白名单',
                    subtitle: '尽量减少系统省电策略对后台保活和拦截链路的打断。',
                    granted: _batteryOptimizationIgnored,
                    onTap: _backendService.openBatteryOptimizationSettings,
                  ),
                  _buildKeepAliveCard(),
                  const SizedBox(height: 2),
                  _buildEngineStatusCard(),
                  const SizedBox(height: 10),
                  _buildRecentDiagnosticsCard(),
                  const SizedBox(height: 12),
                  Text(
                    '提示：授权后返回本页会自动刷新状态。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
    final allGranted =
        _usageStatsGranted &&
        _accessibilityGranted &&
        _overlayGranted &&
        _notificationGranted &&
        _batteryOptimizationIgnored &&
        _keepAliveEnabled;

    return AnimeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            allGranted ? Icons.verified_user_outlined : Icons.shield_outlined,
            color: allGranted ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              allGranted
                  ? '系统级拦截前置权限已满足。'
                  : '当前权限未全部满足，系统级拦截能力将受限。',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required bool granted,
    required Future<void> Function() onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimeCard(
        onTap: () async {
          await onTap();
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请在系统设置页完成授权后返回')),
          );
        },
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (granted
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE53935))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                granted ? Icons.check_circle_outline : Icons.error_outline,
                color:
                    granted ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Color(0xFF999999), size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotificationPermissionFlow() async {
    if (await _backendService.areNotificationsEnabled()) {
      return;
    }
    final canRequest = await _backendService.canRequestNotificationPermission();
    if (canRequest) {
      final granted = await _backendService.requestNotificationPermission();
      if (granted) {
        return;
      }
    }
    await _backendService.openNotificationPermissionSettings();
  }

  Widget _buildKeepAliveCard() {
    final statusText = _keepAliveEnabled
        ? (_keepAliveRunning ? '已启用，前台保活服务正在运行' : '已启用，等待系统重新拉起')
        : '未启用，后台被系统回收的概率会明显增加';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimeCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (_keepAliveEnabled
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF9800))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _keepAliveEnabled
                    ? Icons.motion_photos_auto_outlined
                    : Icons.pause_circle_outline,
                color: _keepAliveEnabled
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '后台保活服务',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '通过前台服务、开机恢复和任务移除后自恢复，尽量提高存活率。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _keepAliveRunning
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: _keepAliveEnabled,
              onChanged: (value) async {
                await _backendService.setKeepAliveEnabled(value);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? '后台保活已开启，建议同时加入电池优化白名单'
                          : '后台保活已关闭',
                    ),
                  ),
                );
                await _loadStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineStatusCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF607D8B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.memory_outlined,
              color: Color(0xFF607D8B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '拦截引擎状态',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _engineStatusText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _engineDetailText,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiagnosticsCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近事件诊断',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          _buildDiagRow('最近拦截包名', _recentInterceptText),
          const SizedBox(height: 4),
          _buildDiagRow('最近锁定记录', _recentLockText),
          const SizedBox(height: 4),
          _buildDiagRow('最近解锁记录', _recentUnlockText),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _buildRecordText(String? appName, DateTime? time) {
    if (appName == null || time == null) {
      return '-';
    }
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$appName ($y-$m-$d $hh:$mm)';
  }
}
