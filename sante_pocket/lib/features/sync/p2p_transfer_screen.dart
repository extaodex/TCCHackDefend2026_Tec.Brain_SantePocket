import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../../core/p2p/secure_transfer_service.dart';

class P2PTransferScreen extends StatefulWidget {
  const P2PTransferScreen({super.key});

  @override
  State<P2PTransferScreen> createState() => _P2PTransferScreenState();
}

class _P2PTransferScreenState extends State<P2PTransferScreen> {
  final _service = SecureTransferService();
  final Nearby _nearby = Nearby();
  bool _isDoctor = false;
  final String _qrData = "";
  String? _connectedEndpointId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfert P2P sécurisé')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isDoctor = true;
                });
                _service.startAdvertising(
                  "Medecin_${DateTime.now().millisecondsSinceEpoch}",
                  (id, payload) { /* Gérer la réception des données */ },
                );
              },
              child: const Text('Je suis Médecin (Recevoir)'),
            ),
            if (_isDoctor && _qrData.isNotEmpty)
              QrImageView(data: _qrData, size: 200),
            
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      if (barcodes.isNotEmpty) {
                        final raw = barcodes.first.rawValue;
                        if (raw != null) {
                          // TODO: Connect to endpoint
                        }
                      }
                    },
                  ),
                ));
              },
              child: const Text('Je suis Patient (Connecter)'),
            ),
            if (_connectedEndpointId != null)
              ElevatedButton(
                onPressed: () async {
                  final patientData = {
                      'nom': 'Doe',
                      'prenom': 'John',
                      'dob': '1990-01-01',
                      'allergies': ['Pénicilline', 'Pollens'],
                      'groupeSanguin': 'A+',
                      'notes': 'Patient asthmatique léger.'
                  };
                  final encryptedData = _service.encryptData(patientData);
                  await _nearby.sendBytesPayload(_connectedEndpointId!, Uint8List.fromList(encryptedData));
                },
                child: const Text('Envoyer Dossier Médical'),
              ),
          ],
        ),
      ),
    );
  }
}
