import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

class _PermissionCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool granted;
  final bool required;
  final String actionLabel;
  final Future<void> Function() onTap;

  const _PermissionCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.granted,
    required this.required,
    required this.actionLabel,
    required this.onTap,
  });
}

/// 权限申请页面
class PermissionPage extends StatefulWidget {
  final VoidCallback onGranted;
  final VoidCallback onSkip;

  const PermissionPage({
    super.key,
    required this.onGranted,
    required this.onSkip,
  });

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage>
    with WidgetsBindingObserver {
  final LocalBackendService _backendService = LocalBackendService();
  bool _isLoading = true;
  bool _usagePermissionGranted = false;
  bool _accessibilityGranted = false;
  bool _overlayGranted = false;
  bool _notificationGranted = false;
  bool _batteryOptimizationIgnored = false;
  bool _keepAliveEnabled = false;

  bool get _requiredPermissionsReady {
    return _usagePermissionGranted && _accessibilityGranted && _overlayGranted;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPermissionStates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadPermissionStates();
    }
  }

  Future<void> _loadPermissionStates() async {
    final usage = await _backendService.isUsageStatsPermissionGranted();
    final accessibility =
        await _backendService.isAccessibilityPermissionGranted();
    final overlay = await _backendService.isOverlayPermissionGranted();
    final notification = await _backendService.areNotificationsEnabled();
    final battery = await _backendService.isBatteryOptimizationIgnored();
    final keepAlive = await _backendService.isKeepAliveEnabled();

    if (!mounted) {
      return;
    }
    setState(() {
      _usagePermissionGranted = usage;
      _accessibilityGranted = accessibility;
      _overlayGranted = overlay;
      _notificationGranted = notification;
      _batteryOptimizationIgnored = battery;
      _keepAliveEnabled = keepAlive;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await _backendService.areNotificationsEnabled();
    if (granted) {
      return;
    }

    final canRequest = await _backendService.canRequestNotificationPermission();
    if (canRequest) {
      final requestGranted = await _backendService.requestNotificationPermission();
      if (requestGranted) {
        return;
      }
    }

    await _backendService.openNotificationPermissionSettings();
  }

  Future<void> _enableKeepAlive() async {
    await _backendService.setKeepAliveEnabled(true);
  }

  Future<void> _continue() async {
    if (!_requiredPermissionsReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少开启使用统计、无障碍和悬浮窗权限')),
      );
      return;
    }
    widget.onGranted();
  }

  @override
  Widget build(BuildContext context) {
    final permissionCards = <_PermissionCardData>[
      _PermissionCardData(
        title: '应用使用统计',
        description: '用于读取真实使用时长并判断是否超限。',
        icon: Icons.bar_chart_outlined,
        color: const Color(0xFF7EB8DA),
        granted: _usagePermissionGranted,
        required: true,
        actionLabel: '去授权',
        onTap: _backendService.openUsageStatsPermissionSettings,
      ),
      _PermissionCardData(
        title: '无障碍权限',
        description: '用于在受控应用切到前台时稳定触发拦截。',
        icon: Icons.accessibility_new_outlined,
        color: const Color(0xFF9B8FD4),
        granted: _accessibilityGranted,
        required: true,
        actionLabel: '去授权',
        onTap: _backendService.openAccessibilityPermissionSettings,
      ),
      _PermissionCardData(
        title: '悬浮窗权限',
        description: '用于在其他应用上层展示拦截页和提示。',
        icon: Icons.layers_outlined,
        color: AppTheme.primaryColor,
        granted: _overlayGranted,
        required: true,
        actionLabel: '去授权',
        onTap: _backendService.openOverlayPermissionSettings,
      ),
      _PermissionCardData(
        title: '通知权限',
        description: '用于在接近限制前发送提醒通知。',
        icon: Icons.notifications_outlined,
        color: const Color(0xFF5CB85C),
        granted: _notificationGranted,
        required: false,
        actionLabel: '去开启',
        onTap: _requestNotificationPermission,
      ),
      _PermissionCardData(
        title: '电池优化白名单',
        description: '降低系统省电策略对后台监控和拦截的影响。',
        icon: Icons.battery_charging_full_outlined,
        color: const Color(0xFFFFB74D),
        granted: _batteryOptimizationIgnored,
        required: false,
        actionLabel: '去开启',
        onTap: _backendService.openBatteryOptimizationSettings,
      ),
      _PermissionCardData(
        title: '后台保活服务',
        description: '前台服务会提高应用被系统回收后的恢复概率。',
        icon: Icons.motion_photos_auto_outlined,
        color: const Color(0xFF607D8B),
        granted: _keepAliveEnabled,
        required: false,
        actionLabel: '去开启',
        onTap: _enableKeepAlive,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '开始前需要完成授权',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '先把关键权限打开，后面的拦截、提醒和后台存活才会稳定。',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: AnimeCard(
                      padding: const EdgeInsets.all(16),
                      borderColor: _requiredPermissionsReady
                          ? const Color(0xFF43A047)
                          : AppTheme.primaryColor,
                      child: Row(
                        children: [
                          Icon(
                            _requiredPermissionsReady
                                ? Icons.verified_user_outlined
                                : Icons.info_outline,
                            color: _requiredPermissionsReady
                                ? const Color(0xFF43A047)
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _requiredPermissionsReady
                                  ? '关键权限已满足，可以继续。'
                                  : '必需项只有 3 个：使用统计、无障碍、悬浮窗。',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: permissionCards.length,
                      itemBuilder: (context, index) {
                        return _buildPermissionItem(permissionCards[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: AnimeButton(
                            text: _requiredPermissionsReady ? '继续' : '检查并继续',
                            onPressed: () => unawaited(_continue()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AnimeOutlinedButton(
                            text: '暂时跳过',
                            onPressed: widget.onSkip,
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

  Widget _buildPermissionItem(_PermissionCardData permission) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimeCard(
        padding: const EdgeInsets.all(16),
        borderColor: permission.granted ? permission.color : AppTheme.primaryColor,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: permission.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                permission.icon,
                color: permission.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          permission.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: permission.required
                              ? const Color(0xFFE53935).withValues(alpha: 0.1)
                              : permission.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          permission.required ? '必需' : '建议',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: permission.required
                                ? const Color(0xFFE53935)
                                : permission.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    permission.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        permission.granted
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        size: 18,
                        color: permission.granted
                            ? const Color(0xFF43A047)
                            : const Color(0xFFE53935),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        permission.granted ? '已开启' : '未开启',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: permission.granted
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () async {
                await permission.onTap();
                await _loadPermissionStates();
              },
              child: Text(permission.granted ? '已完成' : permission.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
