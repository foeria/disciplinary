import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_card.dart';

/// 解锁方式类型
enum UnlockMethod {
  password,
  question,
  math,
  delay,
}

/// 解锁方式数据模型
class UnlockMethodItem {
  final UnlockMethod method;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const UnlockMethodItem({
    required this.method,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// 解锁方式选择页面
class UnlockSetupPage extends StatefulWidget {
  final Function(UnlockMethod) onMethodSelected;
  final VoidCallback onBack;

  const UnlockSetupPage({
    super.key,
    required this.onMethodSelected,
    required this.onBack,
  });

  @override
  State<UnlockSetupPage> createState() => _UnlockSetupPageState();
}

class _UnlockSetupPageState extends State<UnlockSetupPage> {
  final List<UnlockMethodItem> _methods = const [
    UnlockMethodItem(
      method: UnlockMethod.password,
      title: '密码解锁',
      description: '设置4-6位数字密码',
      icon: Icons.lock_outline,
      color: Color(0xFFFF6B9D),
    ),
    UnlockMethodItem(
      method: UnlockMethod.question,
      title: '知识问答解锁',
      description: '预设题库，答题解锁',
      icon: Icons.quiz_outlined,
      color: Color(0xFF7EB8DA),
    ),
    UnlockMethodItem(
      method: UnlockMethod.math,
      title: '数学题解锁',
      description: '解答数学题目解锁',
      icon: Icons.calculate_outlined,
      color: Color(0xFF9B8FD4),
    ),
    UnlockMethodItem(
      method: UnlockMethod.delay,
      title: '延迟等待解锁',
      description: '等待设定时间后自动解锁',
      icon: Icons.timer_outlined,
      color: Color(0xFF5CB85C),
    ),
  ];

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
          '选择解锁方式',
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                '请选择一种解锁方式，\n选择后将无法更改',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // 解锁方式列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _methods.length,
                itemBuilder: (context, index) {
                  return _buildMethodItem(_methods[index]);
                },
              ),
            ),
            // 警告提示
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFFF9800),
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '选择后将无法修改，请谨慎选择',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(UnlockMethodItem method) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimeCard(
        onTap: () => widget.onMethodSelected(method.method),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: method.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                method.icon,
                color: method.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

/// 密码设置页面
class PasswordSetupPage extends StatefulWidget {
  final Function(String) onPasswordSet;
  final VoidCallback onBack;

  const PasswordSetupPage({
    super.key,
    required this.onPasswordSet,
    required this.onBack,
  });

  @override
  State<PasswordSetupPage> createState() => _PasswordSetupPageState();
}

class _PasswordSetupPageState extends State<PasswordSetupPage> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  final List<TextEditingController> _confirmControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _confirmFocusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );

