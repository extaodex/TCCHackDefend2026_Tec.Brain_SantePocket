import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../db/database_helper.dart';

class MshParserService {
  static Future<void> importMsh(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    ArchiveFile? jsonFile;
    for (final file in archive) {
      if (file.name == 'dossier_clinique.json') {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) return;

    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final dossier = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    final db = await DatabaseHelper.instance.database;

    // Mise à jour des consultations (retour du médecin)
    final consultations = dossier['consultations'] as List<dynamic>? ?? [];
    for (var consult in consultations) {
      if (consult is Map<String, dynamic>) {
        // On insère ou met à jour. Ici on insère les nouvelles notes.
        await db.insert(
          'consultations', 
          Map<String, dynamic>.from(consult)..remove('id'), // On laisse l'auto-increment gérer l'ID local
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    
    // On pourrait aussi importer d'autres données si nécessaire.
  }
}
