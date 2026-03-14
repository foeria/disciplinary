import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

/// 解锁方式类型
enum UnlockMethod { password, question, math, delay }

/// 锁屏拦截页面
class LockScreen extends StatefulWidget {
  final String appName;
  final int usedMinutes;
  final int limitMinutes;
  final UnlockMethod unlockMethod;
  final String titleText;
  final String reasonText;
  final Future<void> Function() onUnlockSuccess;
  final Future<void> Function()? onExitRequested;
  final VoidCallback? onEmergencyCall;

  const LockScreen({
    super.key,
    required this.appName,
    required this.usedMinutes,
    required this.limitMinutes,
    required this.unlockMethod,
    this.titleText = '应用已锁定',
    this.reasonText = '使用时间已达上限，请完成知识问答后继续使用',
    required this.onUnlockSuccess,
    this.onExitRequested,
    this.onEmergencyCall,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  static const Color _pageBackground = Color(0xFF10131A);
  static const Color _surfaceColor = Color(0xFF171B24);
  static const Color _surfaceHighlight = Color(0xFF1D2330);
  static const Color _primaryTextColor = Colors.white;
  static const Color _secondaryTextColor = Color(0xFFB7BFCC);
  static const Color _dividerColor = Color(0x2AFFFFFF);
  final LocalBackendService _backendService = LocalBackendService();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  int _requiredQuestionCount = 3;
  List<Map<String, String>> _questions = const [
    {'question': '一年有几个季节？', 'answer': '4|四季'},
    {'question': '水的化学式是什么？', 'answer': 'H2O'},
    {'question': '中国的首都是哪里？', 'answer': '北京'},
    {'question': '12 - 5 = ?', 'answer': '7'},
    {'question': '地球绕着哪颗恒星公转？', 'answer': '太阳'},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 5, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeOut),
    );
    _loadUnlockConfig();
  }

