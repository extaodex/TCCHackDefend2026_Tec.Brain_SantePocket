import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';
import '../../models/examen_analyse.dart';

class ExamenDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<ExamenAnalyse>> getExamens(int patientId) async {
    final db = await _db;
    final maps = await db.query(
      'examens_analyses',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    return maps.map((m) => ExamenAnalyse.fromMap(m)).toList();
  }

  Future<int> insertExamen(ExamenAnalyse examen) async {
    final db = await _db;
    return await db.insert('examens_analyses', examen.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteExamen(int id) async {
    final db = await _db;
    return await db.delete('examens_analyses', where: 'id = ?', whereArgs: [id]);
  }
}
