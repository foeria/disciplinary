import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../database/tables/questions_table.dart';
import '../models/question_model.dart';

/// 题库数据仓库。
class QuestionRepository {
  QuestionRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;
  final Uuid _uuid = const Uuid();

  Future<List<QuestionModel>> getQuestions({
    QuestionType? type,
    String? category,
  }) async {
    final filters = <String>[];
    final args = <dynamic>[];

    if (type != null) {
      filters.add('${QuestionsTable.columnType} = ?');
      args.add(_typeToString(type));
    }
    if (category != null && category.isNotEmpty && category != '全部') {
      filters.add('${QuestionsTable.columnCategory} = ?');
      args.add(category);
    }

    final where = filters.isEmpty ? null : filters.join(' AND ');
    final rows = await _databaseHelper.queryByCondition(
      QuestionsTable.tableName,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: '${QuestionsTable.columnUpdatedAt} DESC',
    );

    return rows.map(QuestionModel.fromMap).toList(growable: false);
  }

  Future<QuestionModel?> getQuestionById(String id) async {
    final row = await _databaseHelper.queryById(QuestionsTable.tableName, id);
    if (row == null) {
      return null;
    }
    return QuestionModel.fromMap(row);
  }

  Future<QuestionModel> createQuestion({
    required String question,
    required String answer,
    required String category,
    QuestionType type = QuestionType.fill,
    List<String>? options,
  }) async {
    final now = DateTime.now();
    final model = QuestionModel(
      id: _uuid.v4(),
      question: question,
      answer: answer,
      category: category,
      type: type,
      options: options,
      createdAt: now,
      updatedAt: now,
    );
    await saveQuestion(model);
    return model;
  }

  Future<void> saveQuestion(QuestionModel question) async {
    final existing = await getQuestionById(question.id);
    if (existing == null) {
      await _databaseHelper.insert(QuestionsTable.tableName, question.toMap());
      return;
    }

    await _databaseHelper.update(
      QuestionsTable.tableName,
      question.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${QuestionsTable.columnId} = ?',
      whereArgs: [question.id],
    );
  }

  Future<void> removeQuestion(String id) async {
    await _databaseHelper.delete(
      QuestionsTable.tableName,
      where: '${QuestionsTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<List<QuestionModel>> getRandomUnlockQuestions({
    int count = 3,
  }) async {
    final db = await _databaseHelper.database;
    final rows = await db.rawQuery(
      'SELECT * FROM ${QuestionsTable.tableName} ORDER BY RANDOM() LIMIT ?',
      [count],
    );
    return rows.map(QuestionModel.fromMap).toList(growable: false);
  }

  String _typeToString(QuestionType type) {
    return type == QuestionType.choice
        ? QuestionsTable.typeChoice
        : QuestionsTable.typeFill;
  }
}
