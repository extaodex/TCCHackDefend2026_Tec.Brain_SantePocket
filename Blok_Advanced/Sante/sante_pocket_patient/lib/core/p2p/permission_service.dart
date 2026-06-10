import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Service pour gérer les permissions réseau et stockage nécessaires au P2P.
class PermissionService {
  /// Demande toutes les permissions nécessaires sur Android.
  static Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) return true;

    final statuses = await [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.location,
      Permission.nearbyWifiDevices,
      Permission.camera, // Pour le scan QR
    ].request();

    // Pour MANAGE_EXTERNAL_STORAGE sur Android 11+
    if (await Permission.manageExternalStorage.isDenied) {
      await openAppSettings();
    }

    return statuses[Permission.storage]?.isGranted == true || 
           statuses[Permission.manageExternalStorage]?.isGranted == true;
  }

  /// Vérifie si les permissions de stockage nécessaires sont accordées.
  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;
    
    final storageGranted = await Permission.storage.isGranted;
    final manageGranted = await Permission.manageExternalStorage.isGranted;
    
    return storageGranted || manageGranted;
  }
}
