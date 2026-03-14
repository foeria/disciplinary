import 'dart:convert';

/// 题目类型
enum QuestionType {
  fill,   // 填空题
  choice, // 选择题
}

/// 题库问题数据模型
class QuestionModel {
  final String id;
  final String question;
  final String answer;
  final String category;
  final QuestionType type;
  final List<String>? options;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.type = QuestionType.fill,
    this.options,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'fill';
    final optionsJson = map['options'] as String?;
    return QuestionModel(
      id: map['id'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      category: map['category'] as String,
      type: typeStr == 'choice' ? QuestionType.choice : QuestionType.fill,
      options: optionsJson != null
          ? List<String>.from(jsonDecode(optionsJson) as List)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'type': type == QuestionType.choice ? 'choice' : 'fill',
      'options': options != null ? jsonEncode(options) : null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  QuestionModel copyWith({
    String? id,
    String? question,
    String? answer,
    String? category,
    QuestionType? type,
    List<String>? options,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      type: type ?? this.type,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
