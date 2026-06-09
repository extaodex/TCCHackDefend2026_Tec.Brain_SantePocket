import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service pour lire, décompresser et analyser les archives de santé .msh
class MshParserService {
  /// Décompresse le fichier .msh, extrait le JSON et sauvegarde les fichiers joints (PDF, images)
  static Future<Map<String, dynamic>> parseMshFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    
    // Décompression du zip (.msh)
    final archive = ZipDecoder().decodeBytes(bytes);
    
    final appDocDir = await getApplicationSupportDirectory();
    final patientsDocsRoot = Directory(p.join(appDocDir.path, 'patients_data'));
    if (!await patientsDocsRoot.exists()) await patientsDocsRoot.create();

    ArchiveFile? jsonFile;
    Map<String, String> extractedFiles = {}; // Map entre nom original et nouveau chemin local

    // 1. Premier passage pour trouver le JSON et identifier le patient
    for (final file in archive) {
      if (file.name == 'dossier_clinique.json') {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) {
      throw Exception('Fichier dossier_clinique.json introuvable dans l\'archive .msh');
    }

    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final dossier = jsonDecode(jsonStr) as Map<String, dynamic>;
    final patients = dossier['patients'] as List<dynamic>? ?? [];
    final patient = patients.isNotEmpty ? patients.first as Map<String, dynamic> : {};
    
    // Identifiant unique pour le dossier de stockage du patient sur le PC
    final patientId = '${patient['nom']}_${patient['prenom']}_${patient['date_naissance']}'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    final patientStorageDir = Directory(p.join(patientsDocsRoot.path, patientId));
    if (!await patientStorageDir.exists()) await patientStorageDir.create();

    // 2. Second passage pour extraire les fichiers (PDFs et Photo)
    for (final file in archive) {
      if (file.name == 'dossier_clinique.json') continue;

      final data = file.content as List<int>;
      final fileName = p.basename(file.name);
      final subDirName = p.dirname(file.name); // e.g., "documents" or "profile"

      final subDir = Directory(p.join(patientStorageDir.path, subDirName));
      if (!await subDir.exists()) await subDir.create(recursive: true);

      final localFile = File(p.join(subDir.path, fileName));
      await localFile.writeAsBytes(data);

      extractedFiles[file.name] = localFile.path;
    }

    // 3. Consolidation des données
    final allergiesTable = dossier['allergies'] as List<dynamic>? ?? [];
    final List<String> allergiesList = [];
    for (var item in allergiesTable) {
      if (item is Map && item['libelle'] != null) {
        allergiesList.add(item['libelle'].toString());
      }
    }

    // Récupération de la photo de profil extraite
    String localProfilePath = '';
    final profileEntry = extractedFiles.keys.firstWhere((k) => k.startsWith('profile/'), orElse: () => '');
    if (profileEntry.isNotEmpty) {
      localProfilePath = extractedFiles[profileEntry]!;
    }

    return {
      'nom': patient['nom'] ?? 'N/A',
      'prenom': patient['prenom'] ?? 'N/A',
      'dob': patient['date_naissance'] ?? 'N/A',
      'groupeSanguin': patient['groupe_sanguin'] ?? 'N/A',
      'sexe': patient['sexe'] ?? 'N/A',
      'taille': patient['taille'] ?? 'N/A',
      'poids': patient['poids'] ?? 'N/A',
      'tension': patient['tension'] ?? 'N/A',
      'allergies': allergiesList,
      'antecedents': patient['antecedents'] ?? '',
      'image_profil_local': localProfilePath,
      'extracted_documents': extractedFiles, // Utile pour ouvrir les PDFs plus tard
      'notes': '',
      'dossier_clinique': dossier,
    };
  }
}
