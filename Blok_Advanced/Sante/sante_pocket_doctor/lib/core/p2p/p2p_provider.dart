import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'discovery_service.dart';
import 'file_transfer_service.dart';
import 'models.dart';

/// Provider pour l'instance unique de DiscoveryService.
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final service = DiscoveryService();
  ref.onDispose(() {
    service.stopDiscovery();
  });
  return service;
});

/// Provider pour l'instance unique de FileTransferService.
final fileTransferServiceProvider = Provider<FileTransferService>((ref) {
  final service = FileTransferService();
  ref.onDispose(() {
    service.stopServer();
  });
  return service;
});

/// StreamProvider pour écouter la liste des appareils découverts.
final discoveredDevicesProvider = StreamProvider<List<DiscoveredDevice>>((ref) {
  final discoveryService = ref.watch(discoveryServiceProvider);
  return discoveryService.devicesStream;
});

/// StreamProvider pour écouter le progrès des transferts.
final transferProgressProvider = StreamProvider<TransferProgress>((ref) {
  final transferService = ref.watch(fileTransferServiceProvider);
  return transferService.progressStream;
});

/// StreamProvider pour écouter les fichiers reçus.
final receivedFilesProvider = StreamProvider<ReceivedFile>((ref) {
  final transferService = ref.watch(fileTransferServiceProvider);
  return transferService.receivedFileStream;
});
