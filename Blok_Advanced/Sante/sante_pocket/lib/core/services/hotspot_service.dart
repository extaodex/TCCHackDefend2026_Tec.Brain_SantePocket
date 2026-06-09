import 'package:flutter/services.dart';
import 'dart:io';

class HotspotService {
  static const MethodChannel _channel = MethodChannel('com.santepocket.sante_pocket/hotspot');

  /// Active le hotspot avec un SSID et un mot de passe personnalisés.
  /// Note: Sur Android 8+, cela activera généralement un "LocalOnlyHotspot" 
  /// dont le SSID/PWD est géré par le système.
  static Future<Map<String, String>?> enableHotspot() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod('enableHotspot');
      if (result != null) {
        return Map<String, String>.from(result);
      }
    } catch (e) {
      print("Erreur activation hotspot: $e");
    }
    return null;
  }

  /// Désactive le hotspot.
  static Future<void> disableHotspot() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('disableHotspot');
    } catch (e) {
      print("Erreur désactivation hotspot: $e");
    }
  }
}
