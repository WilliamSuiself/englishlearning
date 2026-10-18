import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/word.dart';
import '../models/quiz_question.dart';
import '../models/study_record.dart';
import '../models/wrong_word.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'english_learning.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            phonetic_us TEXT,
            phonetic_uk TEXT,
            definition TEXT NOT NULL,
            definition_en TEXT,
            part_of_speech TEXT,
            level TEXT,
            exchange TEXT,
            tag TEXT,
            collins INTEGER DEFAULT 0,
            oxford INTEGER DEFAULT 0,
            frequency INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE word_examples (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word_id INTEGER NOT NULL,
            example TEXT NOT NULL,
            translation TEXT,
            FOREIGN KEY (word_id) REFERENCES words(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE quiz_questions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            question TEXT NOT NULL,
            options TEXT NOT NULL,
            correct_index INTEGER NOT NULL,
            explanation TEXT,
            difficulty TEXT,
            category TEXT,
            audio_url TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE study_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            skill TEXT NOT NULL,
            exercise_type TEXT NOT NULL,
            total_questions INTEGER NOT NULL,
            correct_count INTEGER NOT NULL,
            duration_seconds INTEGER NOT NULL,
            studied_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE wrong_words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL,
            definition TEXT,
            skill TEXT NOT NULL,
            wrong_count INTEGER DEFAULT 1,
            created_at TEXT NOT NULL,
            last_reviewed_at TEXT,
            review_stage INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE favorite_words (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            word TEXT NOT NULL UNIQUE,
            added_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE words ADD COLUMN definition_en TEXT');
          await db.execute('ALTER TABLE words ADD COLUMN exchange TEXT');
          await db.execute('ALTER TABLE words ADD COLUMN tag TEXT');
          await db.execute('ALTER TABLE words ADD COLUMN collins INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE words ADD COLUMN oxford INTEGER DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE word_examples ADD COLUMN translation TEXT');
        }
      },
    );
  }

  // === Word operations ===

  static Future<int> insertWord(Word word) async {
    final db = await database;
    return await db.insert('words', word.toDbMap());
  }

  static Future<void> insertWords(List<Word> words) async {
    final db = await database;
    final batch = db.batch();
    for (final word in words) {
      batch.insert('words', word.toDbMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Word>> getWords({String? level, int? limit, int offset = 0}) async {
    final db = await database;
    List<dynamic> args = [];
    String where = '';
    if (level != null) {
      where = 'level = ?';
      args.add(level);
    }
    final maps = await db.query(
      'words',
      where: where.isNotEmpty ? where : null,
      whereArgs: args.isNotEmpty ? args : null,
      limit: limit,
      offset: offset,
      orderBy: 'frequency DESC',
    );
    return maps.map(Word.fromDbMap).toList();
  }

  static Future<List<Word>> getRandomWords({String? level, int limit = 20}) async {
    final db = await database;
    List<dynamic> args = [];
    String where = '';
    if (level != null) {
      where = 'level = ?';
      args.add(level);
    }
    final maps = await db.rawQuery(
      'SELECT * FROM words ${where.isNotEmpty ? 'WHERE $where' : ''} ORDER BY RANDOM() LIMIT ?',
      [...args, limit],
    );
    return maps.map(Word.fromDbMap).toList();
  }

  static Future<List<Word>> searchWords(String query) async {
    final db = await database;
    final maps = await db.query(
      'words',
      where: 'word LIKE ?',
      whereArgs: ['$query%'],
      limit: 50,
    );
    return maps.map(Word.fromDbMap).toList();
  }

  static Future<int> getWordCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM words');
    return result.first['count'] as int;
  }

  // === Word examples ===

  static Future<void> insertWordExamplesBatch(
      List<Map<String, dynamic>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (final row in rows) {
      batch.insert('word_examples', row);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getExamplesForWord(
      int wordId) async {
    final db = await database;
    return await db.query(
      'word_examples',
      where: 'word_id = ?',
      whereArgs: [wordId],
    );
  }

  static Future<int> getExampleCount() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM word_examples');
    return result.first['count'] as int;
  }

  static Future<List<Map<String, dynamic>>> getRandomExamples(
      {int limit = 100}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT we.example, we.translation, w.word
      FROM word_examples we
      JOIN words w ON we.word_id = w.id
      ORDER BY RANDOM()
      LIMIT ?
    ''', [limit]);
  }

  // === Favorite words ===

  static Future<void> addFavoriteWord(String word) async {
    final db = await database;
    await db.insert('favorite_words', {
      'word': word,
      'added_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> removeFavoriteWord(String word) async {
    final db = await database;
    await db.delete('favorite_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<List<String>> getFavoriteWords() async {
    final db = await database;
    final maps = await db.query('favorite_words', orderBy: 'added_at DESC');
    return maps.map((m) => m['word'] as String).toList();
  }

  static Future<bool> isFavorite(String word) async {
    final db = await database;
    final maps = await db.query(
      'favorite_words',
      where: 'word = ?',
      whereArgs: [word],
    );
    return maps.isNotEmpty;
  }

  // === Quiz operations ===

  static Future<int> insertQuizQuestion(QuizQuestion q) async {
    final db = await database;
    return await db.insert('quiz_questions', q.toDbMap());
  }

  static Future<void> insertQuizQuestions(List<QuizQuestion> questions) async {
    final db = await database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('quiz_questions', q.toDbMap());
    }
    await batch.commit(noResult: true);
  }

  static Future<int> getQuizCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM quiz_questions');
    return result.first['count'] as int;
  }

  static Future<List<String>> getQuizCategories() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT category FROM quiz_questions WHERE category IS NOT NULL');
    return result.map((row) => row['category'] as String).toList();
  }

  static Future<List<QuizQuestion>> getQuizQuestions({
    String? type,
    String? category,
    String? difficulty,
    int? limit,
  }) async {
    final db = await database;
    List<dynamic> args = [];
    List<String> conditions = [];
    if (type != null) {
      conditions.add('type = ?');
      args.add(type);
    }
    if (category != null) {
      conditions.add('category = ?');
      args.add(category);
    }
    if (difficulty != null) {
      conditions.add('difficulty = ?');
      args.add(difficulty);
    }
    final maps = await db.query(
      'quiz_questions',
      where: conditions.isNotEmpty ? conditions.join(' AND ') : null,
      whereArgs: args.isNotEmpty ? args : null,
      limit: limit,
    );
    return maps.map(QuizQuestion.fromDbMap).toList();
  }

  // === Study records ===

  static Future<int> insertStudyRecord(StudyRecord record) async {
    final db = await database;
    return await db.insert('study_records', record.toDbMap());
  }

  static Future<List<StudyRecord>> getStudyRecords({int? days}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (days != null) {
      final since = DateTime.now().subtract(Duration(days: days));
      where = 'studied_at >= ?';
      args = [since.toIso8601String()];
    }
    final maps = await db.query(
      'study_records',
      where: where,
      whereArgs: args,
      orderBy: 'studied_at DESC',
    );
    return maps.map(StudyRecord.fromDbMap).toList();
  }

  // === Wrong words ===

  static Future<int> insertWrongWord(WrongWord ww) async {
    final db = await database;
    return await db.insert('wrong_words', ww.toDbMap());
  }

  static Future<void> incrementWrongCount(String word, String skill) async {
    final db = await database;
    final existing = await db.query(
      'wrong_words',
      where: 'word = ? AND skill = ?',
      whereArgs: [word, skill],
    );
    if (existing.isNotEmpty) {
      await db.update(
        'wrong_words',
        {'wrong_count': (existing.first['wrong_count'] as int) + 1},
        where: 'word = ? AND skill = ?',
        whereArgs: [word, skill],
      );
    } else {
      await db.insert('wrong_words', WrongWord(
        word: word,
        skill: skill,
        createdAt: DateTime.now(),
      ).toDbMap());
    }
  }

  static Future<List<WrongWord>> getWrongWords({String? skill, int? limit}) async {
    final db = await database;
    String? where;
    List<dynamic>? args;
    if (skill != null) {
      where = 'skill = ?';
      args = [skill];
    }
    final maps = await db.query(
      'wrong_words',
      where: where,
      whereArgs: args,
      orderBy: 'wrong_count DESC',
      limit: limit,
    );
    return maps.map(WrongWord.fromDbMap).toList();
  }

  static Future<void> removeWrongWord(int id) async {
    final db = await database;
    await db.delete('wrong_words', where: 'id = ?', whereArgs: [id]);
  }

  // === Stats ===

  static Future<Map<String, int>> getSkillStats() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT skill, COUNT(*) as count, SUM(correct_count) as correct, SUM(total_questions) as total
      FROM study_records
      GROUP BY skill
    ''');
    Map<String, int> stats = {};
    for (final row in result) {
      stats[row['skill'] as String] = row['count'] as int;
    }
    return stats;
  }

  static Future<int> getTodayStudyCount() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM study_records WHERE studied_at >= ?',
      [startOfDay.toIso8601String()],
    );
    return result.first['count'] as int;
  }

  static Future<int> getStreakDays() async {
    final db = await database;
    final records = await db.rawQuery(
      'SELECT DISTINCT DATE(studied_at) as day FROM study_records ORDER BY day DESC',
    );
    if (records.isEmpty) return 0;

    final days = records.map((r) => r['day'] as String).toSet();
    int streak = 0;
    var checkDate = DateTime.now();
    // If no study today, start from yesterday
    final todayStr = _dateKey(DateTime.now());
    if (!days.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    while (days.contains(_dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static Future<Map<String, int>> getDailyCounts({int days = 90}) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days));
    final result = await db.rawQuery(
      'SELECT DATE(studied_at) as day, COUNT(*) as count FROM study_records WHERE studied_at >= ? GROUP BY day ORDER BY day',
      [since.toIso8601String()],
    );
    return {for (final row in result) row['day'] as String: row['count'] as int};
  }

  static Future<int> getTotalStudyDays() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT DATE(studied_at)) as count FROM study_records',
    );
    return result.first['count'] as int;
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('words');
    await db.delete('word_examples');
    await db.delete('quiz_questions');
    await db.delete('study_records');
    await db.delete('wrong_words');
    await db.delete('favorite_words');
  }

  static String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
