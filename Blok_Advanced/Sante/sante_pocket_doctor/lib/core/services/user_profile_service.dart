import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'database_service.dart';

class UserProfileService {
  static const String _keyFirstLaunch = 'first_launch_done';
  static const String _keyDoctorName = 'doctor_name';
  static const String _keyDoctorUuid = 'doctor_uuid';

  /// Vérifie si c'est le premier lancement de l'application.
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyFirstLaunch) ?? false);
  }

  /// Sauvegarde le nom du médecin et synchronise avec le profil de base de données.
  static Future<void> saveDoctorName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDoctorName, name);
    await prefs.setBool(_keyFirstLaunch, true);
    
    // Assurer que l'UUID existe
    await getDoctorUuid();

    // Synchronisation avec SQLCipher
    await DatabaseService.saveDoctorProfile(name, 'Généraliste');
  }

  /// Récupère le nom du médecin.
  static Future<String?> getDoctorName() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString(_keyDoctorName);
    
    // Si absent dans SharedPreferences, essayer de lire depuis SQLCipher
    if (name == null) {
      final dbProfile = await DatabaseService.getDoctorProfile();
      name = dbProfile['name'];
      if (name != null && name != 'Dr. Dupont') {
        // Enregistrer dans SharedPreferences
        await prefs.setString(_keyDoctorName, name);
      } else {
        name = null;
      }
    }
    return name;
  }

  /// Récupère ou génère un UUID persistant unique pour ce médecin.
  static Future<String> getDoctorUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_keyDoctorUuid);
    if (uuid == null || uuid.isEmpty) {
      uuid = const Uuid().v4();
      await prefs.setString(_keyDoctorUuid, uuid);
    }
    return uuid;
  }
}
