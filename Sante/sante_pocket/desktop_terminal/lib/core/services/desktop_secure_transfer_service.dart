import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'database_service.dart';

enum ConnectionStatus { idle, listening, connected, error }

class TransferState {
  final ConnectionStatus status;
  final Map<String, dynamic>? patientRecord;
  final String? localIp;
  final int port;

  TransferState({this.status = ConnectionStatus.idle, this.patientRecord, this.localIp, this.port = 8080});

  TransferState copyWith({ConnectionStatus? status, Map<String, dynamic>? patientRecord, String? localIp}) {
    return TransferState(
      status: status ?? this.status,
      patientRecord: patientRecord ?? this.patientRecord,
      localIp: localIp ?? this.localIp,
    );
  }
}

class DesktopSecureTransferService extends Notifier<TransferState> {
  HttpServer? _server;
  final _key = enc.Key.fromUtf8('my-ultra-secure-key-32-chars-!!!'); // À sécuriser d'avantage
  final _iv = enc.IV.fromLength(16);

  @override
  TransferState build() => TransferState();

  // Déchiffrer les données reçues du mobile
  Map<String, dynamic> _decrypt(String encryptedBase64) {
    final encrypter = enc.Encrypter(enc.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedBase64, iv: _iv);
    return jsonDecode(decrypted);
  }

  // Chiffrer les données à envoyer au mobile
  String _encrypt(Map<String, dynamic> data) {
    final encrypter = enc.Encrypter(enc.AES(_key));
    return encrypter.encrypt(jsonEncode(data), iv: _iv).base64;
  }

  Future<void> startServer() async {
    try {
      final ip = await _getLocalIp();
      final router = Router();

      router.post('/upload_record', (Request request) async {
        final body = await request.readAsString();
        final decryptedData = _decrypt(body);
        
        // Sauvegarde automatique en base de données
        await DatabaseService.savePatient(decryptedData);
        
        state = state.copyWith(status: ConnectionStatus.connected, patientRecord: decryptedData);
        return Response.ok(jsonEncode({'status': 'ok'}));
      });

      router.get('/get_prescription', (Request request) async {
        final prescription = {
          'id': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          'data': 'Ordonnance chiffrée hors-ligne'
        };
        return Response.ok(_encrypt(prescription));
      });

      _server = await io.serve(router.call, InternetAddress.anyIPv4, 8080);
      state = state.copyWith(status: ConnectionStatus.listening, localIp: ip);
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (var interface in interfaces) {
      // Priorité aux interfaces Wi-Fi ou Point d'accès
      if (interface.name.contains('wlan') || interface.name.contains('Wi-Fi')) {
        return interface.addresses.first.address;
      }
    }
    return interfaces.isNotEmpty ? interfaces.first.addresses.first.address : '127.0.0.1';
  }

  void stopServer() => _server?.close();
}

final secureTransferServiceProvider = NotifierProvider<DesktopSecureTransferService, TransferState>(() => DesktopSecureTransferService());
