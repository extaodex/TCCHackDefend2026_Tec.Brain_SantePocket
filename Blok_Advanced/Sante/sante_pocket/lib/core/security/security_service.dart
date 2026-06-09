import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _dbKeyName = 'sp_secure_db_key';
  static const String _userPasswordKey = 'sp_user_password';

  /// Récupère la clé de chiffrement existante ou en génère une nouvelle
  /// de manière persistante.
  static Future<String> getOrCreateDatabaseKey() async {
    final prefs = await SharedPreferences.getInstance();
    String? existingKey = prefs.getString(_dbKeyName);

    if (existingKey == null) {
      // Génération d'une clé unique complexe
      final newKey = const Uuid().v4();
      await prefs.setString(_dbKeyName, newKey);
      return newKey;
    }

    return existingKey;
  }

  /// Vérifie si un mot de passe utilisateur est configuré
  static Future<bool> hasUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userPasswordKey);
  }

  /// Définit un nouveau mot de passe utilisateur
  static Future<void> setUserPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    // En production, on devrait hasher le mot de passe
    await prefs.setString(_userPasswordKey, password);
  }

  /// Vérifie si le mot de passe fourni est correct
  static Future<bool> verifyPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_userPasswordKey);
    return stored == password;
  }
}
