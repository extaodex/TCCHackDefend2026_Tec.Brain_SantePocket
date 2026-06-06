import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';

/// Service pour lire, décompresser et analyser les archives de santé .msh
class MshParserService {
  /// Décompresse le fichier .msh et extrait le dossier clinique consolidé
  static Future<Map<String, dynamic>> parseMshFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    
    // Décompression du zip (.msh)
    final archive = ZipDecoder().decodeBytes(bytes);
    
    ArchiveFile? jsonFile;
    for (final file in archive) {
      if (file.name == 'dossier_clinique.json') {
        jsonFile = file;
        break;
      }
    }
    
    if (jsonFile == null) {
      throw Exception('Fichier dossier_clinique.json introuvable dans l\'archive .msh');
    }
    
    // Lecture du JSON
    final jsonStr = utf8.decode(jsonFile.content as List<int>);
    final dossier = jsonDecode(jsonStr) as Map<String, dynamic>;
    
    // Conversion et consolidation du dossier patient
    final patients = dossier['patients'] as List<dynamic>? ?? [];
    final allergiesTable = dossier['allergies'] as List<dynamic>? ?? [];
    
    final patient = patients.isNotEmpty ? patients.first as Map<String, dynamic> : {};
    
    // Extraction des allergies
    final List<String> allergiesList = [];
    for (var item in allergiesTable) {
      if (item is Map && item['libelle'] != null) {
        allergiesList.add(item['libelle'].toString());
      }
    }
    
    // Fallback sur le champ allergies du patient si la table dédiée est vide
    if (allergiesList.isEmpty && patient['allergies'] != null && patient['allergies'].toString().isNotEmpty) {
      allergiesList.addAll(patient['allergies'].toString().split(',').map((e) => e.trim()));
    }
    
    // Format attendu par la base de données et l'IHM du médecin
    return {
      'nom': patient['nom'] ?? 'N/A',
      'prenom': patient['prenom'] ?? 'N/A',
      'dob': patient['date_naissance'] ?? patient['dob'] ?? 'N/A',
      'groupeSanguin': patient['groupe_sanguin'] ?? patient['groupeSanguin'] ?? 'N/A',
      'sexe': patient['sexe'] ?? 'N/A',
      'taille': patient['taille'] ?? 'N/A',
      'poids': patient['poids'] ?? 'N/A',
      'tension': patient['tension'] ?? 'N/A',
      'allergies': allergiesList,
      'antecedents': patient['antecedents'] ?? '',
      'notes': '', // Notes ou rapport rédigé par le médecin sur PC
      'dossier_clinique': dossier, // On conserve l'historique complet (ordonnances, consultations, vaccins, etc.)
    };
  }
}
