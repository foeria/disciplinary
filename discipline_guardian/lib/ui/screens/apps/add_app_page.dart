import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../../platform/device_apps_bridge.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

/// 鍙坊鍔犵殑搴旂敤鏁版嵁妯″瀷
class AvailableApp {
  final String appName;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  final DateTime? installedAt;
  final bool isInstalled;
  final String sortKey;
  final String searchText;

  AvailableApp({
    required this.appName,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    this.installedAt,
    this.isInstalled = true,
  })  : sortKey = appName.trim().toLowerCase(),
        searchText = '${appName.trim().toLowerCase()} ${packageName.trim().toLowerCase()}';
}

/// 娣诲姞搴旂敤椤甸潰
class AddAppPage extends StatefulWidget {
  final Future<void> Function(
    String appName,
    String packageName,
    int limitMinutes,
    DateTime? installedAt,
  ) onAppSelected;
  final Set<String> excludedPackages;

  const AddAppPage({
    super.key,
    required this.onAppSelected,
    this.excludedPackages = const <String>{},
  });

  @override
  State<AddAppPage> createState() => _AddAppPageState();
}

class _AddAppPageState extends State<AddAppPage> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 120);

  final DeviceAppsBridge _deviceAppsBridge = DeviceAppsBridge();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  AvailableApp? _selectedApp;
  int _limitMinutes = 60;
  bool _isLoading = true;
  String? _loadError;

  List<AvailableApp> _availableApps = const [];
  List<AvailableApp> _visibleApps = const [];

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    if (!Platform.isAndroid) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableApps = const [];
        _visibleApps = const [];
        _loadError = '当前设备暂不支持读取已安装应用列表，仅支持 Android 设备。';
        _isLoading = false;
      });
      return;
    }

    try {
      final rawApps = await _deviceAppsBridge.getInstalledApps();

      final mappedApps = rawApps
          .map((app) {
            return AvailableApp(
              appName: app.appName,
              packageName: app.packageName,
              icon: _resolveIcon(app.packageName),
              iconColor: _resolveColor(app.packageName),
              installedAt: app.installedAt,
            );
          })
          .where((app) => !widget.excludedPackages.contains(app.packageName))
          .toList(growable: false)
        ..sort((a, b) => a.sortKey.compareTo(b.sortKey));

      if (!mounted) {
        return;
      }

      setState(() {
        _availableApps = mappedApps;
        _visibleApps = _filterApps(mappedApps, _searchQuery);
        _loadError = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableApps = const [];
        _visibleApps = const [];
        _loadError = '读取已安装应用失败，请检查权限或稍后重试。';
        _isLoading = false;
      });
    }
  }

  List<AvailableApp> _filterApps(List<AvailableApp> apps, String query) {
    if (query.isEmpty) {
      return apps;
    }
    return apps
        .where((app) => app.searchText.contains(query))
        .toList(growable: false);
  }

  void _scheduleSearch(String value) {
    final normalizedQuery = value.trim().toLowerCase();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDuration, () {
      if (!mounted || normalizedQuery == _searchQuery) {
        return;
      }
      setState(() {
        _searchQuery = normalizedQuery;
        _visibleApps = _filterApps(_availableApps, normalizedQuery);
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final showSearchBar = _selectedApp == null;
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : showSearchBar
            ? _buildAppList()
            : _buildLimitSetting();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '娣诲姞搴旂敤',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (showSearchBar)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: _scheduleSearch,
                  decoration: InputDecoration(
                    hintText: '搜索应用...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF999999)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppList() {
    final filteredApps = _visibleApps;

    if (_loadError != null) {
      return _buildLoadError();
    }

    if (filteredApps.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) {
        final app = filteredApps[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimeCard(
            onTap: () {
              setState(() {
                _selectedApp = app;
              });
            },
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: app.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(app.icon, color: app.iconColor, size: 24),
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
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFFFF6B9D),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLimitSetting() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 杩斿洖鎸夐挳鍜屾爣棰?
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedApp = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                color: const Color(0xFF666666),
              ),
              const Text(
                '璁剧疆姣忔棩闄愬埗',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 閫変腑搴旂敤淇℃伅
          if (_selectedApp != null)
            AnimeCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _selectedApp!.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _selectedApp!.icon,
                      color: _selectedApp!.iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedApp!.appName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          // 闄愬埗鏃堕棿璁剧疆
          const Text(
            '姣忔棩浣跨敤闄愬埗',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _formatTime(_limitMinutes),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B9D),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _limitMinutes.toDouble(),
                  min: 1,
                  max: 480,
                  divisions: 479,
                  activeColor: const Color(0xFFFF6B9D),
                  onChanged: (value) {
                    setState(() {
                      _limitMinutes = value.toInt();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1m',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '8h',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: AnimeButton(
              text: '纭娣诲姞',
              onPressed: () async {
                await widget.onAppSelected(
                  _selectedApp!.appName,
                  _selectedApp!.packageName,
                  _limitMinutes,
                  _selectedApp!.installedAt,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF666666)),
            ),
            const SizedBox(height: 12),
            AnimeOutlinedButton(
              text: '閲嶈瘯',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _loadError = null;
                });
                _loadInstalledApps();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty ? '没有可添加的应用。' : '没有匹配的应用。',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  IconData _resolveIcon(String packageName) {
    if (packageName.contains('tencent') || packageName.contains('game')) {
      return Icons.games_outlined;
    }
    if (packageName.contains('ugc') || packageName.contains('video')) {
      return Icons.smart_display_outlined;
    }
    if (packageName.contains('qq') || packageName.contains('chat')) {
      return Icons.chat_outlined;
    }
    if (packageName.contains('camera')) {
      return Icons.camera_alt_outlined;
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
    if (packageName.contains('qq') || packageName.contains('chat')) {
      return const Color(0xFF12B7F5);
    }
    if (packageName.contains('camera')) {
      return const Color(0xFF43A047);
    }
    return const Color(0xFFFF6B9D);
  }
}
