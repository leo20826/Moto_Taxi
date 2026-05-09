import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trip_record.dart';

class TripDatabase {
  static final TripDatabase instance = TripDatabase._init();
  static Database? _database;
  TripDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trips.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        distance REAL NOT NULL,
        durationSeconds INTEGER NOT NULL,
        price REAL NOT NULL
      )
    ''');
  }

  Future<void> insert(TripRecord trip) async {
    final db = await database;
    await db.insert('trips', trip.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TripRecord>> getAll() async {
    final db = await database;
    final result = await db.query('trips', orderBy: 'startTime DESC');
    return result.map((json) => TripRecord.fromMap(json)).toList();
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('trips');
  }
}