  String? _errorText;
  bool _isConfirming = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _confirmControllers) {
      controller.dispose();
    }
    for (var node in _confirmFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _password => _controllers.map((c) => c.text).join();
  String get _confirmPassword => _confirmControllers.map((c) => c.text).join();

  void _onDigitEntered(List<TextEditingController> controllers,
      List<FocusNode> focusNodes, int index, String value) {
    if (value.isNotEmpty) {
      controllers[index].text = value[value.length - 1];
      if (index < 3) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
        if (!_isConfirming) {
          setState(() {
            _isConfirming = true;
          });
          _confirmFocusNodes[0].requestFocus();
        } else {
          _verifyPassword();
        }
      }
    }
  }

  void _verifyPassword() {
    if (_password != _confirmPassword) {
      setState(() {
        _errorText = '两次输入的密码不一致';
      });
      // 清空确认密码
      for (var controller in _confirmControllers) {
        controller.clear();
      }
      _confirmFocusNodes[0].requestFocus();
    } else {
      widget.onPasswordSet(_password);
    }
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
          '设置密码',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isConfirming ? '请再次输入密码' : '请输入4位数字密码',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirming ? '请再次输入以确认密码' : '用于解锁应用',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              // 密码输入框
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final controllers = _isConfirming
                        ? _confirmControllers
                        : _controllers;
                    final focusNodes = _isConfirming
                        ? _confirmFocusNodes
                        : _focusNodes;
                    return Container(
                      width: 56,
                      height: 64,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: focusNodes[index].hasFocus
                              ? const Color(0xFFFF6B9D)
                              : const Color(0xFFE0E0E0),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: controllers[index],
                        focusNode: focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        obscureText: true,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitEntered(
                          controllers,
                          focusNodes,
                          index,
                          value,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _errorText!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 知识问答设置页面
class QuestionSetupPage extends StatefulWidget {
  final Function(List<Map<String, String>>) onQuestionsSet;
  final VoidCallback onBack;

  const QuestionSetupPage({
    super.key,
    required this.onQuestionsSet,
    required this.onBack,
  });

  @override
  State<QuestionSetupPage> createState() => _QuestionSetupPageState();
}

class _QuestionSetupPageState extends State<QuestionSetupPage> {
  final List<Map<String, String>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  void _addQuestion() {
    if (_questionController.text.isNotEmpty &&
        _answerController.text.isNotEmpty) {
      setState(() {
        _questions.add({
          'question': _questionController.text,
          'answer': _answerController.text,
        });
        _questionController.clear();
        _answerController.clear();
      });
    }
  }

  void _finishSetup() {
    if (_questions.length >= 5) {
      widget.onQuestionsSet(_questions);
    }
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
          '设置题库',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _questions.length >= 5 ? _finishSetup : null,
            child: Text(
              '完成',
              style: TextStyle(
                color: _questions.length >= 5
                    ? const Color(0xFFFF6B9D)
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 统计
            Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('已添加', '${_questions.length}', Colors.green),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                  _buildStatItem('最少需要', '5', Colors.orange),
                ],
              ),
            ),
            // 输入区域
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '添加问题',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: '输入问题',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      hintText: '输入答案',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: AnimeButton(
                      text: '添加问题',
                      onPressed: _addQuestion,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 问题列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _questions[index]['question']!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '答案: ${_questions[index]['answer']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFE53935)),
                          onPressed: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

/// 数学题设置页面
class MathSetupPage extends StatefulWidget {
  final Function(String difficulty, int count) onMathSet;
  final VoidCallback onBack;

  const MathSetupPage({
    super.key,
    required this.onMathSet,
    required this.onBack,
  });

  @override
  State<MathSetupPage> createState() => _MathSetupPageState();
}

class _MathSetupPageState extends State<MathSetupPage> {
  String _difficulty = '简单';
  int _questionCount = 3;

  final List<String> _difficulties = ['简单', '中等', '困难'];

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
          '数学题设置',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择难度',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: _difficulties.map((diff) {
                  final isSelected = _difficulty == diff;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _difficulty = diff),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B9D)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFF6B9D)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Text(
                          diff,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              const Text(
                '题目数量',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '每次解锁需要解答的题目数',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _questionCount > 1
                              ? () => setState(() => _questionCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFFFF6B9D),
                        ),
                        Text(
                          '$_questionCount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        IconButton(
                          onPressed: _questionCount < 10
                              ? () => setState(() => _questionCount++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFFFF6B9D),
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
                  text: '确认设置',
                  onPressed: () => widget.onMathSet(_difficulty, _questionCount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 延迟等待设置页面
class DelaySetupPage extends StatefulWidget {
  final Function(int days) onDelaySet;
  final VoidCallback onBack;

  const DelaySetupPage({
    super.key,
    required this.onDelaySet,
    required this.onBack,
  });

  @override
  State<DelaySetupPage> createState() => _DelaySetupPageState();
}

class _DelaySetupPageState extends State<DelaySetupPage> {
  double _delayDays = 1;

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
          '延迟等待设置',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '等待时间',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '锁定后将等待设定时间后自动解锁',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 64,
                      color: const Color(0xFF5CB85C),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${_delayDays.toInt()} ${_delayDays.toInt() == 1 ? '天' : '天'}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getDelayDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Slider(
                      value: _delayDays,
                      min: 1,
                      max: 7,
                      divisions: 6,
                      activeColor: const Color(0xFF5CB85C),
                      onChanged: (value) {
                        setState(() {
                          _delayDays = value;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '1天',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '7天',
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
                  text: '确认设置',
                  gradientColors: const [
                    Color(0xFF5CB85C),
                    Color(0xFF7BC67B)
                  ],
                  onPressed: () => widget.onDelaySet(_delayDays.toInt()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDelayDescription() {
    switch (_delayDays.toInt()) {
      case 1:
        return '短暂的一天反思时间';
      case 2:
        return '两天的缓冲期';
      case 3:
        return '三天的适应期';
      case 4:
        return '四天的调整期';
      case 5:
        return '五天的习惯养成';
      case 6:
        return '六天的强化期';
      case 7:
        return '整整一周的考验';
      default:
        return '';
    }
  }
}
