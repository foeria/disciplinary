import 'package:flutter/material.dart';

/// 动漫风格应用列表项组件
/// 特点：图标、名称、时间、进度条
class AppListTile extends StatelessWidget {
  final String appName;
  final String? packageName;
  final IconData? icon;
  final Color? iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isLocked;

  const AppListTile({
    super.key,
    required this.appName,
    this.packageName,
    this.icon,
    this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
    this.onTap,
    this.onLongPress,
    this.isLocked = false,
  });

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = limitMinutes > 0
        ? (usedMinutes / limitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isOverLimit = usedMinutes > limitMinutes;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOverLimit
                  ? const Color(0xFFE53935).withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 应用图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFFFF6B9D))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon != null
                    ? Icon(
                        icon,
                        color: iconColor ?? const Color(0xFFFF6B9D),
                        size: 24,
                      )
                    : Icon(
                        Icons.apps,
                        color: iconColor ?? const Color(0xFFFF6B9D),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              // 应用名称和时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '已锁定',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 进度条
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(
                          isOverLimit
                              ? const Color(0xFFE53935)
                              : const Color(0xFFFF6B9D),
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 时间显示
                    Text(
                      '${_formatTime(usedMinutes)} / ${_formatTime(limitMinutes)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverLimit
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简单的应用列表项（用于首页展示）
class SimpleAppListTile extends StatelessWidget {
  final String appName;
  final IconData? icon;
  final Color? iconColor;
  final int usedMinutes;
  final int limitMinutes;
  final VoidCallback? onTap;

  const SimpleAppListTile({
    super.key,
    required this.appName,
    this.icon,
    this.iconColor,
    required this.usedMinutes,
    required this.limitMinutes,
    this.onTap,
  });

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final progress = limitMinutes > 0
        ? (usedMinutes / limitMinutes).clamp(0.0, 1.0)
        : 0.0;
    final isOverLimit = usedMinutes > limitMinutes;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFFFF6B9D))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon ?? Icons.apps,
                color: iconColor ?? const Color(0xFFFF6B9D),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        isOverLimit
                            ? const Color(0xFFE53935)
                            : const Color(0xFFFF6B9D),
                      ),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatTime(usedMinutes),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isOverLimit
                    ? const Color(0xFFE53935)
                    : const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
