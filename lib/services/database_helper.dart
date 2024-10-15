import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('questions.db');
    return _database!;
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
      questionText TEXT,
      answers TEXT,
      correctAnswerIndex INTEGER,
      isPremium INTEGER
    )
    ''');

    // Here you would insert all your questions
    // await db.insert('questions', Question(...).toMap());
  }

  Future<List<Question>> getQuestions(String examType, {bool isPremium = false}) async {
    final db = await instance.database;
    final result = await db.query(
      'questions',
      where: 'examType = ? AND isPremium <= ?',
      whereArgs: [examType, isPremium ? 1 : 0],
    );
    return result.map((map) => Question.fromMap(map)).toList();
  }
}
