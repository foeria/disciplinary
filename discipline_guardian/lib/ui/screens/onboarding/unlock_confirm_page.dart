import 'package:flutter/material.dart';
import '../../widgets/anime_button.dart';
import 'unlock_setup_page.dart';

/// 解锁确认页面
class UnlockConfirmPage extends StatefulWidget {
  final UnlockMethod method;
  final VoidCallback onConfirmed;
  final VoidCallback onBack;

  const UnlockConfirmPage({
    super.key,
    required this.method,
    required this.onConfirmed,
    required this.onBack,
  });

  @override
  State<UnlockConfirmPage> createState() => _UnlockConfirmPageState();
}

class _UnlockConfirmPageState extends State<UnlockConfirmPage> {
  bool _isConfirmed = false;
  final TextEditingController _confirmController = TextEditingController();

  String get _methodTitle {
    switch (widget.method) {
      case UnlockMethod.password:
        return '密码解锁';
      case UnlockMethod.question:
        return '知识问答解锁';
      case UnlockMethod.math:
        return '数学题解锁';
      case UnlockMethod.delay:
        return '延迟等待解锁';
    }
  }

  String get _methodDescription {
    switch (widget.method) {
      case UnlockMethod.password:
        return '使用4位数字密码解锁';
      case UnlockMethod.question:
        return '回答题库中的问题解锁';
      case UnlockMethod.math:
        return '解答数学题目解锁';
      case UnlockMethod.delay:
        return '等待设定时间后自动解锁';
    }
  }

  IconData get _methodIcon {
    switch (widget.method) {
      case UnlockMethod.password:
        return Icons.lock_outline;
      case UnlockMethod.question:
        return Icons.quiz_outlined;
      case UnlockMethod.math:
        return Icons.calculate_outlined;
      case UnlockMethod.delay:
        return Icons.timer_outlined;
    }
  }

  Color get _methodColor {
    switch (widget.method) {
      case UnlockMethod.password:
        return const Color(0xFFFF6B9D);
      case UnlockMethod.question:
        return const Color(0xFF7EB8DA);
      case UnlockMethod.math:
        return const Color(0xFF9B8FD4);
      case UnlockMethod.delay:
        return const Color(0xFF5CB85C);
    }
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: widget.onBack,
        ),
        title: const Text(
          '确认解锁方式',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 警告图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 24),
              // 标题
              const Text(
                '重要提示',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 24),
              // 已选方式
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _methodColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _methodColor.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _methodColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _methodIcon,
                        color: _methodColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '已选择',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _methodTitle,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _methodColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _methodDescription,
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
              ),
              const SizedBox(height: 24),
              // 警告信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '此设置确定后将无法修改',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 确认复选框
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isConfirmed = !_isConfirmed;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isConfirmed
                            ? const Color(0xFFFF6B9D)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isConfirmed
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                      child: _isConfirmed
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '我已了解并确认此设置后将无法更改',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: AnimeButton(
                  text: '确认',
                  isDisabled: !_isConfirmed,
                  onPressed: _isConfirmed ? widget.onConfirmed : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
