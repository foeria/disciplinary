import 'package:flutter/material.dart';

import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/progress_ring.dart';

class AppSettingsPage extends StatefulWidget {
  final String appName;
  final String packageName;
  final String? planName;
  final IconData icon;
  final Color iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final bool isHundredDayPlan;
  final bool isLocked;
  final Future<void> Function(int) onLimitChanged;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onDelete;

  const AppSettingsPage({
    super.key,
    required this.appName,
    required this.packageName,
    this.planName,
    required this.icon,
    required this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
    this.isHundredDayPlan = false,
    required this.isLocked,
    required this.onLimitChanged,
    required this.onUnlock,
    required this.onDelete,
  });

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  late int _limitMinutes;

  @override
  void initState() {
    super.initState();
    _limitMinutes = widget.limitMinutes;
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${mins}m';
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
          '应用设置',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppInfo(),
              const SizedBox(height: 24),
              _buildUsageProgress(),
              const SizedBox(height: 24),
              _buildLimitSetting(),
              const SizedBox(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (widget.isHundredDayPlan) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7E57C2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.planName == null || widget.planName!.trim().isEmpty
                          ? '计划中'
                          : '所属计划：${widget.planName}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7E57C2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageProgress() {
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日使用情况',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              if (widget.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '已锁定',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: TimeProgressRing(
              usedMinutes: widget.usedMinutes,
              limitMinutes: widget.limitMinutes,
              size: 140,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitSetting() {
    if (widget.isHundredDayPlan) {
      final planName =
          widget.planName == null || widget.planName!.trim().isEmpty
              ? '当前计划'
              : widget.planName!;
      return AnimeCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '计划规则',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$planName 中的应用按计划单独计算，不使用普通模式的限额。计划生效期间，每天仅可使用 30 分钟；若要解锁、移出计划或调整计划内容，需要完成 100 道题。',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }

    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '每日限额',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _limitMinutes > 15
                    ? () {
                        setState(() {
                          _limitMinutes -= 15;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: const Color(0xFFFF6B9D),
                iconSize: 32,
              ),
              Text(
                _formatTime(_limitMinutes),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B9D),
                ),
              ),
              IconButton(
                onPressed: _limitMinutes < 480
                    ? () {
                        setState(() {
                          _limitMinutes += 15;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFFF6B9D),
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _limitMinutes.toDouble(),
            min: 15,
            max: 480,
            divisions: 31,
            activeColor: const Color(0xFFFF6B9D),
            onChanged: (value) {
              setState(() {
                _limitMinutes = value.toInt();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15m',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              Text(
                '8h',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AnimeButton(
              text: '保存限额',
              onPressed: () async {
                await widget.onLimitChanged(_limitMinutes);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('限额已更新')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        if (widget.isLocked)
          SizedBox(
            width: double.infinity,
            child: AnimeButton(
              text: '立即解锁',
              gradientColors: const [Color(0xFF43A047), Color(0xFF66BB6A)],
              icon: Icons.lock_open_outlined,
              onPressed: () async => widget.onUnlock(),
            ),
          ),
        if (widget.isLocked) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AnimeOutlinedButton(
            text: '移除受控应用',
            borderColor: const Color(0xFFE53935),
            textColor: const Color(0xFFE53935),
            onPressed: _showDeleteDialog,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确认将 ${widget.appName} 从受控应用中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.onDelete();
            },
            child: const Text(
              '移除',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}
