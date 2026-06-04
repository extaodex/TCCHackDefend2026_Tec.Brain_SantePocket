import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';
import '../../models/vaccination.dart';

class VaccinationDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Vaccination>> getVaccinations(int patientId) async {
    final db = await _db;
    final maps = await db.query(
      'vaccinations',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => Vaccination.fromMap(m)).toList();
  }

  Future<int> insertVaccination(Vaccination vaccination) async {
    final db = await _db;
    return await db.insert('vaccinations', vaccination.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteVaccination(int id) async {
    final db = await _db;
    return await db.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
  }
}
