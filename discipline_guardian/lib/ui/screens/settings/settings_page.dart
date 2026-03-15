import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../lock/lock_screen.dart';
import 'about_page.dart';
import 'export_page.dart';
import 'notification_page.dart';
import 'question_bank_page.dart';
import 'schedule_page.dart';
import 'system_permissions_page.dart';
import 'theme_page.dart';
import 'whitelist_page.dart';

/// 设置中心页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalBackendService _backendService = LocalBackendService();
  int _unlockQuestionCount = 3;
  int _unlockExtensionMinutes = 15;
  static const List<int> _unlockExtensionOptions = <int>[5, 10, 15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final questionCount = await _backendService.getUnlockQuestionCount();
    final unlockExtension = await _backendService.getUnlockExtensionMinutes();
    if (!mounted) {
      return;
    }
    setState(() {
      _unlockQuestionCount = questionCount;
      _unlockExtensionMinutes = unlockExtension;
    });
  }

  Future<void> _showQuestionCountDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: _unlockQuestionCount.toString(),
    );
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('知识问答解锁'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '解锁时将从题库中随机抽题，题库内可包含常识题和数学题。',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '需答对题目数量',
                      hintText: '请输入 3 到 100',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    final rawValue = controller.text.trim();
                    final parsedValue = int.tryParse(rawValue);
                    if (parsedValue == null || parsedValue < 3 || parsedValue > 100) {
                      setDialogState(() {
                        errorText = '题目数量必须在 3 到 100 之间';
                      });
                      return;
                    }

                    await _backendService.setUnlockMethod('question');
                    await _backendService.setUnlockQuestionCount(parsedValue);
                    if (!mounted || !dialogContext.mounted) {
                      return;
                    }
                    Navigator.pop(dialogContext);
                    setState(() {
                      _unlockQuestionCount = parsedValue;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已设置为答对 $parsedValue 题后解锁')),
                    );
                  },
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _showUnlockExtensionPicker(BuildContext context) async {
    final rootMessenger = ScaffoldMessenger.of(this.context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '解锁延长时长',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ..._unlockExtensionOptions.map((minutes) {
                    final selected = _unlockExtensionMinutes == minutes;
                    return ListTile(
                      title: Text('解锁后延长 $minutes 分钟'),
                      subtitle: const Text('当天内都会按新的临时限额计算'),
                      trailing: selected
                          ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : null,
                      onTap: () => Navigator.pop(context, minutes),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    await _backendService.setUnlockExtensionMinutes(selected);
    if (!mounted) {
      return;
    }
    setState(() {
      _unlockExtensionMinutes = selected;
    });
    rootMessenger.showSnackBar(
      SnackBar(content: Text('已设置解锁后延长 $selected 分钟')),
    );
  }

  Future<bool> _shouldProtectSettingsAccess() async {
    final apps = await _backendService.getAppsPageData();
    return apps.isNotEmpty;
  }

  Future<bool> _requestProtectedSettingsAuthorization(
    String configName,
  ) async {
    if (!await _shouldProtectSettingsAccess()) {
      return true;
    }
    if (!mounted) {
      return false;
    }

    var isAuthorized = false;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          appName: configName,
          usedMinutes: 0,
          limitMinutes: 0,
          unlockMethod: UnlockMethod.question,
          titleText: '需要验证',
          reasonText: '已存在监控应用，修改$configName前请先完成知识问答',
          showUsageSummary: false,
          onUnlockSuccess: () async {
            await _backendService.incrementUnlockQuestionCountAfterSuccess();
            await _loadSettings();
            if (!mounted) {
              return;
            }
            isAuthorized = true;
            Navigator.of(context).pop();
          },
          onExitRequested: () async {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    return isAuthorized;
  }

  Future<void> _openProtectedSettingsAction({
    required String configName,
    required Future<dynamic> Function() action,
  }) async {
    final isAuthorized = await _requestProtectedSettingsAuthorization(
      configName,
    );
    if (!isAuthorized || !mounted) {
      return;
    }
    await action();
    if (mounted) {
      await _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '我的',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 24),
              _buildSectionTitle('锁定设置'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.quiz_outlined,
                iconColor: AppTheme.primaryColor,
                title: '解锁方式',
                subtitle: '知识问答解锁，当前需答对 $_unlockQuestionCount 题',
                onTap: () => _openProtectedSettingsAction(
                  configName: '解锁方式',
                  action: () => _showQuestionCountDialog(context),
                ),
              ),
              _buildSettingItem(
                icon: Icons.timelapse_outlined,
                iconColor: const Color(0xFFFB8C00),
                title: '解锁后延长时长',
                subtitle: '当前：$_unlockExtensionMinutes 分钟',
                onTap: () => _openProtectedSettingsAction(
                  configName: '解锁后延长时长',
                  action: () => _showUnlockExtensionPicker(context),
                ),
              ),
              _buildSettingItem(
                icon: Icons.quiz_outlined,
                iconColor: const Color(0xFF7EB8DA),
                title: '题库管理',
                subtitle: '管理填空题与选择题题库',
                onTap: () => _openProtectedSettingsAction(
                  configName: '题库管理',
                  action: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuestionBankPage()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('监控设置'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.access_time_outlined,
                iconColor: const Color(0xFF9B8FD4),
                title: '监控时段',
                subtitle: '设置监控时间段',
                onTap: () => _openProtectedSettingsAction(
                  configName: '监控时段',
                  action: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SchedulePage()),
                  ),
                ),
              ),
              _buildSettingItem(
                icon: Icons.playlist_add_check_outlined,
                iconColor: const Color(0xFF5CB85C),
                title: '白名单',
                subtitle: '设置白名单应用',
                onTap: () => _openProtectedSettingsAction(
                  configName: '白名单',
                  action: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WhitelistPage()),
                  ),
                ),
              ),
              _buildSettingItem(
                icon: Icons.notifications_outlined,
                iconColor: const Color(0xFFFF9800),
                title: '通知设置',
                subtitle: '提醒开关和提醒方式',
                onTap: () => _openProtectedSettingsAction(
                  configName: '通知权限',
                  action: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  ),
                ),
              ),
              _buildSettingItem(
                icon: Icons.security_outlined,
                iconColor: const Color(0xFF607D8B),
                title: '系统权限中枢',
                subtitle: '统一管理无障碍/悬浮窗/使用统计权限',
                onTap: () => _openProtectedSettingsAction(
                  configName: '系统权限中枢',
                  action: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SystemPermissionsPage(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('个性化'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.palette_outlined,
                iconColor: AppTheme.primaryColor,
                title: '主题',
                subtitle: '切换应用主题风格',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemePage()),
                  );
                  if (!mounted) {
                    return;
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('数据'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.download_outlined,
                iconColor: const Color(0xFF7EB8DA),
                title: '导出数据',
                subtitle: '导出使用统计数据',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportPage()),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('关于'),
              const SizedBox(height: 12),
              _buildSettingItem(
                icon: Icons.info_outline,
                iconColor: const Color(0xFF666666),
                title: '关于',
                subtitle: '版本信息和使用条款',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: AppTheme.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '守护者用户',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '今天也要保持专注！',
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimeCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
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
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
