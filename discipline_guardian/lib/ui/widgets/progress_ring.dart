import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 动漫风格环形进度显示组件
/// 特点：渐变色、动画效果、中心显示内容
class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 - 1.0
  final double size;
  final double strokeWidth;
  final List<Color> gradientColors;
  final Widget? center;
  final bool showAnimation;
  final Duration animationDuration;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 10,
    this.gradientColors = const [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
    this.center,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    if (widget.showAnimation) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        _currentProgress = _progressAnimation.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: _progressAnimation.value,
              strokeWidth: widget.strokeWidth,
              gradientColors: widget.gradientColors,
            ),
            child: Center(child: widget.center),
          ),
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> gradientColors;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景圆环
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 进度圆环
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: gradientColors,
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// 带时间显示的进度环
class TimeProgressRing extends StatelessWidget {
  final int usedMinutes; // 已使用分钟数
  final int limitMinutes; // 限制分钟数
  final double size;
  final List<Color> gradientColors;

  const TimeProgressRing({
    super.key,
    required this.usedMinutes,
    required this.limitMinutes,
    this.size = 160,
    this.gradientColors = const [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
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
    final progress = limitMinutes > 0 ? usedMinutes / limitMinutes : 0.0;
    final isOverLimit = usedMinutes > limitMinutes;

    return ProgressRing(
      progress: progress,
      size: size,
      gradientColors: isOverLimit
          ? [const Color(0xFFE53935), const Color(0xFFFF7043)]
          : gradientColors,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(usedMinutes),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isOverLimit
                  ? const Color(0xFFE53935)
                  : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${_formatTime(limitMinutes)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
