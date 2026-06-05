import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class DatabaseService {
  static Database? _db;
  static const String _dbName = 'sante_pro.db';
  static const String _pass = 'sante-pocket-secure-pass-2026'; // À améliorer avec un système de clé plus robuste

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);

    return await openDatabase(
      path,
      version: 1,
      password: _pass,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE patients (
            id TEXT PRIMARY KEY,
            nom TEXT,
            prenom TEXT,
            dob TEXT,
            groupe_sanguin TEXT,
            data TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  static Future<void> savePatient(Map<String, dynamic> record) async {
    final db = await database;
    final id = '${record['nom']}_${record['prenom']}_${record['dob']}'.replaceAll(' ', '_');
    
    await db.insert(
      'patients',
      {
        'id': id,
        'nom': record['nom'],
        'prenom': record['prenom'],
        'dob': record['dob'],
        'groupe_sanguin': record['groupeSanguin'],
        'data': jsonEncode(record),
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('patients', orderBy: 'created_at DESC');
    
    return List.generate(maps.length, (i) {
      final patientData = jsonDecode(maps[i]['data']) as Map<String, dynamic>;
      patientData['db_id'] = maps[i]['id']; // Ensure ID is available for deletion
      return patientData;
    });
  }

  static Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getPatientCountToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM patients WHERE created_at LIKE ?', ['$today%']);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalPatientCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM patients');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> saveDoctorProfile(String name, String specialty) async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS profile (id INTEGER PRIMARY KEY, name TEXT, specialty TEXT)');
    await db.insert('profile', {'id': 1, 'name': name, 'specialty': specialty}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, String>> getDoctorProfile() async {
    final db = await database;
    await db.execute('CREATE TABLE IF NOT EXISTS profile (id INTEGER PRIMARY KEY, name TEXT, specialty TEXT)');
    final List<Map<String, dynamic>> maps = await db.query('profile', where: 'id = 1');
    if (maps.isEmpty) return {'name': 'Dr. Dupont', 'specialty': 'Généraliste'};
    return {'name': maps[0]['name']?.toString() ?? 'Dr. Dupont', 'specialty': maps[0]['specialty']?.toString() ?? 'Généraliste'};
  }
}
