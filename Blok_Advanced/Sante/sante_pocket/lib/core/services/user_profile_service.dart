import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class UserProfileService {
  static const String _keyName = 'user_name';
  static const String _keyUuid = 'user_uuid';
  static const String _keyIsFirstLaunch = 'is_first_launch_p2p';

  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsFirstLaunch, false);
  }

  static Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  static Future<String> getUserUuid() async {
    final prefs = await SharedPreferences.getInstance();
    String? uuid = prefs.getString(_keyUuid);
    
    if (uuid == null) {
      // Fallback: check old file-based UUID if exists
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, '.p2p_device_uuid'));
      if (await file.exists()) {
        uuid = (await file.readAsString()).trim();
      }
      
      if (uuid == null || uuid.isEmpty) {
        uuid = const Uuid().v4();
      }
      
      await prefs.setString(_keyUuid, uuid);
    }
    
    return uuid;
  }
}
