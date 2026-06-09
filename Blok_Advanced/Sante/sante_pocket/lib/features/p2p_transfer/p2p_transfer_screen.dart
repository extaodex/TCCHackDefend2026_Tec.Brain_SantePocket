import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/mobile_secure_transfer_service.dart';
import 'qr_scanner_view.dart';

class P2PTransferScreen extends ConsumerWidget {
  final File? fileToShare; // null if waiting for return
  
  const P2PTransferScreen({super.key, this.fileToShare});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mobileTransferProvider);
    final notifier = ref.read(mobileTransferProvider.notifier);

    // Initialisation du flux
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == MobileFlowStatus.idle) {
        if (fileToShare != null) {
          notifier.startFlux1(fileToShare!);
        } else {
          notifier.startFlux2();
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade900, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(state.status),
              const SizedBox(height: 32),
              Text(
                _getStatusMessage(state),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (state.status == MobileFlowStatus.transferring) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "${(state.progress * 100).toInt()}% - ${state.currentFilename}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              if (state.status == MobileFlowStatus.scanningQr) ...[
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerView()));
                    if (result != null) {
                      notifier.connectViaQr(result);
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text("Scanner le code QR du médecin"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
              if (state.status == MobileFlowStatus.completed) ...[
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: const Text("Terminer"),
                ),
              ],
              if (state.status == MobileFlowStatus.error) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(state.errorMessage ?? "Erreur inconnue", style: const TextStyle(color: Colors.redAccent)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Retour"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(MobileFlowStatus status) {
    switch (status) {
      case MobileFlowStatus.enablingHotspot:
      case MobileFlowStatus.hotspotActive:
        return const Icon(Icons.wifi_tethering, size: 80, color: Colors.white);
      case MobileFlowStatus.discoveringDoctor:
        return const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(color: Colors.white));
      case MobileFlowStatus.doctorFound:
      case MobileFlowStatus.connecting:
        return const Icon(Icons.verified_user, size: 80, color: Colors.white);
      case MobileFlowStatus.transferring:
        return const Icon(Icons.swap_calls, size: 80, color: Colors.white);
      case MobileFlowStatus.completed:
        return const Icon(Icons.check_circle, size: 80, color: Colors.greenAccent);
      case MobileFlowStatus.scanningQr:
        return const Icon(Icons.qr_code, size: 80, color: Colors.white);
      case MobileFlowStatus.error:
        return const Icon(Icons.error, size: 80, color: Colors.redAccent);
      default:
        return const Icon(Icons.sync, size: 80, color: Colors.white);
    }
  }

  String _getStatusMessage(MobileTransferState state) {
    switch (state.status) {
      case MobileFlowStatus.enablingHotspot: return "Activation du hotspot...";
      case MobileFlowStatus.hotspotActive: return "Hotspot actif. Recherche du médecin...";
      case MobileFlowStatus.discoveringDoctor: return "Recherche du médecin sur le réseau...";
      case MobileFlowStatus.doctorFound: return "Médecin trouvé : ${state.doctorName}";
      case MobileFlowStatus.connecting: return "Connexion en cours...";
      case MobileFlowStatus.transferring: return "Transfert des fichiers...";
      case MobileFlowStatus.scanningQr: return "Médecin non trouvé automatiquement.";
      case MobileFlowStatus.completed: return "Transfert réussi !";
      case MobileFlowStatus.error: return "Erreur de transfert";
      default: return "Initialisation...";
    }
  }
}
