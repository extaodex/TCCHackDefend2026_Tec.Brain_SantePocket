import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/db/database_helper.dart';

/// Service de génération du fichier d'export .msh (MémoSanté Health archive)
/// Conforme au cahier des charges technique V2.0
///
/// Format de l'archive .msh :
/// - dossier_clinique.json : sérialisation complète de toutes les tables SQL
/// - /documents/ : copie des PDFs numérisés
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
      'version': '1.0.0',
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

    // 5. Encoder en ZIP et sauvegarder avec extension .msh
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Erreur de compression ZIP');

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mshPath = p.join(dir.path, 'memosante_$timestamp.msh');
    final mshFile = File(mshPath);
    await mshFile.writeAsBytes(zipBytes);

    return mshPath;
  }

  /// Taille formatée du fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
}
