import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/app_model.dart';
import '../../../platform/device_apps_bridge.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';
import '../lock/lock_screen.dart';

class _SearchableInstalledApp {
  final DeviceInstalledApp app;
  final String sortKey;
  final String searchText;

  _SearchableInstalledApp(this.app)
      : sortKey = app.appName.trim().toLowerCase(),
        searchText =
            '${app.appName.trim().toLowerCase()} ${app.packageName.trim().toLowerCase()}';
}

class HundredDayPlanPage extends StatefulWidget {
  final String planId;

  const HundredDayPlanPage({
    super.key,
    required this.planId,
  });

  @override
  State<HundredDayPlanPage> createState() => _HundredDayPlanPageState();
}

class _HundredDayPlanPageState extends State<HundredDayPlanPage> {
  static const Duration _searchDebounceDuration = Duration(milliseconds: 120);

  final LocalBackendService _backendService = LocalBackendService();
  final DeviceAppsBridge _deviceAppsBridge = DeviceAppsBridge();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isLoading = true;
  bool _isSaving = false;
  String _searchQuery = '';
  List<_SearchableInstalledApp> _searchableApps =
      const <_SearchableInstalledApp>[];
  List<_SearchableInstalledApp> _visibleApps = const <_SearchableInstalledApp>[];
  Set<String> _selectedPackages = <String>{};
  HundredDayPlanStatus _planStatus = const HundredDayPlanStatus(
    planId: '',
    planName: '',
    enabled: false,
    startedAt: null,
    durationDays: 100,
    apps: <AppModel>[],
    remainingDays: 100,
    elapsedDays: 0,
  );

