import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../models/patient.dart';
import 'database_helper.dart';

class PatientDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Patient?> getPatient() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query('patients', limit: 1);
    
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertOrUpdatePatient(Patient patient) async {
    Database db = await _dbHelper.database;
    
    // As it's a single patient pocket app, we can just replace or insert id 1
    return await db.insert(
      'patients',
      patient.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
