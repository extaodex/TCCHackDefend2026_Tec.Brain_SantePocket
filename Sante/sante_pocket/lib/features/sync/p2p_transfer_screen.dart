import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/p2p/patient_sync_service.dart';
import 'sync_service.dart';

class P2PTransferScreen extends StatefulWidget {
  const P2PTransferScreen({super.key});

  @override
  State<P2PTransferScreen> createState() => _P2PTransferScreenState();
}

class _P2PTransferScreenState extends State<P2PTransferScreen> {
  final _syncService = PatientSyncService();
  bool _isConnected = false;
  bool _isScanning = false;
  bool _isSending = false;

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Hors-Ligne (Style Xender)'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pour transférer sans internet, les deux appareils doivent être sur le même réseau local :'),
              const SizedBox(height: 15),
              _buildHelpStep('1', 'Activez le "Point d\'accès mobile" (Hotspot) sur ce téléphone.', Icons.portable_wifi_off),
              _buildHelpStep('2', 'Connectez le PC du médecin au Wi-Fi de votre téléphone.', Icons.computer),
              _buildHelpStep('3', 'Une fois connecté, scannez le code QR sur l\'écran du médecin.', Icons.qr_code_scanner),
              const Divider(),
              const Text(
                'Note: Vos données sont chiffrées (AES-256) et ne passent jamais par internet.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Compris'))
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
          CircleAvatar(radius: 12, child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
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
          const SnackBar(content: Text('Connexion établie avec le terminal médecin')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partage Direct (P2P)'),
        actions: [
          IconButton(onPressed: _showHelpDialog, icon: const Icon(Icons.help_outline)),
        ],
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isConnected && !_isScanning) ...[
              _buildXenderIcon(Icons.qr_code_scanner, Colors.blue),
              const SizedBox(height: 32),
              const Text('Scanner pour partager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Partagez votre dossier médical avec le médecin\nen scannant le code QR sur son écran.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => setState(() => _isScanning = true),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('OUVRIR LE SCANNER', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
            ],

            if (_isScanning) ...[
              const Text('Scannez le code QR du médecin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.primary, width: 2)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MobileScanner(onDetect: _onScan),
                ),
              ),
              const SizedBox(height: 32),
              TextButton(onPressed: () => setState(() => _isScanning = false), child: const Text('Annuler')),
            ],

            if (_isConnected) ...[
              _buildXenderIcon(Icons.check_circle, Colors.green),
              const SizedBox(height: 32),
              const Text('Terminal Connecté', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Prêt pour l\'échange sécurisé', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
              const SizedBox(height: 48),
              
              if (_isSending)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Envoi du dossier en cours...', style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                )
              else ...[
                _buildActionButton(
                  onPressed: () async {
                    setState(() => _isSending = true);
                    final dossier = await SyncService.getDossierMap();
                    final success = await _syncService.sendRecordToDoctor(dossier);
                    setState(() => _isSending = false);
                    
                    if (!context.mounted) return;
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Dossier envoyé avec succès !'), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Échec de l\'envoi. Vérifiez la connexion.'), backgroundColor: Colors.red));
                    }
                  },
                  icon: Icons.upload_file_rounded,
                  label: 'ENVOYER MON DOSSIER COMPLET',
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  onPressed: () async {
                    final prescription = await _syncService.receivePrescription();
                    if (!context.mounted) return;
                    if (prescription != null) {
                      _showPrescriptionDialog(prescription);
                    }
                  },
                  icon: Icons.download_for_offline_rounded,
                  label: 'RECEVOIR ORDONNANCE',
                  color: Colors.orange.shade800,
                ),
                const SizedBox(height: 32),
                TextButton(onPressed: () => setState(() => _isConnected = false), child: const Text('Déconnecter', style: TextStyle(color: Colors.red))),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildXenderIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 80, color: color),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: const Duration(seconds: 2), color: color.withValues(alpha: 0.2)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: const Duration(seconds: 1), curve: Curves.easeInOut);
  }

  Widget _buildActionButton({required VoidCallback onPressed, required IconData icon, required String label, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
      ),
    );
  }

  void _showPrescriptionDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.description, color: Colors.orange),
            SizedBox(width: 12),
            Text('Nouvelle Ordonnance'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Médecin : ${data['medecin'] ?? 'Inconnu'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Instructions :'),
            Text(data['instructions'] ?? 'Pas d\'instructions spécifiques.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Sauvegarder')),
        ],
      ),
    );
  }
}
