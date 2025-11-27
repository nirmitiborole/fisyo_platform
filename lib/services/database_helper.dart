import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('patients.db');
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
      CREATE TABLE patients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        gender TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<String> insertPatient(Map<String, dynamic> patient) async {
    final db = await database;
    await db.insert('patients', patient);
    return patient['id'];
  }

  Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    return await db.query('patients', orderBy: 'createdAt DESC');
  }

  Future<int> deletePatient(String id) async {
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