  Future<void> _loadUnlockConfig() async {
    try {
      final questionCount = await _backendService.getUnlockQuestionCount();
      final questionModels = await _backendService.getQuestionBank(
        type: QuestionType.fill,
      );
      final questions = questionModels.isEmpty
          ? _questions
          : questionModels
              .map((q) => {'question': q.question, 'answer': q.answer})
              .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _requiredQuestionCount = questionCount;
        _questions = questions;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  Future<void> _onUnlockSuccess() async {
    await _runBusyAction(widget.onUnlockSuccess);
  }

  Future<void> _handleBackPressed() async {
    if (_isActionInProgress || widget.onExitRequested == null) {
      return;
    }
    await _runBusyAction(widget.onExitRequested!);
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    if (_isActionInProgress) {
      return;
    }
    setState(() => _isActionInProgress = true);
    try {
      await action();
    } catch (_) {
      // Keep lock screen alive if native navigation fails.
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isActionInProgress) {
          return;
        }
        unawaited(_handleBackPressed());
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: _pageBackground,
            body: Stack(
              children: [
                _buildBackdrop(),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: child,
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildLockHeader(),
                                  const SizedBox(height: 16),
                                  _buildUsageSummary(),
                                  const SizedBox(height: 16),
                                  _isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 56,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : _QuestionUnlockView(
                                          questions: _questions,
                                          requiredQuestionCount:
                                              _requiredQuestionCount,
                                          onSuccess: () => unawaited(
                                            _onUnlockSuccess(),
                                          ),
                                          onError: _triggerShake,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isActionInProgress)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xAA000000),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackdrop() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.18),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _pageBackground,
                  const Color(0xFF131722),
                  AppTheme.primaryColor.withValues(alpha: 0.08),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockHeader() {
    return AnimeCard(
      backgroundColor: _surfaceColor,
      borderColor: AppTheme.primaryColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '专注拦截中',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.titleText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _primaryTextColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.reasonText,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _secondaryTextColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageSummary() {
    return AnimeCard(
      backgroundColor: _surfaceColor,
      borderColor: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.apps_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.appName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '请完成知识问答后继续使用',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: '今日已用',
                  value: '${widget.usedMinutes} 分钟',
                  color: const Color(0xFFE57373),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  label: '每日限额',
                  value: '${widget.limitMinutes} 分钟',
                  color: const Color(0xFF64B5F6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionUnlockView extends StatefulWidget {
  final List<Map<String, String>> questions;
  final int requiredQuestionCount;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _QuestionUnlockView({
    required this.questions,
    required this.requiredQuestionCount,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_QuestionUnlockView> createState() => _QuestionUnlockViewState();
}

class _QuestionUnlockViewState extends State<_QuestionUnlockView> {
  static const Color _surfaceColor = _LockScreenState._surfaceColor;
  static const Color _surfaceHighlight = _LockScreenState._surfaceHighlight;
  static const Color _primaryTextColor = _LockScreenState._primaryTextColor;
  static const Color _secondaryTextColor =
      _LockScreenState._secondaryTextColor;
  static const Color _dividerColor = _LockScreenState._dividerColor;
  final TextEditingController _answerController = TextEditingController();
  late List<Map<String, String>> _questionQueue;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  String _errorMessage = '';
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _questionQueue = List<Map<String, String>>.from(widget.questions)..shuffle();
  }

  Map<String, String> get _currentQuestion {
    if (_questionQueue.isEmpty) {
      return const {'question': '当前题库为空，请返回后补充题目', 'answer': ''};
    }
    return _questionQueue[_currentQuestionIndex];
  }

  void _advanceQuestion() {
    if (_questionQueue.isEmpty) {
      return;
    }

    _currentQuestionIndex += 1;
    if (_currentQuestionIndex < _questionQueue.length) {
      return;
    }

    _questionQueue = List<Map<String, String>>.from(widget.questions)..shuffle();
    _currentQuestionIndex = 0;
  }

  void _submitAnswer() {
    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty || _isVerifying) {
      return;
    }

    final acceptableAnswers =
        (_currentQuestion['answer'] ?? '').split('|').map((answer) {
      return answer.trim().toLowerCase();
    }).where((answer) => answer.isNotEmpty).toSet();

    final isCorrect = acceptableAnswers.contains(userAnswer.toLowerCase());
    setState(() => _isVerifying = true);

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) {
        return;
      }

      if (isCorrect) {
        final nextCorrectAnswers = _correctAnswers + 1;
        if (nextCorrectAnswers >= widget.requiredQuestionCount) {
          widget.onSuccess();
          return;
        }

        setState(() {
          _correctAnswers = nextCorrectAnswers;
          _errorMessage = '';
          _answerController.clear();
          _advanceQuestion();
          _isVerifying = false;
        });
        return;
      }

      setState(() {
        _errorMessage = '回答错误，请重新输入';
        _answerController.clear();
        _isVerifying = false;
      });
      widget.onError();
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final progress = widget.requiredQuestionCount == 0
        ? 0.0
        : _correctAnswers / widget.requiredQuestionCount;

    return AnimeCard(
      backgroundColor: _surfaceColor,
      borderColor: AppTheme.primaryColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '知识问答解锁',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryTextColor,
                ),
              ),
              Text(
                '$_correctAnswers / ${widget.requiredQuestionCount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          Text(
            '需连续答对 ${widget.requiredQuestionCount} 题后解锁，题库中包含常识题和数学题',
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surfaceHighlight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前题目',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _currentQuestion['question'] ?? '当前题目加载失败',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _answerController,
            enabled: !_isVerifying,
            onSubmitted: (_) => _submitAnswer(),
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            cursorColor: AppTheme.primaryColor,
            decoration: InputDecoration(
              hintText: '请输入答案',
              hintStyle: const TextStyle(color: _secondaryTextColor),
              filled: true,
              fillColor: _surfaceHighlight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: _errorMessage.isEmpty
                ? const SizedBox(height: 0)
                : Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 24 + bottomInset),
          SizedBox(
            width: double.infinity,
            child: AnimeButton(
              text: _isVerifying ? '校验中...' : '提交答案',
              onPressed: _isVerifying ? null : _submitAnswer,
            ),
          ),
        ],
      ),
    );
  }
}
