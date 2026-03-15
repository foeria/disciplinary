import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/question_model.dart';
import '../../../services/local_backend_service.dart';
import '../../widgets/anime_card.dart';

/// 题库管理页面
class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({super.key});

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  final LocalBackendService _backendService = LocalBackendService();
  final List<QuestionModel> _questions = <QuestionModel>[];

  String _selectedCategory = '全部';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _backendService.getQuestionBank();
    if (!mounted) {
      return;
    }
    setState(() {
      _questions
        ..clear()
        ..addAll(questions);
      _isLoading = false;
    });
  }

  /// 动态提取题目中实际存在的分类
  List<String> get _allCategories {
    final typeFilters = ['全部', '填空题', '选择题'];
    final contentCategories = _questions
        .map((q) => q.category)
        .toSet()
        .toList()
      ..sort();
    return [...typeFilters, ...contentCategories];
  }

  List<QuestionModel> get _filteredQuestions {
    if (_selectedCategory == '全部') return _questions;
    if (_selectedCategory == '填空题') return _questions.where((q) => q.type == QuestionType.fill).toList();
    if (_selectedCategory == '选择题') return _questions.where((q) => q.type == QuestionType.choice).toList();
    return _questions.where((q) => q.category == _selectedCategory).toList();
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
          '题库管理',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuestionEditPage()),
              );
              await _loadQuestions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildStats(),
                  _buildCategoryFilter(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredQuestions.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionCard(_filteredQuestions[index]);
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuestionEditPage()),
          );
          await _loadQuestions();
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStats() {
    final fillCount = _questions.where((q) => q.type == QuestionType.fill).length;
    final choiceCount = _questions.where((q) => q.type == QuestionType.choice).length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总题数', '${_questions.length}', AppTheme.primaryColor),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem('填空题', '$fillCount', const Color(0xFF7EB8DA)),
          Container(width: 1, height: 40, color: Colors.grey.shade200),
          _buildStatItem('选择题', '$choiceCount', const Color(0xFF9B8FD4)),
        ],
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

  Widget _buildCategoryFilter() {
    final categories = _allCategories;
    // 如果当前选中的分类在新列表中不存在（题目被全部删除时），重置为全部
    final effectiveSelected =
        categories.contains(_selectedCategory) ? _selectedCategory : '全部';
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = effectiveSelected == category;
          // 前三项是类型筛选，其余是内容分类
          final isTypeFilter = index < 3;
          final chipColor = isTypeFilter
              ? (index == 1
                  ? const Color(0xFF5CB85C) // 填空题 绿
                  : index == 2
                      ? const Color(0xFF9B8FD4) // 选择题 紫
                  : AppTheme.primaryColor)
              : AppTheme.primaryColor;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: chipColor.withValues(alpha: 0.2),
              checkmarkColor: chipColor,
              labelStyle: TextStyle(
                color: isSelected ? chipColor : const Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? chipColor : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionCard(QuestionModel question) {
    final isChoice = question.type == QuestionType.choice;
    final typeColor = isChoice ? const Color(0xFF9B8FD4) : const Color(0xFF5CB85C);
    final typeLabel = isChoice ? '选择题' : '填空题';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimeCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 题型标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(fontSize: 12, color: typeColor, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                // 分类标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.category,
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuestionEditPage(question: question)),
                    );
                    await _loadQuestions();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: const Color(0xFFE53935),
                  onPressed: () => _showDeleteDialog(question),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            // 选择题显示选项
            if (isChoice && question.options != null) ...
              question.options!.asMap().entries.map((e) {
                final optionLetter = String.fromCharCode(65 + e.key); // A B C D
                final isCorrect = question.answer == optionLetter;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? const Color(0xFF43A047).withValues(alpha: 0.15)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            optionLetter,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? const Color(0xFF43A047) : Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.value.replaceFirst(RegExp(r'^[A-D]\. '), ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: isCorrect ? const Color(0xFF43A047) : Colors.grey.shade600,
                            fontWeight: isCorrect ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isCorrect)
                        const Icon(Icons.check, size: 14, color: Color(0xFF43A047)),
                    ],
                  ),
                );
              }),
            // 填空题显示答案
            if (!isChoice)
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  Text(
                    '答案: ${question.answer}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(QuestionModel question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: const Text('确定要删除这道题吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _backendService.removeQuestion(question.id);
              if (!mounted) {
                return;
              }
              navigator.pop();
              await _loadQuestions();
            },
            child: const Text('删除', style: TextStyle(color: Color(0xFFE53935))),
          ),
        ],
      ),
    );
  }
}

