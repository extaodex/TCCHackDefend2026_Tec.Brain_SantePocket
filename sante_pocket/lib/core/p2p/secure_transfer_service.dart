import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:nearby_connections/nearby_connections.dart';

class SecureTransferService {
  final String _secretKey = "super-secret-key-for-now"; // À remplacer par un vrai échange de clés
  final Strategy strategy = Strategy.P2P_STAR;

  // --- Chiffrement ---
  Uint8List encryptData(Map<String, dynamic> data) {
    final plainText = jsonEncode(data);
    final key = enc.Key.fromUtf8(_secretKey.padRight(32, '0').substring(0, 32));
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // On concatène IV + Texte Chiffré pour le déchiffrement
    return Uint8List.fromList(iv.bytes + encrypted.bytes);
  }

  // --- Connexion P2P ---
  Future<void> startAdvertising(
      String userName, 
      Function(String, Payload) onPayloadReceived) async {
    await Nearby().startAdvertising(
      userName,
      strategy,
      onConnectionInitiated: (id, info) => Nearby().acceptConnection(
        id, 
        onPayLoadRecieved: (id, payload) => onPayloadReceived(id, payload),
      ),
      onConnectionResult: (id, status) {},
      onDisconnected: (id) {},
    );
  }

  Future<void> startDiscovery(
      String userName,
      Function(String, String, String) onEndpointFound,
      Function(String?) onEndpointLost) async {
    await Nearby().startDiscovery(
      userName,
      strategy,
      onEndpointFound: onEndpointFound,
      onEndpointLost: onEndpointLost,
    );
  }

  Future<void> requestConnection(
      String userName, 
      String endpointId, 
      Function(String, Status) onResult,
      Function(String, Payload) onPayloadReceived) async {
    await Nearby().requestConnection(
      userName,
      endpointId,
      onConnectionInitiated: (id, info) => Nearby().acceptConnection(
        id, 
        onPayLoadRecieved: onPayloadReceived,
      ),
      onConnectionResult: (id, status) => onResult(id, status),
      onDisconnected: (id) {},
    );
  }
}
