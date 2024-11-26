import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import '../models/question_filter.dart';

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
  try {
    bool hasExistingQuestions = await instance.hasQuestions();
    _logger.i('Checking for existing questions: $hasExistingQuestions');
    
    if (hasExistingQuestions) {
      _logger.i('Database already contains questions, skipping population');
      return;
    }

    for (String url in urls) {
      try {
        _logger.i('Processing URL: $url');
        await _processUrl(url);
        _logger.i('Successfully processed URL: $url');
      } catch (e, stackTrace) {
        _logger.e('Error processing URL: $url', error: e, stackTrace: stackTrace);
      }
    }

    hasExistingQuestions = await instance.hasQuestions();
    _logger.i('Final check for questions: $hasExistingQuestions');
    
    if (!hasExistingQuestions) {
      const message = 'Failed to populate database - no questions were inserted';
      _logger.e(message);
      throw ParseException(message);
    }
  } catch (e, stackTrace) {
    _logger.e('Error in populateDatabaseFromUrls', error: e, stackTrace: stackTrace);
    rethrow;
  }
}


  static Future<void> insertQuestions(List<Question> questions) async {
  try {
    final db = await instance.database;
    Batch batch = db.batch();
    
    for (var question in questions) {
      batch.insert(
        'questions', 
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    
    await batch.commit(noResult: true);
    _logger.i('Successfully inserted ${questions.length} questions');
  } catch (e) {
    _logger.e('Error inserting questions', error: e);
    throw ParseException('Failed to insert questions: $e');
  }
}

  static List<Question> parseMarkdown(String markdown) {
  List<Question> questions = [];
  
  // Debug: Log the first part of the markdown
  _logger.i('First 500 characters of markdown:\n${markdown.substring(0, 500)}');

  RegExp questionRegex = RegExp(
    r'(\d+)\.\s+(.*?)(?=\s*-\s+[A-D]\.)((?:\s*-\s+[A-D]\.\s+.*?\n)+).*?<details.*?>\s*<summary.*?>Answer</summary>\s*Correct answer:\s*([A-D])',
    multiLine: true,
    dotAll: true,
  );

  RegExp alternativesRegex = RegExp(r'-\s+([A-D])\.\s+(.*?)(?=\s*-\s+[A-D]\.|\s*<details|$)', 
    multiLine: true,
    dotAll: true,
  );

  // Debug: Log all matches
  var matches = questionRegex.allMatches(markdown).toList();
  _logger.i('Found ${matches.length} question matches');

  for (Match match in matches) {
    try {
      final questionNumber = match.group(1);
      final questionText = match.group(2)?.trim();
      final alternativesText = match.group(3);
      final correctAnswer = match.group(4)?.trim();
      
      // Debug: Log each question parsing attempt
      _logger.i('Parsing question $questionNumber');
      _logger.i('Question text: $questionText');
      _logger.i('Alternatives text: $alternativesText');
      _logger.i('Correct answer: $correctAnswer');

      if (questionText == null || correctAnswer == null || alternativesText == null) {
        _logger.w('Invalid question format for question $questionNumber');
        continue;
      }

  
      // Extract alternatives
      Map<String, String> alternatives = {};
      for (Match altMatch in alternativesRegex.allMatches(alternativesText)) {
        final letter = altMatch.group(1);
        final text = altMatch.group(2)?.trim();
        if (letter != null && text != null) {
          alternatives[letter] = text;
          _logger.i('Found alternative $letter: $text');
        }
      }

      if (alternatives.isEmpty) {
        _logger.w('No alternatives found for question $questionNumber');
        continue;
      }

      questions.add(Question(
        examType: 'AWS Certified Cloud Practitioner',
        question: questionText,
        aAlternative: alternatives['A'] ?? '',
        bAlternative: alternatives['B'] ?? '',
        cAlternative: alternatives['C'],
        dAlternative: alternatives['D'],
        correctAnswer: correctAnswer,
        explanation: '', // We can add explanation parsing if needed
      ));

      _logger.i('Successfully parsed question $questionNumber');
    } catch (e, stackTrace) {
      _logger.e('Failed to parse question', error: e, stackTrace: stackTrace);
    }
  }

  _logger.i('Total questions parsed: ${questions.length}');
  return questions;
}


static Future<void> _processUrl(String url) async {
  try {
    _logger.i('Fetching URL: $url');
    final response = await http.get(Uri.parse(url));
    
    _logger.i('Response status code: ${response.statusCode}');
    if (response.statusCode == 200) {
      String markdown = response.body;
      _logger.i('Markdown content length: ${markdown.length}');
      
      List<Question> questions = parseMarkdown(markdown);
      
      if (questions.isEmpty) {
        _logger.e('No questions parsed from markdown');
        throw ParseException('No questions parsed from markdown');
      }
      
      _logger.i('Parsed ${questions.length} questions, proceeding to insert');
      await insertQuestions(questions);
      _logger.i('Successfully inserted questions');
    } else {
      throw HttpException(
          'Failed to load questions. Status code: ${response.statusCode}');
    }
  } catch (e, stackTrace) {
    _logger.e('Error in _processUrl', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

static Future<void> printDatabaseLocation() async {
  try {
    // Get the database path
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'questions.db');
    print('\n--- Database Location Info ---');
    print('Full database path: $path');
    
    // Check if file exists
    bool exists = await File(path).exists();
    print('Database file exists: $exists');
    
    // Get all app directories
    final appDocDir = await getApplicationDocumentsDirectory();
    final appSupportDir = await getApplicationSupportDirectory();
    final tempDir = await getTemporaryDirectory();
    
    print('\nAll relevant directories:');
    print('Documents Directory: ${appDocDir.path}');
    print('Support Directory: ${appSupportDir.path}');
    print('Temporary Directory: ${tempDir.path}');
    
    // For the actual database directory
    Directory dbDir = Directory(dbPath);
    if (await dbDir.exists()) {
      print('\nDatabase directory contents:');
      await for (var entity in dbDir.list()) {
        print('- ${entity.path}');
      }
    }
    
    print('\nParent directory contents:');
    await for (var entity in dbDir.parent.list()) {
      print('- ${entity.path}');
    }
    
    print('------------------------\n');
  } catch (e) {
    print('Error while getting database location: $e');
  }
}


Future<List<Question>> getFilteredQuestions(String examType, QuestionFilter filter) async {
  final db = await instance.database;
  String whereClause;
  List<dynamic> whereArgs;

  switch (filter) {
    case QuestionFilter.unanswered:
      whereClause = 'examType = ? AND answeredRight IS NULL';
      whereArgs = [examType];
      break;
    case QuestionFilter.all:
      whereClause = 'examType = ?';
      whereArgs = [examType];
      break;
    case QuestionFilter.answeredCorrect:
      whereClause = 'examType = ? AND answeredRight = 1';
      whereArgs = [examType];
      break;
    case QuestionFilter.answeredIncorrect:
      whereClause = 'examType = ? AND answeredRight = 0';
      whereArgs = [examType];
      break;
    case QuestionFilter.answered:
      whereClause = 'examType = ? AND answeredRight IS NOT NULL';
      whereArgs = [examType];
      break;
  }

  final result = await db.query(
    'questions',
    where: whereClause,
    whereArgs: whereArgs,
  );

  print("Found ${result.length} questions for $examType with filter ${filter.name}");
  return result.map((map) => Question.fromMap(map)).toList();
}

Future<Map<String, int>> getQuestionStats(String examType) async {
  final db = await instance.database;
  
  final total = Sqflite.firstIntValue(await db.rawQuery(
    'SELECT COUNT(*) FROM questions WHERE examType = ?',
    [examType]
  )) ?? 0;
  
  final answered = Sqflite.firstIntValue(await db.rawQuery(
    'SELECT COUNT(*) FROM questions WHERE examType = ? AND answeredRight IS NOT NULL',
    [examType]
  )) ?? 0;
  
  final correct = Sqflite.firstIntValue(await db.rawQuery(
    'SELECT COUNT(*) FROM questions WHERE examType = ? AND answeredRight = 1',
    [examType]
  )) ?? 0;

  return {
    'total': total,
    'answered': answered,
    'correct': correct,
    'incorrect': answered - correct,
    'unanswered': total - answered,
  };
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
