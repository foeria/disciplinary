/// questions 表 — 题库
///
/// 字段说明：
///   id        TEXT PRIMARY KEY   — UUID 字符串
///   question  TEXT               — 题目内容
///   answer    TEXT               — 答案；填空题为文本，选择题为正确选项字母(A/B/C/D)
///   category  TEXT DEFAULT '常识' — 题目分类（地理/数学/科学/常识等）
///   type      TEXT DEFAULT 'fill' — 题目类型：fill（填空）或 choice（选择）
///   options   TEXT               — 选择题选项 JSON 数组，示例：
///                                  '["A. 五星","B. 土星","C. 水星","D. 冠军座"]'
///                                  填空题此字段为 NULL
///   created_at TEXT              — 创建时间 ISO-8601
///   updated_at TEXT              — 最后修改时间 ISO-8601
class QuestionsTable {
  static const String tableName = 'questions';

  static const String columnId = 'id';
  static const String columnQuestion = 'question';
  static const String columnAnswer = 'answer';
  static const String columnCategory = 'category';
  static const String columnType = 'type';
  static const String columnOptions = 'options';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  // type 字段合法值
  static const String typeFill = 'fill';
  static const String typeChoice = 'choice';

  static const String createSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnQuestion TEXT NOT NULL,
      $columnAnswer TEXT NOT NULL,
      $columnCategory TEXT NOT NULL DEFAULT '常识',
      $columnType TEXT NOT NULL DEFAULT '$typeFill',
      $columnOptions TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL
    )
  ''';

  static const String createIndexCategory = '''
    CREATE INDEX idx_questions_category ON $tableName ($columnCategory)
  ''';

  static const String createIndexType = '''
    CREATE INDEX idx_questions_type ON $tableName ($columnType)
  ''';
}
