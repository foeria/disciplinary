import 'package:flutter/material.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/progress_ring.dart';

/// 应用设置页面
class AppSettingsPage extends StatefulWidget {
  final String appName;
  final String packageName;
  final IconData icon;
  final Color iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final bool isLocked;
  final Future<void> Function(int) onLimitChanged;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onDelete;

  const AppSettingsPage({
    super.key,
    required this.appName,
    required this.packageName,
    required this.icon,
    required this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
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
    } else if (hours > 0) {
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
            onPressed: () => _showDeleteDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 应用信息
              _buildAppInfo(),
              const SizedBox(height: 24),
              // 使用进度
              _buildUsageProgress(),
              const SizedBox(height: 24),
              // 限制设置
              _buildLimitSetting(),
              const SizedBox(height: 24),
              // 操作按钮
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
                const SizedBox(height: 4),
                Text(
                  widget.packageName,
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
                '今日使用',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              if (widget.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return AnimeCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '每日限制',
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
              text: '保存设置',
              onPressed: () async {
                await widget.onLimitChanged(_limitMinutes);
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('设置已保存')),
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
              text: '手动解锁',
              gradientColors: const [Color(0xFF43A047), Color(0xFF66BB6A)],
              icon: Icons.lock_open_outlined,
              onPressed: () async => widget.onUnlock(),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: AnimeOutlinedButton(
            text: '删除监控',
            borderColor: const Color(0xFFE53935),
            textColor: const Color(0xFFE53935),
            onPressed: () => _showDeleteDialog(),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除 ${widget.appName} 的监控吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onDelete();
            },
            child: const Text(
              '删除',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );
  }
}