/// 题目编辑页面
class QuestionEditPage extends StatefulWidget {
  final QuestionModel? question;

  const QuestionEditPage({
    super.key,
    this.question,
  });

  @override
  State<QuestionEditPage> createState() => _QuestionEditPageState();
}

class _QuestionEditPageState extends State<QuestionEditPage> {
  final LocalBackendService _backendService = LocalBackendService();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String _selectedCategory = '地理';
  QuestionType _questionType = QuestionType.fill;
  final List<TextEditingController> _optionControllers =
      List.generate(4, (_) => TextEditingController());
  String _correctOption = 'A';

  final List<String> _categories = ['地理', '数学', '常识', '科学', '历史', '文学', '英语', '体育', '艺术', '其他'];
  final List<String> _optionLetters = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      final q = widget.question!;
      _questionController.text = q.question;
      _selectedCategory = q.category;
      _questionType = q.type;
      if (q.type == QuestionType.fill) {
        _answerController.text = q.answer;
      } else {
        _correctOption = q.answer;
        final opts = q.options ?? [];
        for (int i = 0; i < opts.length && i < 4; i++) {
          _optionControllers[i].text =
              opts[i].replaceFirst(RegExp(r'^[A-D]\. '), '');
        }
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
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
        title: Text(
          widget.question == null ? '添加题目' : '编辑题目',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveQuestion,
            child: Text(
              '保存',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题型选择
              const Text(
                '题目类型',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeChip(QuestionType.fill, '填空题', Icons.edit_note_outlined),
                  const SizedBox(width: 12),
                  _buildTypeChip(QuestionType.choice, '选择题', Icons.list_alt_outlined),
                ],
              ),
              const SizedBox(height: 24),
              // 问题输入
              const Text(
                '问题',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '请输入问题内容',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 填空题：答案输入
              if (_questionType == QuestionType.fill) ...[
                const Text(
                  '答案',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    hintText: '请输入答案',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                ),
              ],
              // 选择题：选项输入 + 正确答案选择
              if (_questionType == QuestionType.choice) ...[
                const Text(
                  '选项（请填写四个选项，并选择正确答案）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(4, (i) {
                  final letter = _optionLetters[i];
                  final isCorrect = _correctOption == letter;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _correctOption = letter),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF43A047)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isCorrect ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _optionControllers[i],
                            decoration: InputDecoration(
                              hintText: '选项 $letter',
                              filled: true,
                              fillColor: isCorrect
                                  ? const Color(0xFF43A047).withValues(alpha: 0.05)
                                  : Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isCorrect
                                      ? const Color(0xFF43A047)
                                      : const Color(0xFFE0E0E0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: isCorrect
                                      ? const Color(0xFF43A047)
                                      : AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle, color: Color(0xFF43A047), size: 20),
                          ),
                      ],
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '点击左侧字母圆圈设置正确答案',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // 分类选择
              const Text(
                '分类',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFF666666),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(QuestionType type, String label, IconData icon) {
    final isSelected = _questionType == type;
    final color = type == QuestionType.fill
        ? const Color(0xFF5CB85C)
        : const Color(0xFF9B8FD4);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _questionType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写问题内容')),
      );
      return;
    }
    if (_questionType == QuestionType.fill && _answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写答案')),
      );
      return;
    }
    if (_questionType == QuestionType.choice) {
      final emptyOption = _optionControllers.any((c) => c.text.trim().isEmpty);
      if (emptyOption) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写所有选项内容')),
        );
        return;
      }
    }

    final normalizedQuestion = _questionController.text.trim();
    final normalizedCategory = _selectedCategory;
    final answer = _questionType == QuestionType.fill
        ? _answerController.text.trim()
        : _correctOption;
    final options = _questionType == QuestionType.choice
        ? _optionControllers
            .asMap()
            .entries
            .map((entry) => '${_optionLetters[entry.key]}. ${entry.value.text.trim()}')
            .toList(growable: false)
        : null;

    if (widget.question == null) {
      await _backendService.addQuestion(
        question: normalizedQuestion,
        answer: answer,
        category: normalizedCategory,
        type: _questionType,
        options: options,
      );
    } else {
      final updated = widget.question!.copyWith(
        question: normalizedQuestion,
        answer: answer,
        category: normalizedCategory,
        type: _questionType,
        options: options,
        updatedAt: DateTime.now(),
      );
      await _backendService.saveQuestion(updated);
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('题目已保存')),
    );
    Navigator.pop(context);
  }
}
