import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';
import '../../models/allergie.dart';

class AllergieDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<Allergie>> getAllergies(int patientId) async {
    final db = await _db;
    final maps = await db.query(
      'allergies',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    return maps.map((m) => Allergie.fromMap(m)).toList();
  }

  Future<int> insertAllergie(Allergie allergie) async {
    final db = await _db;
    return await db.insert('allergies', allergie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteAllergie(int id) async {
    final db = await _db;
    return await db.delete('allergies', where: 'id = ?', whereArgs: [id]);
  }
}
