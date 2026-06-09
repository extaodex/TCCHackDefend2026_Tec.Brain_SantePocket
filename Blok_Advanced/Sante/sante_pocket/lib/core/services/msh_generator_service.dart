import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../db/database_helper.dart';

class MshGeneratorService {
  static Future<String> generateMsh() async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Collecter les données de la base
    final patients = await db.query('patients');
    final consultations = await db.query('consultations');
    final examens = await db.query('examens_analyses');
    final vaccinations = await db.query('vaccinations');
    final contacts = await db.query('contacts_urgence');
    final allergies = await db.query('allergies');
    final symptomes = await db.query('symptomes');

    final dossier = {
      'patients': patients,
      'consultations': consultations,
      'examens': examens,
      'vaccinations': vaccinations,
      'contacts_urgence': contacts,
      'allergies': allergies,
      'symptomes': symptomes,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 2. Créer l'archive
    final archive = Archive();

    // JSON
    final jsonStr = const JsonEncoder.withIndent('  ').convert(dossier);
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('dossier_clinique.json', jsonBytes.length, jsonBytes));

    // Photo de profil
    if (patients.isNotEmpty) {
      final photoPath = patients.first['image_profil_path'] as String?;
      if (photoPath != null && photoPath.isNotEmpty) {
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          final bytes = await photoFile.readAsBytes();
          archive.addFile(ArchiveFile('profile/${p.basename(photoPath)}', bytes.length, bytes));
        }
      }
    }

    // Examens (PDFs)
    for (var examen in examens) {
      final pdfPath = examen['resultat_pdf_path'] as String?;
      if (pdfPath != null && pdfPath.isNotEmpty) {
        final pdfFile = File(pdfPath);
        if (await pdfFile.exists()) {
          final bytes = await pdfFile.readAsBytes();
          archive.addFile(ArchiveFile('documents/${p.basename(pdfPath)}', bytes.length, bytes));
        }
      }
    }

    // 3. Encoder ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Erreur de compression ZIP');

    final tempDir = await getTemporaryDirectory();
    final mshPath = p.join(tempDir.path, 'export_patient_${DateTime.now().millisecondsSinceEpoch}.msh');
    await File(mshPath).writeAsBytes(zipBytes);

    return mshPath;
  }
}
