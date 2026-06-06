import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import 'package:path/path.dart' as p;
import '../../core/theme/app_theme.dart';
import '../../core/p2p/permission_service.dart';
import '../../core/p2p/models.dart';
import 'p2p_provider.dart';
import 'sync_service.dart';

class P2PScreen extends ConsumerStatefulWidget {
  const P2PScreen({super.key});

  @override
  ConsumerState<P2PScreen> createState() => _P2PScreenState();
}

class _P2PScreenState extends ConsumerState<P2PScreen> with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  bool _hasPermissions = false;
  final List<ReceivedFile> _localReceivedFiles = [];

  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAndStart();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _setupAndStart() async {
    setState(() => _isInitializing = true);
    final granted = await PermissionService.requestAllPermissions();
    setState(() {
      _hasPermissions = granted;
      _isInitializing = false;
    });

    if (granted) {
      try {
        await ref.read(discoveryServiceProvider).startDiscovery();
        await ref.read(fileTransferServiceProvider).startServer();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur d\'initialisation réseau : $e'),
              backgroundColor: AppTheme.emergencyRedLight,
            ),
          );
        }
      }
    }
  }

  Future<void> _sendMedicalRecord(DiscoveredDevice device) async {
    try {
      // 1. Générer le fichier .msh
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du dossier clinique en cours...'),
          duration: Duration(seconds: 1),
        ),
      );
      final mshPath = await SyncService.generateMshArchive();
      final file = File(mshPath);

      // 2. Envoyer le fichier
      await ref.read(fileTransferServiceProvider).sendFile(
            ip: device.ip,
            file: file,
            port: device.tcpPort,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Dossier envoyé avec succès à ${device.name} !'),
            backgroundColor: AppTheme.validatedGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi : $e'),
            backgroundColor: AppTheme.emergencyRedLight,
          ),
        );
      }
    }
  }

  Future<void> _sendCustomFile(DiscoveredDevice device) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      // Envoyer le fichier
      await ref.read(fileTransferServiceProvider).sendFile(
            ip: device.ip,
            file: file,
            port: device.tcpPort,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fichier envoyé avec succès à ${device.name} !'),
            backgroundColor: AppTheme.validatedGreenDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de l\'envoi : $e'),
            backgroundColor: AppTheme.emergencyRedLight,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsyncValue = ref.watch(discoveredDevicesProvider);
    final progressAsyncValue = ref.watch(transferProgressProvider);

    // Écouter les nouveaux fichiers reçus
    ref.listen<AsyncValue<ReceivedFile>>(receivedFilesProvider, (_, next) {
      next.whenData((receivedFile) {
        setState(() {
          if (!_localReceivedFiles.any((f) => f.path == receivedFile.path)) {
            _localReceivedFiles.insert(0, receivedFile);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📥 Nouveau fichier reçu de ${receivedFile.senderName} : ${receivedFile.filename}'),
            backgroundColor: AppTheme.validatedGreenDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Partage Ultra-Rapide (P2P)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.blueGradient),
        ),
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlueLight))
          : !_hasPermissions
              ? _buildPermissionWarning()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTransferStatusCard(progressAsyncValue),
                      const SizedBox(height: 24),
                      Text(
                        'Appareils détectés à proximité',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildDiscoveredDevicesList(devicesAsyncValue),
                      const SizedBox(height: 32),
                      if (_localReceivedFiles.isNotEmpty) ...[
                        Text(
                          'Fichiers reçus',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildReceivedFilesList(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildPermissionWarning() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: AppTheme.emergencyRedLight),
          const SizedBox(height: 16),
          const Text(
            'Permissions requises',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'L\'accès au stockage et aux appareils à proximité est indispensable pour pouvoir transférer des fichiers sans connexion Internet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _setupAndStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlueLight,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Autoriser les accès', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTransferStatusCard(AsyncValue<TransferProgress> progressAsync) {
    return progressAsync.when(
      data: (progress) {
        if (progress.status == TransferStatus.done || progress.status == TransferStatus.waiting) {
          return _buildDefaultInfoCard();
        }

        final isSending = progress.status == TransferStatus.sending;
        final statusText = progress.status == TransferStatus.receiving
            ? 'Réception en cours...'
            : progress.status == TransferStatus.verifying
                ? 'Vérification de l\'intégrité...'
                : progress.status == TransferStatus.error
                    ? 'Erreur de transfert'
                    : 'Envoi en cours...';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: progress.status == TransferStatus.error
                  ? AppTheme.emergencyRedLight.withValues(alpha: 0.3)
                  : AppTheme.primaryBlueLight.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    progress.status == TransferStatus.error
                        ? Icons.error_outline_rounded
                        : isSending
                            ? Icons.upload_rounded
                            : Icons.download_rounded,
                    color: progress.status == TransferStatus.error
                        ? AppTheme.emergencyRedLight
                        : AppTheme.primaryBlueLight,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusText,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Text(
                    progress.progressPercent,
                    style: const TextStyle(color: AppTheme.primaryBlueLight, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                progress.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  backgroundColor: Colors.white10,
                  color: progress.status == TransferStatus.error
                      ? AppTheme.emergencyRedLight
                      : AppTheme.primaryBlueLight,
                  minHeight: 8,
                ),
              ),
              if (progress.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  progress.errorMessage!,
                  style: const TextStyle(color: AppTheme.emergencyRedLight, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
      error: (error, stack) => _buildDefaultInfoCard(),
      loading: () => _buildDefaultInfoCard(),
    );
  }

  Widget _buildDefaultInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlueDark.withValues(alpha: 0.3),
            AppTheme.primaryBlueDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_rounded, color: AppTheme.primaryBlueLight, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prêt à recevoir',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre appareil est visible pour les autres sous le même réseau local.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredDevicesList(AsyncValue<List<DiscoveredDevice>> devicesAsync) {
    return devicesAsync.when(
      data: (devices) {
        if (devices.isEmpty) {
          return _buildRadarSearching();
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: devices.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final device = devices[index];
            final isPc = device.type == 'pc';

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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isPc ? AppTheme.primaryBlueLight : AppTheme.validatedGreenLight).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isPc ? Icons.computer_rounded : Icons.phone_android_rounded,
                      color: isPc ? AppTheme.primaryBlueLight : AppTheme.validatedGreenLight,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'IP: ${device.ip}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.medical_services_rounded, color: AppTheme.pendingOrangeLight),
                        tooltip: 'Envoyer dossier médical',
                        onPressed: () => _sendMedicalRecord(device),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_present_rounded, color: AppTheme.primaryBlueLight),
                        tooltip: 'Envoyer fichier libre',
                        onPressed: () => _sendCustomFile(device),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.emergencyRedLight))),
      loading: () => _buildRadarSearching(),
    );
  }

  Widget _buildRadarSearching() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _radarController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryBlueLight.withValues(alpha: 1.0 - _radarController.value),
                    width: 2 + _radarController.value * 4,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBlueLight,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Recherche d\'appareils...',
            style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Assurez-vous que l\'autre appareil est sur le même réseau WiFi',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedFilesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _localReceivedFiles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final received = _localReceivedFiles[index];
        final sizeText = SyncService.formatFileSize(received.size);
        final isMsh = p.extension(received.filename) == '.msh';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isMsh ? AppTheme.pendingOrangeLight : AppTheme.primaryBlueLight).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isMsh ? Icons.medical_information_rounded : Icons.insert_drive_file_rounded,
                  color: isMsh ? AppTheme.pendingOrangeLight : AppTheme.primaryBlueLight,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      received.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Taille: $sizeText • De: ${received.senderName}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isMsh)
                IconButton(
                  icon: const Icon(Icons.file_open_rounded, color: AppTheme.validatedGreenLight),
                  tooltip: 'Importer dans l\'application',
                  onPressed: () {
                    // Logic for importing msh archive
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Importation non disponible sur mobile (utilisez l\'app PC)')),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