  bool get _hasPlanApps => _planStatus.apps.isNotEmpty;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _scaffoldBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get _surfaceColor => _scheme.surface;
  Color get _titleColor => _scheme.onSurface;
  Color get _bodyColor => _scheme.onSurface.withValues(alpha: 0.72);
  Color get _outlineColor => _scheme.outline.withValues(alpha: 0.2);
  Color get _primaryColor => _scheme.primary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final installedApps = await _deviceAppsBridge.getInstalledApps();
    final planStatus = await _backendService.getPlanStatus(widget.planId);
    if (planStatus == null) {
      if (!mounted) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(false);
      });
      return;
    }

    final searchableApps = installedApps
        .map(_SearchableInstalledApp.new)
        .toList(growable: false)
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    if (!mounted) {
      return;
    }
    setState(() {
      _searchableApps = searchableApps;
      _visibleApps = _filterApps(searchableApps, _searchQuery);
      _planStatus = planStatus;
      _selectedPackages = planStatus.apps
          .map((app) => app.packageName)
          .toSet();
      _isLoading = false;
    });
  }

  List<_SearchableInstalledApp> _filterApps(
    List<_SearchableInstalledApp> apps,
    String query,
  ) {
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
        _visibleApps = _filterApps(_searchableApps, normalizedQuery);
      });
    });
  }

  Future<bool> _requestAuthorization({
    required String title,
    required String reason,
  }) async {
    if (!mounted) {
      return false;
    }

    var isAuthorized = false;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => LockScreen(
          appName: _planStatus.planName,
          usedMinutes: 0,
          limitMinutes: 30,
          unlockMethod: UnlockMethod.question,
          titleText: title,
          reasonText: reason,
          showUsageSummary: false,
          overrideQuestionCount: 100,
          onUnlockSuccess: () async {
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

  Future<void> _confirmPlan() async {
    if (_selectedPackages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请至少选择一个应用后再确认')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);
    try {
      final selectedApps = _searchableApps
          .where((entry) => _selectedPackages.contains(entry.app.packageName))
          .map((entry) => entry.app)
          .toList(growable: false);
      await _backendService.configurePlan(
        planId: widget.planId,
        selectedApps: selectedApps,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } finally {
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _clearPlanApps() async {
    final isAuthorized = await _requestAuthorization(
      title: '清空计划应用需要验证',
      reason: '该计划已经有应用。清空计划应用前，需要先完成 100 道题验证。',
    );
    if (!isAuthorized || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _backendService.clearPlanApps(widget.planId);
      await _loadData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('计划应用已清空，现在可以返回计划列表删除该计划')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackages.contains(packageName)) {
        _selectedPackages.remove(packageName);
      } else {
        _selectedPackages.add(packageName);
      }
    });
  }

  int _daysSince(DateTime? installedAt) {
    if (installedAt == null) {
      return 0;
    }
    final now = DateTime.now();
    final start = DateTime(installedAt.year, installedAt.month, installedAt.day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: _scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _titleColor),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _planStatus.planName.isEmpty ? '计划详情' : _planStatus.planName,
          style: TextStyle(
            color: _titleColor,
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
                  Expanded(child: _buildBodyScrollView()),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _hasPlanApps
                            ? Row(
                              children: [
                                Expanded(
                                  child: AnimeOutlinedButton(
                                    text: '清空计划应用',
                                    onPressed:
                                        _isSaving ? null : _clearPlanApps,
                                    borderColor: const Color(0xFFE53935),
                                    textColor: const Color(0xFFE53935),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AnimeButton(
                                    text: '返回计划列表',
                                    onPressed: _isSaving
                                        ? null
                                        : () => Navigator.of(context).pop(false),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: AnimeButton(
                                text: _isSaving
                                    ? '保存中...'
                                    : _selectedPackages.isEmpty
                                        ? '返回计划列表'
                                        : '确认生效',
                                onPressed: _isSaving
                                    ? null
                                    : _selectedPackages.isEmpty
                                        ? () => Navigator.of(context).pop(false)
                                        : _confirmPlan,
                              ),
                              ),
                        ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBodyScrollView() {
    final visibleApps = _visibleApps;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildCurrentPlanAppsCard(),
                const SizedBox(height: 16),
                _buildRuleCard(),
                const SizedBox(height: 16),
                if (_hasPlanApps) _buildLockedPlanHintCard() else _buildSearchBar(),
                if (!_hasPlanApps) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (_hasPlanApps)
          const SliverToBoxAdapter(child: SizedBox(height: 16))
        else if (visibleApps.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildEmptyAppListCard()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final app = visibleApps[index].app;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildSelectableAppCard(app),
                  );
                },
                childCount: visibleApps.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final title = _hasPlanApps ? '计划已生效' : '等待加入应用';
    final subtitle = _hasPlanApps
        ? '当前计划中已有 ${_planStatus.apps.length} 个应用。要删除该计划，请先清空计划应用。'
        : '选择应用后点击确认生效，返回后会停留在计划列表页面。';

    return AnimeCard(
      padding: const EdgeInsets.all(18),
      borderColor: _primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: _bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  value: '${_planStatus.remainingDays}',
                  label: '剩余天数',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  value:
                      '${_hasPlanApps ? _planStatus.apps.length : _selectedPackages.length}',
                  label: '计划应用',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  value: _formatDate(_planStatus.startedAt),
                  label: '开始日期',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _bodyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPlanAppsCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '计划中的应用',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 10),
          if (_planStatus.apps.isEmpty)
            Text(
              '当前还是空计划。先从下方列表中选择应用，确认后才会正式生效。',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: _bodyColor,
              ),
            )
          else
            ..._planStatus.apps.map(
              (app) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primaryColor.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _resolveColor(app.packageName)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _resolveIcon(app.packageName),
                          color: _resolveColor(app.packageName),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.appName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '加入手机 ${_daysSince(app.installedAt)} 天',
                              style: TextStyle(
                                fontSize: 12,
                                color: _bodyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRuleCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      borderColor: const Color(0xFFEF6C00),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '计划规则',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildRuleLine('计划中的应用每天只能使用 30 分钟。'),
          _buildRuleLine('计划应用解锁时需要回答 100 道题。'),
          _buildRuleLine('已有应用的计划不会显示添加应用列表。'),
          _buildRuleLine('如需删除计划，请先清空计划应用。'),
        ],
      ),
    );
  }

  Widget _buildRuleLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(
              Icons.circle,
              size: 8,
              color: Color(0xFFEF6C00),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: _bodyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedPlanHintCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: _primaryColor.withValues(alpha: 0.08),
      borderColor: const Color(0xFFEF6C00),
      child: Text(
        '这个计划已经有应用，当前不再显示可添加应用列表。若想删除该计划，请先点击底部“清空计划应用”。',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: _bodyColor,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索要加入计划的应用',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: _surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: _scheduleSearch,
    );
  }

  Widget _buildEmptyAppListCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        '没有找到匹配的应用，换个关键词试试。',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: _bodyColor,
        ),
      ),
    );
  }

  Widget _buildSelectableAppCard(DeviceInstalledApp app) {
    final isSelected = _selectedPackages.contains(app.packageName);
    return AnimeCard(
      onTap: () => _toggleSelection(app.packageName),
      padding: const EdgeInsets.all(16),
      borderColor: isSelected
          ? const Color(0xFF43A047)
          : _outlineColor,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _resolveColor(app.packageName).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _resolveIcon(app.packageName),
              color: _resolveColor(app.packageName),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.appName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '加入手机 ${_daysSince(app.installedAt)} 天',
                  style: TextStyle(
                    fontSize: 12,
                    color: _bodyColor,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            color: isSelected
                ? const Color(0xFF43A047)
                : _scheme.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}


