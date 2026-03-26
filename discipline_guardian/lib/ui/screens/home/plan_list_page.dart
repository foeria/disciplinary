import 'package:flutter/material.dart';

import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';
import 'hundred_day_plan_page.dart';

class PlanListPage extends StatefulWidget {
  const PlanListPage({super.key});

  @override
  State<PlanListPage> createState() => _PlanListPageState();
}

class _PlanListPageState extends State<PlanListPage> {
  final LocalBackendService _backendService = LocalBackendService();

  List<HundredDayPlanStatus> _plans = const <HundredDayPlanStatus>[];
  bool _isLoading = true;
  bool _selectionMode = false;
  bool _hasChanges = false;
  Set<String> _selectedPlanIds = <String>{};
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _scaffoldBackground => Theme.of(context).scaffoldBackgroundColor;
  Color get _surfaceColor => _scheme.surface;
  Color get _titleColor => _scheme.onSurface;
  Color get _bodyColor => _scheme.onSurface.withValues(alpha: 0.72);
  Color get _mutedColor => _scheme.onSurface.withValues(alpha: 0.58);
  Color get _primaryColor => _scheme.primary;
  Color get _successColor => const Color(0xFF43A047);

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final plans = await _backendService.getPlanStatuses();
    if (!mounted) {
      return;
    }
    setState(() {
      _plans = plans;
      _isLoading = false;
    });
  }

  Future<void> _closePage() async {
    if (_selectionMode) {
      setState(() {
        _selectionMode = false;
        _selectedPlanIds = <String>{};
      });
      return;
    }
    Navigator.of(context).pop(_hasChanges);
  }

  Future<void> _openPlan(HundredDayPlanStatus plan) async {
    if (_selectionMode) {
      _toggleSelection(plan.planId);
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HundredDayPlanPage(planId: plan.planId),
      ),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      _hasChanges = true;
      await _loadPlans();
      return;
    }
    await _loadPlans();
  }

  Future<void> _createPlan() async {
    final planName = await showDialog<String>(
      context: context,
      builder: (_) => const _CreatePlanDialog(),
    );
    if (planName == null || planName.trim().isEmpty) {
      return;
    }

    final plan = await _backendService.createPlan(name: planName.trim());
    if (!mounted) {
      return;
    }

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => HundredDayPlanPage(planId: plan.id),
      ),
    );
    if (!mounted) {
      return;
    }
    if (changed == true) {
      _hasChanges = true;
    }
    await _loadPlans();
  }

  void _toggleSelection(String planId) {
    setState(() {
      if (_selectedPlanIds.contains(planId)) {
        _selectedPlanIds.remove(planId);
      } else {
        _selectedPlanIds.add(planId);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedPlanIds = <String>{};
      }
    });
  }

  Future<void> _deleteSelectedPlans() async {
    final selectedPlans = _plans
        .where((plan) => _selectedPlanIds.contains(plan.planId))
        .toList(growable: false);
    if (selectedPlans.isEmpty) {
      return;
    }

    final nonEmptyPlans = selectedPlans
        .where((plan) => plan.apps.isNotEmpty)
        .toList(growable: false);
    if (nonEmptyPlans.isNotEmpty) {
      final planNames = nonEmptyPlans.map((plan) => plan.planName).join('、');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('以下计划仍有应用，请先清空后再删除：$planNames'),
        ),
      );
      return;
    }

    await _backendService.deletePlans(
      selectedPlans.map((plan) => plan.planId).toList(growable: false),
    );
    _hasChanges = true;
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedPlanIds = <String>{};
      _selectionMode = false;
    });
    await _loadPlans();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除 ${selectedPlans.length} 个空计划')),
    );
  }

  Future<bool> _handleSwipeDelete(HundredDayPlanStatus plan) async {
    if (plan.apps.isNotEmpty) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('计划“${plan.planName}”仍有应用，请先进入计划清空应用后再删除'),
        ),
      );
      return false;
    }

    await _backendService.deletePlan(plan.planId);
    _hasChanges = true;
    return true;
  }

  void _onPlanDismissed(HundredDayPlanStatus plan) {
    if (!mounted) {
      return;
    }
    setState(() {
      _plans = _plans
          .where((item) => item.planId != plan.planId)
          .toList(growable: false);
      _selectedPlanIds.remove(plan.planId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已删除空计划“${plan.planName}”')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _closePage();
      },
      child: Scaffold(
        backgroundColor: _scaffoldBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: _titleColor),
            onPressed: _closePage,
          ),
          title: Text(
            _selectionMode ? '选择计划' : '计划列表',
            style: TextStyle(
              color: _titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_plans.isNotEmpty)
              TextButton(
                onPressed: _toggleSelectionMode,
                child: Text(
                  _selectionMode ? '取消' : '多选',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                  ),
                ),
              ),
            if (_selectionMode)
              IconButton(
                onPressed:
                    _selectedPlanIds.isEmpty ? null : _deleteSelectedPlans,
                icon: const Icon(Icons.delete_outline),
                color: _selectedPlanIds.isEmpty
                    ? _mutedColor
                    : _scheme.error,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCreatePlanCard(),
                  const SizedBox(height: 18),
                  if (_plans.isEmpty)
                    _buildEmptyPlansCard()
                  else
                    ..._plans.map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPlanCard(plan),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildCreatePlanCard() {
    final isDisabled = _selectionMode;
    final startColor = isDisabled
        ? Color.alphaBlend(
            _scheme.onSurface.withValues(alpha: 0.18),
            _surfaceColor,
          )
        : _primaryColor;
    final endColor = isDisabled
        ? Color.alphaBlend(
            _scheme.onSurface.withValues(alpha: 0.1),
            _surfaceColor,
          )
        : Color.lerp(_primaryColor, _scheme.secondary, 0.35) ?? _primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : _createPlan,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[startColor, endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: startColor.withValues(alpha: isDisabled ? 0.08 : 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.add_task_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '新建计划',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isDisabled
                            ? '退出多选后才能新建计划'
                            : '先创建计划，再进入计划中选择应用并生效',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlansCard() {
    return AnimeCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        '还没有计划。先新建一个计划，再把应用加入其中开始独立的 100 天倒计时。',
        style: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: _bodyColor,
        ),
      ),
    );
  }

  Widget _buildPlanCard(HundredDayPlanStatus plan) {
    final isSelected = _selectedPlanIds.contains(plan.planId);
    final accentColor = isSelected ? _successColor : _primaryColor;
    final card = AnimeCard(
      onTap: () => _openPlan(plan),
      padding: const EdgeInsets.all(18),
      borderColor: accentColor,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _selectionMode
                  ? (isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked)
                  : Icons.event_note_outlined,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.planName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.apps.isEmpty
                      ? '空计划，可直接删除'
                      : '已加入 ${plan.apps.length} 个应用，删除前请先清空计划应用',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _bodyColor,
                  ),
                ),
              ],
            ),
          ),
          if (!_selectionMode) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.chevron_right,
              color: _scheme.onSurface.withValues(alpha: 0.42),
            ),
          ],
        ],
      ),
    );

    if (_selectionMode) {
      return card;
    }

    return Dismissible(
      key: ValueKey<String>('plan-${plan.planId}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) => _handleSwipeDelete(plan),
      onDismissed: (_) => _onPlanDismissed(plan),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: _scheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_outline,
          color: _scheme.onError,
          size: 28,
        ),
      ),
      child: card,
    );
  }
}

class _CreatePlanDialog extends StatefulWidget {
  const _CreatePlanDialog();

  @override
  State<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends State<_CreatePlanDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close([String? value]) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建计划'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(
          hintText: '请输入计划名称',
        ),
        onSubmitted: (_) => _close(_controller.text.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => _close(_controller.text.trim()),
          child: const Text('确认'),
        ),
      ],
    );
  }
}
