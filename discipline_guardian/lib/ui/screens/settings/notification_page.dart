import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/notification_settings_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

/// 通知设置页面
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with WidgetsBindingObserver {
  final LocalBackendService _backendService = LocalBackendService();
  late bool _reminderEnabled;
  late int _reminderMinutes;
  late bool _liveActivityEnabled;
  late bool _soundEnabled;
  bool _isLoading = true;
  bool _isRequestingPermission = false;
  bool _notificationPermissionGranted = false;
  String _settingsId = 'default';

  final List<int> _reminderOptions = [5, 3, 1];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reminderEnabled = false;
    _reminderMinutes = 5;
    _liveActivityEnabled = false;
    _soundEnabled = false;
    _loadSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationPermission();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _backendService.getNotificationSettings();
    final permissionGranted = await _backendService.areNotificationsEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _settingsId = settings.id;
      _reminderEnabled = settings.reminderEnabled;
      _reminderMinutes = settings.reminderMinutes;
      _liveActivityEnabled = settings.liveActivityEnabled;
      _soundEnabled = settings.soundEnabled;
      _notificationPermissionGranted = permissionGranted;
      _isLoading = false;
    });
  }

  Future<void> _refreshNotificationPermission() async {
    final permissionGranted = await _backendService.areNotificationsEnabled();
    if (!mounted) {
      return;
    }

    setState(() {
      _notificationPermissionGranted = permissionGranted;
      if (!permissionGranted) {
        _reminderEnabled = false;
      }
    });
  }

  Future<void> _handleReminderToggle(bool value) async {
    if (!value) {
      setState(() {
        _reminderEnabled = false;
      });
      return;
    }

    final permissionGranted = await _ensureNotificationPermission();
    if (!mounted) {
      return;
    }

    if (!permissionGranted) {
      setState(() {
        _reminderEnabled = false;
      });
      return;
    }

    setState(() {
      _notificationPermissionGranted = true;
      _reminderEnabled = true;
    });
  }

  Future<bool> _ensureNotificationPermission() async {
    final alreadyGranted = await _backendService.areNotificationsEnabled();
    if (alreadyGranted) {
      return true;
    }

    final canRequestDirectly =
        await _backendService.canRequestNotificationPermission();
    if (canRequestDirectly) {
      if (mounted) {
        setState(() => _isRequestingPermission = true);
      }
      try {
        final granted = await _backendService.requestNotificationPermission();
        if (granted) {
          return true;
        }
      } finally {
        if (mounted) {
          setState(() => _isRequestingPermission = false);
        }
      }
    }

    if (!mounted) {
      return false;
    }

    final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('通知权限未开启'),
              content: const Text(
                '提醒功能需要通知权限。未授予时，将无法在接近时限时收到提醒。',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('稍后再说'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('打开系统设置'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (shouldOpenSettings) {
      await _backendService.openNotificationPermissionSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请在系统页面中开启通知权限，返回后会自动刷新状态')),
        );
      }
    }
    return false;
  }

  Future<void> _saveSettings() async {
    final model = NotificationSettingsModel(
      id: _settingsId,
      reminderEnabled: _notificationPermissionGranted && _reminderEnabled,
      reminderMinutes: _reminderMinutes,
      liveActivityEnabled: _liveActivityEnabled,
      soundEnabled: _soundEnabled,
      quietHoursStart: null,
      quietHoursEnd: null,
      updatedAt: DateTime.now(),
    );
    await _backendService.saveNotificationSettings(model);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
    Navigator.pop(context);
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
          '通知设置',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('使用提醒'),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      '启用提醒',
                      '在使用时间即将达到限制时提醒',
                      _reminderEnabled,
                      (value) => unawaited(_handleReminderToggle(value)),
                    ),
                    const SizedBox(height: 8),
                    _buildPermissionStatusCard(),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 12),
                      _buildReminderOptions(),
                    ],
                    const SizedBox(height: 24),
                    _buildSectionTitle('实时提醒'),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      '灵动岛实时活动',
                      '在锁定屏幕上显示实时使用状态',
                      _liveActivityEnabled,
                      (value) => setState(() => _liveActivityEnabled = value),
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchCard(
                      '提示音',
                      '解锁时播放提示音',
                      _soundEnabled,
                      (value) => setState(() => _soundEnabled = value),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: AnimeButton(
                        text: '保存设置',
                        isLoading: _isRequestingPermission,
                        onPressed: _saveSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF999999),
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                const SizedBox(height: 4),
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
          Switch(
            value: value,
            onChanged: _isRequestingPermission
                ? null
                : onChanged,
            activeThumbColor: AppTheme.primaryColor,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      borderColor: _notificationPermissionGranted
          ? const Color(0xFF43A047)
          : AppTheme.primaryColor,
      child: Row(
        children: [
          Icon(
            _notificationPermissionGranted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: _notificationPermissionGranted
                ? const Color(0xFF43A047)
                : AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _notificationPermissionGranted
                  ? '通知权限已开启，提醒功能可以正常生效。'
                  : '通知权限未开启。Android 13 及以上会先弹系统授权框，其他系统会引导进入设置页。',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
          ),
          TextButton(
            onPressed: _isRequestingPermission
                ? null
                : () async {
                    await _ensureNotificationPermission();
                    await _refreshNotificationPermission();
                  },
            child: Text(_notificationPermissionGranted ? '已开启' : '去开启'),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOptions() {
    return AnimeCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '提前提醒',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _reminderOptions.map((minutes) {
              final isSelected = _reminderMinutes == minutes;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _reminderMinutes = minutes),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$minutes 分钟',
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
        ],
      ),
    );
  }
}
