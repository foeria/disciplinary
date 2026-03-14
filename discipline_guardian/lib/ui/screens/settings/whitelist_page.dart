import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../../data/models/whitelist_app_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_button.dart';

/// 白名单页面
class WhitelistPage extends StatefulWidget {
  const WhitelistPage({super.key});

  @override
  State<WhitelistPage> createState() => _WhitelistPageState();
}

class _WhitelistPageState extends State<WhitelistPage> {
  static const MethodChannel _deviceAppsChannel = MethodChannel(
    'discipline_guardian/device_apps',
  );
  final LocalBackendService _backendService = LocalBackendService();
  bool _isEnabled = false;
  bool _isLoading = true;
  List<WhitelistAppModel> _whitelistApps = const [];

  @override
  void initState() {
    super.initState();
    _loadWhitelist();
  }

  Future<void> _loadWhitelist() async {
    final enabled = await _backendService.getWhitelistEnabled();
    final apps = await _backendService.getWhitelistApps();

    if (!mounted) {
      return;
    }

    setState(() {
      _isEnabled = enabled;
      _whitelistApps = apps;
      _isLoading = false;
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
          '白名单',
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
        child: Column(
          children: [
            // 开关
            _buildEnableSwitch(),
            // 说明
            _buildDescription(),
            // 白名单列表
            Expanded(
              child: _whitelistApps.isEmpty
                  ? _buildEmptyState()
                  : _buildWhitelist(),
            ),
            // 添加按钮
            if (_isEnabled)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimeOutlinedButton(
                    text: '添加白名单应用',
                    icon: Icons.add,
                    onPressed: () => _showAddOptions(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSwitch() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '启用白名单',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '白名单内应用不受监控限制',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          Switch(
            value: _isEnabled,
            onChanged: (v) async {
              setState(() => _isEnabled = v);
              await _backendService.setWhitelistEnabled(v);
            },
            activeThumbColor: const Color(0xFF5CB85C),
            activeTrackColor: const Color(0xFF5CB85C).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (!_isEnabled) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF43A047),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '白名单中的应用将不会被锁定，即使超过使用时间',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无白名单应用',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加需要紧急使用的应用',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhitelist() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _whitelistApps.length,
      itemBuilder: (context, index) {
        final app = _whitelistApps[index];
        final iconColor = _resolveColor(app.packageName);
        final icon = _resolveIcon(app.packageName);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimeCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        app.packageName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFE53935),
                  onPressed: () => _showRemoveDialog(app),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRemoveDialog(WhitelistAppModel app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除确认'),
        content: Text('确定要将 ${app.appName} 从白名单中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _backendService.removeWhitelistApp(app.id);
              await _loadWhitelist();
            },
            child: const Text('移除', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final appNameController = TextEditingController();
    final packageController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加白名单应用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: appNameController,
              decoration: const InputDecoration(labelText: '应用名称'),
            ),
            TextField(
              controller: packageController,
              decoration: const InputDecoration(labelText: '应用包名'),
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
              final navigator = Navigator.of(dialogContext);
              final appName = appNameController.text.trim();
              final packageName = packageController.text.trim();
              if (appName.isEmpty || packageName.isEmpty) {
                return;
              }
              await _backendService.addWhitelistApp(
                appName: appName,
                packageName: packageName,
              );
              if (!mounted) {
                return;
              }
              navigator.pop();
              await _loadWhitelist();
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );

    appNameController.dispose();
    packageController.dispose();
  }

  Future<void> _showAddOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('从设备应用中选择'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _showDeviceAppsPicker();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('手动输入应用信息'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showAddDialog(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeviceAppsPicker() async {
    if (!Platform.isAndroid) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请在 Android 设备上使用该功能')),
      );
      return;
    }

    try {
      final rawApps = await _deviceAppsChannel.invokeListMethod<dynamic>('getInstalledApps') ?? const [];
      final apps = rawApps
          .whereType<Map>()
          .map((app) {
            return _DeviceAppItem(
              appName: (app['appName'] ?? '').toString(),
              packageName: (app['packageName'] ?? '').toString(),
            );
          })
          .where((app) => app.appName.isNotEmpty && app.packageName.isNotEmpty)
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.7,
              child: ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return ListTile(
                    title: Text(app.appName),
                    subtitle: Text(app.packageName),
                    onTap: () async {
                      final navigator = Navigator.of(sheetContext);
                      await _backendService.addWhitelistApp(
                        appName: app.appName,
                        packageName: app.packageName,
                      );
                      if (!mounted) {
                        return;
                      }
                      navigator.pop();
                      await _loadWhitelist();
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('读取设备应用失败，请稍后重试')),
      );
    }
  }

  IconData _resolveIcon(String packageName) {
    if (packageName.contains('phone') || packageName.contains('dialer')) {
      return Icons.phone_outlined;
    }
    if (packageName.contains('mms') || packageName.contains('message')) {
      return Icons.message_outlined;
    }
    if (packageName.contains('camera')) {
      return Icons.camera_alt_outlined;
    }
    return Icons.apps_outlined;
  }

  Color _resolveColor(String packageName) {
    if (packageName.contains('phone')) {
      return const Color(0xFF43A047);
    }
    if (packageName.contains('mms') || packageName.contains('message')) {
      return const Color(0xFF7EB8DA);
    }
    if (packageName.contains('camera')) {
      return const Color(0xFFE53935);
    }
    return const Color(0xFFFF6B9D);
  }
}

class _DeviceAppItem {
  final String appName;
  final String packageName;

  const _DeviceAppItem({
    required this.appName,
    required this.packageName,
  });
}
