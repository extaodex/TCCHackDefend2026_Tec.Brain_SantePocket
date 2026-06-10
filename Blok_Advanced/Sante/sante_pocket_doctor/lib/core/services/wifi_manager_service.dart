import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum WifiScanStatus {
  idle,
  scanning,
  found,
  connecting,
  connected,
  notFound,
  error,
}

class WifiScanEvent {
  final WifiScanStatus status;
  final String? ssid;
  final String? error;

  WifiScanEvent(this.status, {this.ssid, this.error});
}

class WifiManagerService {
  final _statusController = StreamController<WifiScanEvent>.broadcast();
  Stream<WifiScanEvent> get statusStream => _statusController.stream;

  /// Recherche active d'un hotspot mobile correspondant au format MediShare_<UUID>_v1.
  /// Analyse la sortie de la commande `netsh wlan show networks`.
  Future<String?> scanForMediShareHotspot() async {
    if (!Platform.isWindows) {
      _statusController.add(WifiScanEvent(WifiScanStatus.error, error: "Non supporté sur cette plateforme"));
      return null;
    }

    _statusController.add(WifiScanEvent(WifiScanStatus.scanning));

    try {
      final result = await Process.run('netsh', ['wlan', 'show', 'networks']);
      if (result.exitCode != 0) {
        _statusController.add(WifiScanEvent(WifiScanStatus.error, error: "Impossible de lister les réseaux WiFi"));
        return null;
      }

      final output = result.stdout as String;
      final regex = RegExp(r'MediShare_[A-Za-z0-9_-]+_v1');
      final matches = regex.allMatches(output);

      if (matches.isNotEmpty) {
        final ssid = matches.first.group(0)!;
        _statusController.add(WifiScanEvent(WifiScanStatus.found, ssid: ssid));
        return ssid;
      } else {
        _statusController.add(WifiScanEvent(WifiScanStatus.notFound));
        return null;
      }
    } catch (e) {
      _statusController.add(WifiScanEvent(WifiScanStatus.error, error: e.toString()));
      return null;
    }
  }

  /// Extrait l'UUID contenu dans le SSID (MediShare_[UUID]_v1).
  static String? extractUuidFromSsid(String ssid) {
    final prefix = "MediShare_";
    final suffix = "_v1";
    if (ssid.startsWith(prefix) && ssid.endsWith(suffix)) {
      return ssid.substring(prefix.length, ssid.length - suffix.length);
    }
    return null;
  }

  /// Connecte la machine Windows au hotspot spécifié.
  /// Génère un fichier de profil XML temporaire pour la connexion WPA2.
  Future<bool> connectToHotspot(String ssid, String password) async {
    if (!Platform.isWindows) return false;

    _statusController.add(WifiScanEvent(WifiScanStatus.connecting, ssid: ssid));

    try {
      // 1. Convertir le SSID en Hexadécimal (requis par Windows dans l'XML)
      final hexSsid = utf8.encode(ssid).map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

      // 2. Générer le contenu XML du profil WLAN
      final xmlContent = '''<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$ssid</name>
    <SSIDConfig>
        <SSID>
            <hex>$hexSsid</hex>
            <name>$ssid</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>manual</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>''';

      // 3. Écrire le profil XML dans un fichier temporaire dans le répertoire de l'application
      final tempDir = await getTemporaryDirectory();
      final profileFile = File(p.join(tempDir.path, 'temp_wifi_profile.xml'));
      await profileFile.writeAsString(xmlContent);

      // 4. Importer le profil WiFi
      final addProfileResult = await Process.run('netsh', ['wlan', 'add', 'profile', 'filename=${profileFile.path}']);
      if (addProfileResult.exitCode != 0) {
        _statusController.add(WifiScanEvent(WifiScanStatus.error, error: "Erreur lors de la création du profil WiFi"));
        return false;
      }

      // 5. Se connecter au réseau
      final connectResult = await Process.run('netsh', ['wlan', 'connect', 'name=$ssid']);
      if (connectResult.exitCode != 0) {
        _statusController.add(WifiScanEvent(WifiScanStatus.error, error: "Échec de connexion au réseau"));
        return false;
      }

      // 6. Attendre quelques secondes et vérifier le statut de la connexion
      int retries = 5;
      bool isConnected = false;
      while (retries > 0) {
        await Future.delayed(const Duration(seconds: 1));
        final statusResult = await Process.run('netsh', ['wlan', 'show', 'interfaces']);
        final statusOutput = statusResult.stdout as String;
        if (statusOutput.contains(ssid) && statusOutput.contains("connect")) {
          isConnected = true;
          break;
        }
        retries--;
      }

      if (isConnected) {
        _statusController.add(WifiScanEvent(WifiScanStatus.connected, ssid: ssid));
        return true;
      } else {
        _statusController.add(WifiScanEvent(WifiScanStatus.error, error: "Délai d'attente de connexion dépassé"));
        return false;
      }
    } catch (e) {
      _statusController.add(WifiScanEvent(WifiScanStatus.error, error: e.toString()));
      return false;
    }
  }

  /// Déconnecte du réseau WiFi actuel et supprime le profil temporaire.
  Future<void> disconnectFromHotspot(String ssid) async {
    if (!Platform.isWindows) return;

    try {
      await Process.run('netsh', ['wlan', 'disconnect']);
      await Process.run('netsh', ['wlan', 'delete', 'profile', 'name=$ssid']);
    } catch (_) {}
    _statusController.add(WifiScanEvent(WifiScanStatus.idle));
  }
}
