import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agenda_nusantara.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date TEXT NOT NULL,
        category TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        completed_date TEXT
      )
    ''');
  }

  // INSERT new task
  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await instance.database;
    return await db.insert('tasks', task);
  }

  // GET all tasks
  Future<List<Map<String, dynamic>>> getAllTasks() async {
    final db = await instance.database;
    return await db.query('tasks', orderBy: 'due_date ASC');
  }

  // UPDATE completed status
  Future<int> updateTaskStatus(int id, bool isDone) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {
        'is_done': isDone ? 1 : 0,
        'completed_date': isDone
            ? DateTime.now().toIso8601String().substring(0, 10)
            : null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // UPDATE task fields
  Future<int> updateTask(int id, Map<String, dynamic> values) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE task
  Future<int> deleteTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // COUNT completed tasks
  Future<int> countCompletedTasks() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tasks WHERE is_done = 1');
    return result.first['total'] as int;
  }

  // COUNT incomplete tasks
  Future<int> countIncompleteTasks() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tasks WHERE is_done = 0');
    return result.first['total'] as int;
  }

  // GET completed tasks per day (last 7 days) for chart
  Future<List<Map<String, dynamic>>> getCompletedTasksPerDay() async {
    final db = await instance.database;
    // Get last 7 days
    final List<Map<String, dynamic>> results = [];
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      final count = await db.rawQuery(
        'SELECT COUNT(*) as total FROM tasks WHERE is_done = 1 AND completed_date = ?',
        [dateStr],
      );
      results.add({
        'date': dateStr,
        'total': count.first['total'] as int,
      });
    }
    return results;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}