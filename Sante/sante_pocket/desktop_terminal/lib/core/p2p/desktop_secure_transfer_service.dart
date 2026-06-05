import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:nearby_connections/nearby_connections.dart';

class DesktopSecureTransferService {
  final String _secretKey = "super-secret-key-for-now"; // Doit correspondre à la clé mobile

  // --- Chiffrement ---
  Map<String, dynamic> decryptData(Uint8List encryptedData) {
    final iv = enc.IV(encryptedData.sublist(0, 16));
    final encrypted = enc.Encrypted(encryptedData.sublist(16));
    final key = enc.Key.fromUtf8(_secretKey.padRight(32, '0').substring(0, 32));
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final decrypted = encrypter.decrypt(encrypted, iv: iv);
    return jsonDecode(decrypted);
  }

  // --- Connexion P2P (Réception) ---
  Future<void> startListening(
      String doctorName, 
      Function(Map<String, dynamic>) onDataReceived) async {
    await Nearby().startAdvertising(
      doctorName,
      Strategy.P2P_STAR,
      onConnectionInitiated: (id, info) => Nearby().acceptConnection(
        id, 
        onPayLoadRecieved: (id, payload) {
          if (payload.type == PayloadType.BYTES) {
            final data = decryptData(payload.bytes!);
            onDataReceived(data);
          }
        },
      ),
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
    );
  }
}
