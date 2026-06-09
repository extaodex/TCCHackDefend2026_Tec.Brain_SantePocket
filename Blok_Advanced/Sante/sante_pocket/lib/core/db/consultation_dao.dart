import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../models/consultation.dart';
import '../../models/ordonnance.dart';
import 'database_helper.dart';

class ConsultationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Consultation>> getAllConsultations() async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('consultations', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => Consultation.fromMap(maps[i]));
  }

  Future<Ordonnance?> getOrdonnanceByConsultationId(int consultationId) async {
    Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ordonnances',
      where: 'consultation_id = ?',
      whereArgs: [consultationId],
    );
    if (maps.isNotEmpty) {
      return Ordonnance.fromMap(maps.first);
    }
    return null;
  }

  Future<int> insertConsultation(Consultation consultation) async {
    Database db = await _dbHelper.database;
    return await db.insert('consultations', consultation.toMap());
  }
}
