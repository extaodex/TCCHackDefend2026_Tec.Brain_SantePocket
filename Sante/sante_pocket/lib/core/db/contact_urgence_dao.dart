import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';
import '../../models/contact_urgence.dart';

class ContactUrgenceDao {
  Future<Database> get _db async => await DatabaseHelper.instance.database;

  Future<List<ContactUrgence>> getContacts(int patientId) async {
    final db = await _db;
    final maps = await db.query(
      'contacts_urgence',
      where: 'patient_id = ?',
      whereArgs: [patientId],
    );
    return maps.map((m) => ContactUrgence.fromMap(m)).toList();
  }

  Future<int> insertContact(ContactUrgence contact) async {
    final db = await _db;
    return await db.insert('contacts_urgence', contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteContact(int id) async {
    final db = await _db;
    return await db.delete('contacts_urgence', where: 'id = ?', whereArgs: [id]);
  }
}
