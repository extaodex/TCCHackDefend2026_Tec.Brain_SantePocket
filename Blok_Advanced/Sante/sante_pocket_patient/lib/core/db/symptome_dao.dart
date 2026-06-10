import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';
import '../../models/symptome.dart';

class SymptomeDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Symptome>> getSymptomes(int patientId) async {
    final db = await _db;
    final maps = await db.query(
      'symptomes',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Symptome.fromMap(m)).toList();
  }

  Future<int> insertSymptome(Symptome symptome) async {
    final db = await _db;
    return await db.insert('symptomes', symptome.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteSymptome(int id) async {
    final db = await _db;
    return await db.delete('symptomes', where: 'id = ?', whereArgs: [id]);
  }
}
