import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../p2p/discovery_service.dart';
import '../p2p/file_transfer_service.dart';
import '../p2p/models.dart';
import '../p2p/p2p_provider.dart';
import '../p2p/tcp_utils.dart';
import 'database_service.dart';
import 'msh_parser_service.dart';

enum ConnectionStatus { idle, listening, connected, error }

class TransferState {
  final ConnectionStatus status;
  final Map<String, dynamic>? patientRecord;
  final String? localIp;
  final int port;
  final String? currentTransferFilename;
  final double? transferProgress;

  TransferState({
    this.status = ConnectionStatus.idle,
    this.patientRecord,
    this.localIp,
    this.port = 9876,
    this.currentTransferFilename,
    this.transferProgress,
  });

  TransferState copyWith({
    ConnectionStatus? status,
    Map<String, dynamic>? patientRecord,
    String? localIp,
    int? port,
    String? currentTransferFilename,
    double? transferProgress,
  }) {
    return TransferState(
      status: status ?? this.status,
      patientRecord: patientRecord ?? this.patientRecord,
      localIp: localIp ?? this.localIp,
      port: port ?? this.port,
      currentTransferFilename: currentTransferFilename ?? this.currentTransferFilename,
      transferProgress: transferProgress ?? this.transferProgress,
    );
  }
}

class DesktopSecureTransferService extends Notifier<TransferState> {
  StreamSubscription<ReceivedFile>? _fileSub;
  StreamSubscription<TransferProgress>? _progressSub;

  @override
  TransferState build() {
    ref.onDispose(() {
      _cancelSubs();
    });
    return TransferState();
  }

  void _cancelSubs() {
    _fileSub?.cancel();
    _fileSub = null;
    _progressSub?.cancel();
    _progressSub = null;
  }

  Future<void> startServer() async {
    try {
      final ip = await _getLocalIp();
      final DiscoveryService discovery = ref.read(discoveryServiceProvider);
      final FileTransferService transfer = ref.read(fileTransferServiceProvider);

      // S'assurer de nettoyer les anciens abonnements et connexions
      _cancelSubs();

      // Démarrage des serveurs TCP et UDP
      await transfer.startServer(port: kDefaultTcpPort);
      await discovery.startDiscovery(udpPort: kDefaultUdpPort);

      // Écouter les fichiers reçus
      _fileSub = transfer.receivedFileStream.listen((receivedFile) async {
        try {
          // Extraction et décodage de l'archive de santé .msh
          final patientData = await MshParserService.parseMshFile(receivedFile.path);
          
          // Sauvegarde automatique du dossier clinique consolidé dans SQLite
          await DatabaseService.savePatient(patientData);

          state = state.copyWith(
            status: ConnectionStatus.connected,
            patientRecord: patientData,
            transferProgress: 1.0,
          );
        } catch (e) {
          state = state.copyWith(status: ConnectionStatus.error);
        }
      });

      // Écouter la progression du transfert
      _progressSub = transfer.progressStream.listen((progress) {
        if (progress.status == TransferStatus.receiving || progress.status == TransferStatus.sending) {
          state = state.copyWith(
            status: ConnectionStatus.listening,
            currentTransferFilename: progress.filename,
            transferProgress: progress.progress,
          );
        } else if (progress.status == TransferStatus.error) {
          state = state.copyWith(status: ConnectionStatus.error);
        }
      });

      state = state.copyWith(status: ConnectionStatus.listening, localIp: ip, port: kDefaultTcpPort);
    } catch (e) {
      state = state.copyWith(status: ConnectionStatus.error);
    }
  }

  Future<void> stopServer() async {
    _cancelSubs();
    
    final DiscoveryService discovery = ref.read(discoveryServiceProvider);
    final FileTransferService transfer = ref.read(fileTransferServiceProvider);

    discovery.stopDiscovery();
    await transfer.stopServer();

    state = state.copyWith(status: ConnectionStatus.idle, currentTransferFilename: null, transferProgress: null);
  }

  Future<String> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (var interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('wlan') || name.contains('wi-fi') || name.contains('ethernet')) {
        return interface.addresses.first.address;
      }
    }
    return interfaces.isNotEmpty ? interfaces.first.addresses.first.address : '127.0.0.1';
  }
}

final secureTransferServiceProvider = NotifierProvider<DesktopSecureTransferService, TransferState>(() => DesktopSecureTransferService());
