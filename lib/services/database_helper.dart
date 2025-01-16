import 'dart:io';
import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import '../models/question_filter.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static const String DATABASE_NAME = 'questions.db';
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

    Future<String> getDatabasePath() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'questions.db');
    print('Database path: $path'); // This will show you the exact location
    return path;
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
      eAlternative TEXT,
      explanation TEXT,
      correctAnswer TEXT,
      secondAnswer TEXT,
      explanationUrl TEXT,
      answeredRight INTEGER
    )
    ''');
  }

  // You might also want to add this helper method
Future<void> resetDatabase() async {
  final logger = Logger();
  try {
    final db = await instance.database;
    await db.execute('DROP TABLE IF EXISTS questions');
    await _createDB(db, 2);
    logger.i('Successfully reset database');
  } catch (e) {
    logger.e('Error resetting database: $e');
    rethrow;
  }
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
  final logger = Logger();
  
  try {
    logger.i('Starting database population from ${urls.length} URLs');
    
    bool hasExistingQuestions = await instance.hasQuestions();
    if (hasExistingQuestions) {
      logger.i('Database already contains questions, skipping population');
      return;
    }

    int totalQuestions = 0;
    int successfulUrls = 0;
    
    for (String url in urls) {
      try {
        await _processUrl(url);
        successfulUrls++;
      } catch (e) {
        logger.e('Failed to process URL: $url', error: e);
        // Continue with other URLs
      }
    }

    if (successfulUrls == 0) {
      throw ParseException('Failed to process any URLs successfully');
    }

    // Verify database population
    hasExistingQuestions = await instance.hasQuestions();
    if (!hasExistingQuestions) {
      throw ParseException('Database population failed - no questions were inserted');
    }

    logger.i('Successfully populated database from $successfulUrls URLs');
  } catch (e, stackTrace) {
    logger.e('Error in populateDatabaseFromUrls', error: e, stackTrace: stackTrace);
    rethrow;
  }
}



 static Future<void> insertQuestions(List<Question> questions) async {
  try {
    if (questions.isEmpty) {
      _logger.e('Attempted to insert empty questions list');
      return;
    }

    final db = await instance.database;
    Batch batch = db.batch();
    
    for (var question in questions) {
      // Add debug logging for each question being inserted
      _logger.i('Preparing to insert question: ${question.question.substring(0, min(50, question.question.length))}...');
      
      Map<String, dynamic> questionMap = question.toMap();
      _logger.i('Question map created successfully');
      
      batch.insert(
        'questions', 
        questionMap,
        conflictAlgorithm: ConflictAlgorithm.replace
      );
    }
    
    await batch.commit(noResult: true);
    _logger.i('Successfully inserted ${questions.length} questions');
  } catch (e, stackTrace) {
    _logger.e('Error inserting questions', error: e, stackTrace: stackTrace);
    throw ParseException('Failed to insert questions: $e');
  }
}


static List<Question> parseMarkdown(String markdown) {
  List<Question> questions = [];
  final logger = Logger();
  
  try {
    // Updated regex to handle the actual markdown format
    RegExp questionRegex = RegExp(
      r'(\d+)\.\s+(.*?)(?=\s*-\s+[A-E]\.)((?:\s*-\s+[A-E]\.\s+.*?(?=\s*-\s+[A-E]\.|\s*<details|\n\s*\d+\.|$))+).*?<details.*?<summary.*?Answer.*?</summary>\s*Correct answer:\s*([A-E](?:\s*,\s*[A-E])*)',
      multiLine: true,
      dotAll: true,
    );

    RegExp alternativesRegex = RegExp(
      r'-\s+([A-E])\.\s+(.*?)(?=\s*-\s+[A-E]\.|\s*<details|\n\s*\d+\.|$)',
      multiLine: true,
      dotAll: true,
    );

    var matches = questionRegex.allMatches(markdown);
    logger.i('Found ${matches.length} potential questions in markdown');

    for (Match match in matches) {
      try {
        final questionNumber = match.group(1);
        final questionText = match.group(2)?.trim();
        final alternativesText = match.group(3);
        final correctAnswersText = match.group(4)?.trim();

        logger.i('Processing question $questionNumber');
        logger.i('Question text: ${questionText?.substring(0, min(50, questionText?.length ?? 0))}...');
        logger.i('Alternatives text: $alternativesText');
        logger.i('Correct answers: $correctAnswersText');

        if (questionText == null || alternativesText == null || correctAnswersText == null) {
          logger.w('Missing required fields for question $questionNumber');
          continue;
        }

        // Parse alternatives
        Map<String, String> alternatives = {};
        for (Match altMatch in alternativesRegex.allMatches(alternativesText)) {
          final letter = altMatch.group(1);
          final text = altMatch.group(2)?.trim();
          if (letter != null && text != null) {
            alternatives[letter] = text;
            logger.i('Found alternative $letter: $text');
          }
        }

        if (alternatives.isEmpty) {
          logger.w('No alternatives found for question $questionNumber');
          continue;
        }

        // Handle multiple correct answers
        List<String> correctAnswers = correctAnswersText
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        if (correctAnswers.isEmpty) {
          logger.w('No correct answers found for question $questionNumber');
          continue;
        }

        questions.add(Question(
          examType: 'AWS Certified Cloud Practitioner',
          question: questionText,
          aAlternative: alternatives['A'] ?? '',
          bAlternative: alternatives['B'] ?? '',
          cAlternative: alternatives['C'] ?? '',
          dAlternative: alternatives['D'] ?? '',
          eAlternative: alternatives['E'] ?? '',
          correctAnswer: correctAnswers[0],
          secondAnswer: correctAnswers.length > 1 ? correctAnswers[1] : null,
          explanation: '', // Add explanation parsing if needed
        ));

        logger.i('Successfully added question $questionNumber');
      } catch (e, stackTrace) {
        logger.e('Error processing question: $e', stackTrace: stackTrace);
      }
    }
  } catch (e, stackTrace) {
    logger.e('Error parsing markdown: $e', stackTrace: stackTrace);
  }

  logger.i('Successfully parsed ${questions.length} questions');
  return questions;
}



static Future<void> _processUrl(String url) async {
  final logger = Logger();
  try {
    logger.i('Fetching URL: $url');
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode != 200) {
      throw HttpException('Failed to load questions. Status code: ${response.statusCode}');
    }

    String markdown = response.body;
    if (markdown.isEmpty) {
      throw ParseException('Empty markdown content received');
    }

    logger.i('Successfully fetched markdown (${markdown.length} bytes)');
    List<Question> questions = parseMarkdown(markdown);
    
    if (questions.isEmpty) {
      logger.w('No questions parsed from markdown at $url');
      return;
    }
    
    logger.i('Parsed ${questions.length} questions, proceeding to insert');
    await insertQuestions(questions);
    logger.i('Successfully processed URL: $url');
  } catch (e, stackTrace) {
    logger.e('Error processing URL: $url', error: e, stackTrace: stackTrace);
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
