import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Service pour gérer les permissions réseau et stockage nécessaires au P2P.
class PermissionService {
  /// Demande toutes les permissions nécessaires sur Android.
  /// Ne fait rien sur les autres plateformes.
  static Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Demander les permissions de stockage de base
    final storageStatus = await Permission.storage.request();

    // 2. Pour Android 13+ (API 33+), demander l'accès aux appareils WiFi à proximité
    if (await Permission.nearbyWifiDevices.status.isDenied) {
      await Permission.nearbyWifiDevices.request();
    }

    // 3. Gérer MANAGE_EXTERNAL_STORAGE pour Android 11+ (API 30+)
    // Utile pour accéder aux dossiers externes si nécessaire.
    if (await Permission.manageExternalStorage.isDenied) {
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isPermanentlyDenied) {
        // Rediriger vers les paramètres pour que l'utilisateur puisse l'activer manuellement
        await openAppSettings();
      }
    }

    return storageStatus.isGranted || await Permission.manageExternalStorage.isGranted;
  }

  /// Vérifie si les permissions de stockage nécessaires sont accordées.
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    final storageGranted = await Permission.storage.isGranted;
    final manageGranted = await Permission.manageExternalStorage.isGranted;
    
    return storageGranted || manageGranted;
  }
}
