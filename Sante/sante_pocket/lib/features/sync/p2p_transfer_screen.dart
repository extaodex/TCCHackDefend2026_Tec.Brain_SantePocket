import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/p2p/patient_sync_service.dart';

class P2PTransferScreen extends StatefulWidget {
  const P2PTransferScreen({super.key});

  @override
  State<P2PTransferScreen> createState() => _P2PTransferScreenState();
}

class _P2PTransferScreenState extends State<P2PTransferScreen> {
  final _syncService = PatientSyncService();
  bool _isConnected = false;
  bool _isScanning = false;

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Hors-Ligne (Style Xender)'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pour transférer sans internet, les deux appareils doivent être sur le même réseau local :'),
              const SizedBox(height: 15),
              _buildHelpStep(
                '1',
                'Activez le "Point d\'accès mobile" (Hotspot) sur ce téléphone.',
                Icons.portable_wifi_off,
              ),
              _buildHelpStep(
                '2',
                'Demandez au médecin de connecter son PC au Wi-Fi de votre téléphone.',
                Icons.computer,
              ),
              _buildHelpStep(
                '3',
                'Une fois connecté, scannez le code QR sur l\'écran du médecin.',
                Icons.qr_code_scanner,
              ),
              const Divider(),
              const Text(
                'Note: Aucune donnée mobile n\'est utilisée. Le transfert est direct et chiffré.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('J\'ai compris'))
        ],
      ),
    );
  }

  Widget _buildHelpStep(String number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 12, child: Text(number, style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          Icon(icon, size: 20, color: Colors.blueGrey),
        ],
      ),
    );
  }

  void _onScan(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !_isConnected) {
      final code = barcodes.first.rawValue;
      if (code != null && _syncService.configureFromQr(code)) {
        setState(() {
          _isConnected = true;
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connecté au médecin !')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation Médecin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isConnected && !_isScanning) ...[
                const Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  'Scannez le code QR sur l\'écran du médecin pour commencer le transfert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => setState(() => _isScanning = true),
                  child: const Text('Scanner le Code QR'),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _showHelpDialog,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('Comment se connecter sans internet ?'),
                ),
              ],

              if (_isScanning)
                SizedBox(
                  height: 300,
                  width: 300,
                  child: MobileScanner(onDetect: _onScan),
                ),

              if (_isConnected) ...[
                const Icon(Icons.check_circle, size: 100, color: Colors.green),
                const SizedBox(height: 20),
                const Text('Lien établi avec le terminal du médecin.'),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () async {
                    final data = {
                      'nom': 'Doe',
                      'prenom': 'John',
                      'dossier': 'Historique médical complet...'
                    };
                    final success = await _syncService.sendRecordToDoctor(data);
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dossier envoyé avec succès !')),
                      );
                    }
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Envoyer mon Dossier'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    final prescription = await _syncService.receivePrescription();
                    if (!context.mounted) return;
                    if (prescription != null) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Nouvelle Ordonnance'),
                          content: Text('Reçue de: ${prescription['medecin']}\n\n'
                              'Instructions: ${prescription['instructions']}'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Recevoir Ordonnance'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() => _isConnected = false),
                  child: const Text('Déconnecter'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
