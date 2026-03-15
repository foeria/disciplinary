import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_button.dart';
import '../../widgets/anime_text_field.dart';

/// 题目编辑页面
class QuestionEditPage extends StatefulWidget {
  final String? questionId;

  const QuestionEditPage({
    super.key,
    this.questionId,
  });

  @override
  State<QuestionEditPage> createState() => _QuestionEditPageState();
}

class _QuestionEditPageState extends State<QuestionEditPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  String _selectedCategory = '常识';

  final List<String> _categories = ['常识', '历史', '地理', '科学', '数学', '其他'];

  bool get _isEditing => widget.questionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // 加载现有题目数据
      _loadQuestion();
    }
  }

  void _loadQuestion() {
    // 模拟加载数据
    _questionController.text = '一年有几个季节？';
    _answerController.text = '4';
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty || _answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写完整题目和答案')),
      );
      return;
    }

    Navigator.pop(context);
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
          _isEditing ? '编辑题目' : '添加题目',
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问题输入
              const Text(
                '问题',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              AnimeCard(
                padding: const EdgeInsets.all(16),
                child: AnimeTextField(
                  controller: _questionController,
                  hintText: '请输入问题内容',
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              // 答案输入
              const Text(
                '答案',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              AnimeCard(
                padding: const EdgeInsets.all(16),
                child: AnimeTextField(
                  controller: _answerController,
                  hintText: '请输入答案',
                ),
              ),
              const SizedBox(height: 20),
              // 分类选择
              const Text(
                '分类',
                style: TextStyle(
                  fontSize: 14,
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
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : const Color(0xFF333333),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: AnimeButton(
                  text: '保存题目',
                  onPressed: _saveQuestion,
                ),
              ),
              const SizedBox(height: 12),
              // 取消按钮
              SizedBox(
                width: double.infinity,
                child: AnimeOutlinedButton(
                  text: '取消',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
