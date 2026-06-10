import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import 'sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isExporting = false;
  String? _lastExportPath;
  String? _lastExportSize;

  Future<void> _exportDossier() async {
    setState(() => _isExporting = true);
    try {
      final path = await SyncService.generateMshArchive();
      final file = File(path);
      final size = SyncService.formatFileSize(await file.length());

      setState(() {
        _lastExportPath = path;
        _lastExportSize = size;
        _isExporting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dossier exporté ($size)'),
            backgroundColor: AppTheme.validatedGreenDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.emergencyRedLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareDossier() async {
    if (_lastExportPath == null) return;
    final file = XFile(_lastExportPath!);
    await Share.shareXFiles(
      [file],
      subject: 'Santé Pocket – Dossier Médical',
      text: 'Voici mon dossier médical sécurisé Santé Pocket (.msh). Ouvrez-le avec l\'application Terminal Médecin sur PC.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Transfert P2P'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.blueGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header explanation card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlueDark.withValues(alpha: 0.5),
                    AppTheme.primaryBlueDark.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryBlueLight, size: 48),
                  const SizedBox(height: 12),
                  Text('Transfert Sécurisé',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Exportez votre dossier médical complet dans un fichier chiffré .msh, puis partagez-le directement avec votre médecin via WhatsApp, e-mail ou tout autre canal.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Steps
            _buildStep(1, 'Exporter', 'Génère un fichier .msh chiffré contenant tout votre dossier.',
                Icons.archive_rounded, AppTheme.primaryBlueLight),
            const SizedBox(height: 16),
            _buildStep(2, 'Partager', 'Envoyez le fichier via WhatsApp, Email ou Bluetooth.',
                Icons.share_rounded, AppTheme.validatedGreenLight),
            const SizedBox(height: 16),
            _buildStep(3, 'Consultation', 'Le médecin importe le fichier dans son logiciel.',
                Icons.medical_information_rounded, AppTheme.pendingOrangeLight),

            const SizedBox(height: 40),

            // P2P Direct Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/p2p'),
                icon: const Icon(Icons.wifi_tethering_rounded, color: Colors.white),
                label: const Text(
                  'Partage Direct (P2P – WiFi local)',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.pendingOrangeLight,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportDossier,
                icon: _isExporting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.file_download_rounded, color: Colors.white),
                label: Text(
                  _isExporting ? 'Export en cours...' : 'Exporter mon dossier (.msh)',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlueLight,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ),

            // Share button (visible after export)
            if (_lastExportPath != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.validatedGreenLight.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.validatedGreenLight.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.validatedGreenLight),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Fichier prêt',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Taille : $_lastExportSize',
                              style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareDossier,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('Partager via WhatsApp / Email',
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.validatedGreenLight,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('$number',
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
          Icon(icon, color: color.withValues(alpha: 0.5), size: 24),
        ],
      ),
    );
  }
}
