import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';

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
      return jsonDecode(maps[i]['data']);
    });
  }

  static Future<void> deletePatient(String id) async {
    final db = await database;
    await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }
}
