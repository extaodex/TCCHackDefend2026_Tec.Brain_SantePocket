import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;

class PatientSyncService {
  String? _serverUrl;
  final _key = enc.Key.fromUtf8('my-ultra-secure-key-32-chars-!!!');
  final _iv = enc.IV.fromLength(16);

  bool configureFromQr(String qrData) {
    if (qrData.startsWith('sante_sync:')) {
      final parts = qrData.split(':');
      if (parts.length == 3) {
        _serverUrl = 'http://${parts[1]}:${parts[2]}';
        return true;
      }
    }
    return false;
  }

  String _encrypt(Map<String, dynamic> data) {
    final encrypter = enc.Encrypter(enc.AES(_key));
    return encrypter.encrypt(jsonEncode(data), iv: _iv).base64;
  }

  Map<String, dynamic> _decrypt(String encryptedBase64) {
    final encrypter = enc.Encrypter(enc.AES(_key));
    return jsonDecode(encrypter.decrypt64(encryptedBase64, iv: _iv));
  }

  Future<bool> sendRecordToDoctor(Map<String, dynamic> record) async {
    if (_serverUrl == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/upload_record'),
        body: _encrypt(record),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> receivePrescription() async {
    if (_serverUrl == null) return null;
    try {
      final response = await http.get(Uri.parse('$_serverUrl/get_prescription'));
      if (response.statusCode == 200) {
        return _decrypt(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Erreur lors de la réception: $e');
    }
    return null;
  }
}
