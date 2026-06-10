import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service pour générer une archive .msh à partir du dossier patient sur PC
class MshGeneratorService {
  /// Génère un fichier .msh prêt à être renvoyé au mobile
  static Future<String> generateMshFromRecord(Map<String, dynamic> record) async {
    // 1. Récupérer le dossier clinique original
    Map<String, dynamic> dossier = Map<String, dynamic>.from(record['dossier_clinique'] ?? {});

    // 2. Mettre à jour avec les modifications faites par le médecin sur PC
    // Mise à jour des notes dans le dossier clinique (qui sera réimporté par le mobile)
    List consultations = List.from(dossier['consultations'] ?? []);

    // On peut soit mettre à jour la dernière consultation, soit en créer une nouvelle.
    // Pour simplifier, on s'assure que les notes du médecin sur PC sont intégrées.
    if (consultations.isNotEmpty) {
      // On met à jour la note de la consultation la plus récente
      Map<String, dynamic> lastConsult = Map<String, dynamic>.from(consultations.last);
      lastConsult['notes'] = record['notes'] ?? '';
      consultations[consultations.length - 1] = lastConsult;
    } else {
      // Création d'une entrée par défaut si aucune n'existe
      consultations.add({
        'patient_id': 1,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'diagnostic': 'Consultation PC',
        'notes': record['notes'] ?? '',
        'statut_validation': 'VALIDE',
      });
    }
    dossier['consultations'] = consultations;
    dossier['timestamp'] = DateTime.now().toIso8601String();

    // 3. Créer l'archive ZIP
    final archive = Archive();

    // Dossier clinique JSON
    final jsonStr = const JsonEncoder.withIndent('  ').convert(dossier);
    final jsonBytes = utf8.encode(jsonStr);
    archive.addFile(ArchiveFile('dossier_clinique.json', jsonBytes.length, jsonBytes));

    // 4. Ré-inclure les documents extraits
    // On parcourt les documents extraits localement sur le PC pour les remettre dans l'archive
    final extractedDocs = record['extracted_documents'] as Map<String, dynamic>? ?? {};
    for (var entry in extractedDocs.entries) {
      final localPath = entry.value as String;
      final internalName = entry.key; // e.g. "documents/test.pdf"

      final file = File(localPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        archive.addFile(ArchiveFile(internalName, bytes.length, bytes));
      }
    }

    // 5. Encoder et sauvegarder
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Erreur compression');

    final tempDir = await getTemporaryDirectory();
    final mshPath = p.join(tempDir.path, 'retour_medecin_${DateTime.now().millisecondsSinceEpoch}.msh');
    await File(mshPath).writeAsBytes(zipBytes);

    return mshPath;
  }
}
