import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../core/db/database_helper.dart';

/// Service de génération et d'importation du fichier d'export .msh (Santé Pocket Health archive)
class SyncService {
  static Future<String> generateMshArchive() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Extraire toutes les données des tables
    final patients = await db.query('patients');
    final consultations = await db.query('consultations');
    final ordonnances = await db.query('ordonnances');
    final examens = await db.query('examens_analyses');
    final vaccinations = await db.query('vaccinations');
    final contactsUrgence = await db.query('contacts_urgence');
    final allergies = await db.query('allergies');
    final symptomes = await db.query('symptomes');

    // 2. Créer le dossier clinique JSON
    final dossierClinique = {
      'version': '1.1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'patients': patients,
      'consultations': consultations,
      'ordonnances': ordonnances,
      'examens_analyses': examens,
      'vaccinations': vaccinations,
      'contacts_urgence': contactsUrgence,
      'allergies': allergies,
      'symptomes': symptomes,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(dossierClinique);

    // 3. Construire l'archive ZIP
    final archive = Archive();

    // Ajouter le JSON clinique
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile(
      'dossier_clinique.json',
      jsonBytes.length,
      jsonBytes,
    ));

    // 4. Ajouter les PDFs numérisés
    for (final examen in examens) {
      final pdfPath = examen['resultat_pdf_path'] as String?;
      if (pdfPath != null && pdfPath.isNotEmpty) {
        final pdfFile = File(pdfPath);
        if (await pdfFile.exists()) {
          final pdfBytes = await pdfFile.readAsBytes();
          archive.addFile(ArchiveFile(
            'documents/${p.basename(pdfPath)}',
            pdfBytes.length,
            pdfBytes,
          ));
        }
      }
    }

    // 5. Ajouter la photo de profil si elle existe
    if (patients.isNotEmpty) {
      final imgPath = patients.first['image_profil_path'] as String?;
      if (imgPath != null && imgPath.isNotEmpty) {
        final imgFile = File(imgPath);
        if (await imgFile.exists()) {
          final imgBytes = await imgFile.readAsBytes();
          archive.addFile(ArchiveFile(
            'profile/${p.basename(imgPath)}',
            imgBytes.length,
            imgBytes,
          ));
        }
      }
    }

    // 6. Encoder en ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Erreur de compression ZIP');

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mshPath = p.join(dir.path, 'memosante_$timestamp.msh');
    final mshFile = File(mshPath);
    await mshFile.writeAsBytes(zipBytes);

    return mshPath;
  }

  /// Importe un dossier médical complet depuis un fichier .msh
  /// Cette fonction écrase les données existantes par celles du fichier (utilisé après retour du médecin)
  static Future<void> importMshArchive(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? jsonFile;
    for (final file in archive) {
      if (file.name == 'dossier_clinique.json') {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) throw Exception('Fichier dossier_clinique.json introuvable');

    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final db = await DatabaseHelper.instance.database;
    final appDir = await getApplicationDocumentsDirectory();

    await db.transaction((txn) async {
      // 1. Mise à jour du profil patient (Table 'patients')
      final List patients = data['patients'] ?? [];
      if (patients.isNotEmpty) {
        final patientMap = Map<String, dynamic>.from(patients.first);

        // Gérer la photo de profil si présente dans l'archive
        final profileFile = archive.files.firstWhere(
          (f) => f.name.startsWith('profile/'),
          orElse: () => ArchiveFile('', 0, null)
        );
        if (profileFile.name.isNotEmpty) {
          final fileName = p.basename(profileFile.name);
          final localPath = p.join(appDir.path, fileName);
          await File(localPath).writeAsBytes(profileFile.content as List<int>);
          patientMap['image_profil_path'] = localPath;
        }

        await txn.insert('patients', patientMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 2. Synchronisation des autres tables
      final tables = [
        'consultations', 'ordonnances', 'examens_analyses',
        'vaccinations', 'contacts_urgence', 'allergies', 'symptomes'
      ];

      for (var table in tables) {
        // Optionnel : On vide la table avant d'importer les données "officielles"
        // Cela permet de supprimer les éléments que le médecin aurait jugé obsolètes
        await txn.delete(table);

        final List rows = data[table] ?? [];
        for (var row in rows) {
          final rowMap = Map<String, dynamic>.from(row);

          // Gérer les documents PDF reçus
          if (table == 'examens_analyses' && rowMap['resultat_pdf_path'] != null) {
            final originalName = p.basename(rowMap['resultat_pdf_path'] as String);
            final pdfInArchive = archive.files.firstWhere(
              (f) => f.name == 'documents/$originalName',
              orElse: () => ArchiveFile('', 0, null)
            );

            if (pdfInArchive.name.isNotEmpty) {
              final localPath = p.join(appDir.path, originalName);
              await File(localPath).writeAsBytes(pdfInArchive.content as List<int>);
              rowMap['resultat_pdf_path'] = localPath;
            }
          }

          await txn.insert(table, rowMap, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  static Future<Map<String, dynamic>> getDossierMap() async {
    final db = await DatabaseHelper.instance.database;

    final patients = await db.query('patients');
    final consultations = await db.query('consultations');
    final ordonnances = await db.query('ordonnances');
    final examens = await db.query('examens_analyses');
    final vaccinations = await db.query('vaccinations');
    final contactsUrgence = await db.query('contacts_urgence');
    final allergies = await db.query('allergies');
    final symptomes = await db.query('symptomes');

    return {
      'version': '1.1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'patients': patients,
      'consultations': consultations,
      'ordonnances': ordonnances,
      'examens_analyses': examens,
      'vaccinations': vaccinations,
      'contacts_urgence': contactsUrgence,
      'allergies': allergies,
      'symptomes': symptomes,
    };
  }

  /// Taille formatée du fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
