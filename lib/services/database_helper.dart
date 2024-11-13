import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final Logger _logger = Logger();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('questions.db');
    return _database!;
  }

  Future<List<Question>> getUnansweredQuestions(String examType) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'examType = ? AND answeredRight IS NULL',
      whereArgs: [examType],
    );
    print("Found ${result.length} unanswered questions for $examType");
    return result.map((map) => Question.fromMap(map)).toList();
  }

  Future<bool> hasQuestions() async {
    final db = await instance.database;
    final result = await db.query('questions', limit: 1);
    return result.isNotEmpty;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE questions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      examType TEXT,
      question TEXT,
      aAlternative TEXT,
      bAlternative TEXT,
      cAlternative TEXT,
      dAlternative TEXT,
      explanation TEXT,
      correctAnswer TEXT,
      explanationUrl TEXT,
      answeredRight INTEGER
    )
    ''');
  }

  Future<int> insertQuestion(Question question) async {
    final db = await instance.database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestions(String examType) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'examType = ?',
      whereArgs: [examType],
    );
    return result.map((map) => Question.fromMap(map)).toList();
  }

  Future<void> updateQuestionAnswer(int? id, bool answeredRight) async {
    if (id == null || id <= 0) return;
    final db = await instance.database;
    await db.update(
      'questions',
      {'answeredRight': answeredRight ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  //--

  static Future<void> populateDatabaseFromUrls(List<String> urls) async {
    for (String url in urls) {
      try {
        await _processUrl(url);
        print("Processed and inserted questions from $url");
      } catch (e) {
        _logger.e('Error processing URL: $url', error: e);
      }
    }
  }

  static Future<void> insertQuestions(List<Question> questions) async {
    final db = await instance.database;
    Batch batch = db.batch();
    _logger.e(questions);
    for (var question in questions) {
      _logger.e(question);
      batch.insert('questions', question.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static List<Question> parseMarkdown(String markdown) {
    List<Question> questions = [];
    RegExp questionRegex = RegExp(
      r'(\d+)\.\s(.+?)\n\n(?:- ([A-D])\.\s(.+?)\n)+\n(Answer:\s([A-D]))?\n\nExplanation:\s*(.*?)(?=\n\n\d+\.|\Z)',
      multiLine: true,
      dotAll: true,
    );

    for (Match match in questionRegex.allMatches(markdown)) {
      try {
        String questionText = match.group(2)!.trim();
        List<String> alternatives = [];
        RegExp optionRegex = RegExp(r'- ([A-D])\.\s(.+?)$');
        for (var i = 0; i < 4; i++) {
          String? altText = match.group(i + 4)?.trim();
          if (altText != null) alternatives.add(altText);
        }

        String correctAnswer = match.group(6) ?? '';
        String explanation = match.group(7)?.trim() ?? '';

        questions.add(Question(
          examType: 'AWS Certified Cloud Practitioner',
          question: questionText,
          aAlternative: alternatives.isNotEmpty ? alternatives[0] : '',
          bAlternative: alternatives.length > 1 ? alternatives[1] : '',
          cAlternative: alternatives.length > 2 ? alternatives[2] : '',
          dAlternative: alternatives.length > 3 ? alternatives[3] : '',
          correctAnswer: correctAnswer,
          explanation: explanation,
        ));
      } catch (e) {
        _logger.w('Failed to parse question', error: e);
      }
    }

    return questions;
  }

  static Future<void> _processUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      //_logger.w(response.statusCode);
      if (response.statusCode == 200) {
        String markdown = response.body;
        //_logger.w(response.body);
        List<Question> questions = parseMarkdown(markdown);
        //_logger.w(questions);
        await insertQuestions(questions);
      } else {
        throw HttpException(
            'Failed to load questions. Status code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error occurred: ${e.message}');
    } catch (e) {
      throw ParseException('Error parsing questions: $e');
    }
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ParseException implements Exception {
  final String message;
  ParseException(this.message);
}
