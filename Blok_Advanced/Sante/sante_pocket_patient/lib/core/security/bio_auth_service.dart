import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BioAuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si l'appareil supporte la biométrie et si elle est configurée
  static Future<bool> canAuthenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Tente d'authentifier l'utilisateur
  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à vos données de santé',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permet d'utiliser le code PIN/Schéma en fallback
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Erreur d\'authentification biométrique: $e');
      return false;
    }
  }
}
