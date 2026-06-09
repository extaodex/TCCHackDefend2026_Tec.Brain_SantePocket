import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../p2p/models.dart';
import '../p2p/discovery_service.dart';
import '../p2p/file_transfer_service.dart';
import '../p2p/tcp_utils.dart';
import 'encryption_service.dart';
import 'user_profile_service.dart';
import 'hotspot_service.dart';
import 'msh_parser_service.dart';

enum MobileFlowStatus {
  idle,
  enablingHotspot,
  hotspotActive,
  discoveringDoctor,
  doctorFound,
  connecting,
  transferring,
  scanningQr,
  completed,
  error,
}

class MobileTransferState {
  final MobileFlowStatus status;
  final String? doctorName;
  final String? doctorIp;
  final String? currentFilename;
  final double progress;
  final String? errorMessage;
  final String? hotspotSsid;
  final String? hotspotPassword;

  MobileTransferState({
    this.status = MobileFlowStatus.idle,
    this.doctorName,
    this.doctorIp,
    this.currentFilename,
    this.progress = 0.0,
    this.errorMessage,
    this.hotspotSsid,
    this.hotspotPassword,
  });

  MobileTransferState copyWith({
    MobileFlowStatus? status,
    String? doctorName,
    String? doctorIp,
    String? currentFilename,
    double? progress,
    String? errorMessage,
    String? hotspotSsid,
    String? hotspotPassword,
  }) {
    return MobileTransferState(
      status: status ?? this.status,
      doctorName: doctorName ?? this.doctorName,
      doctorIp: doctorIp ?? this.doctorIp,
      currentFilename: currentFilename ?? this.currentFilename,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      hotspotSsid: hotspotSsid ?? this.hotspotSsid,
      hotspotPassword: hotspotPassword ?? this.hotspotPassword,
    );
  }
}

class MobileSecureTransferService extends Notifier<MobileTransferState> {
  final DiscoveryService _discoveryService = DiscoveryService();
  final FileTransferService _fileTransferService = FileTransferService();
  StreamSubscription? _discoverySub;
  StreamSubscription? _progressSub;
  StreamSubscription? _fileSub;

  @override
  MobileTransferState build() {
    _fileSub = _fileTransferService.receivedFileStream.listen((receivedFile) async {
      try {
        await MshParserService.importMsh(receivedFile.path);
        state = state.copyWith(status: MobileFlowStatus.completed);
      } catch (e) {
        state = state.copyWith(status: MobileFlowStatus.error, errorMessage: "Échec de l'import : $e");
      }
    });

    ref.onDispose(() {
      _discoverySub?.cancel();
      _progressSub?.cancel();
      _fileSub?.cancel();
      _discoveryService.stopDiscovery();
    });

    return MobileTransferState();
  }

  Future<void> startFlux1(File fileToShare) async {
    state = state.copyWith(status: MobileFlowStatus.enablingHotspot);
    
    try {
      final hotspotInfo = await HotspotService.enableHotspot();
      if (hotspotInfo == null) {
        throw Exception("Impossible d'activer le hotspot WiFi.");
      }

      state = state.copyWith(
        status: MobileFlowStatus.hotspotActive,
        hotspotSsid: hotspotInfo['ssid'],
        hotspotPassword: hotspotInfo['password'],
      );

      state = state.copyWith(status: MobileFlowStatus.discoveringDoctor);
      await _discoveryService.startDiscovery();
      
      _discoverySub = _discoveryService.devicesStream.listen((devices) async {
        final doctor = devices.where((d) => d.type == 'pc').firstOrNull;
        if (doctor != null) {
          _discoverySub?.cancel();
          state = state.copyWith(
            status: MobileFlowStatus.doctorFound,
            doctorName: doctor.name,
            doctorIp: doctor.ip,
          );
          
          await _connectAndSend(doctor.ip, fileToShare, doctor.uuid);
        }
      });
    } catch (e) {
      state = state.copyWith(status: MobileFlowStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> startFlux2() async {
    state = state.copyWith(status: MobileFlowStatus.enablingHotspot);
    
    try {
      final hotspotInfo = await HotspotService.enableHotspot();
      state = state.copyWith(
        status: MobileFlowStatus.hotspotActive,
        hotspotSsid: hotspotInfo?['ssid'],
        hotspotPassword: hotspotInfo?['password'],
      );

      state = state.copyWith(status: MobileFlowStatus.discoveringDoctor);
      await _discoveryService.startDiscovery();

      bool doctorFound = false;
      _discoverySub = _discoveryService.devicesStream.listen((devices) async {
        final doctor = devices.where((d) => d.type == 'pc').firstOrNull;
        if (doctor != null) {
          doctorFound = true;
          _discoverySub?.cancel();
          state = state.copyWith(
            status: MobileFlowStatus.doctorFound,
            doctorName: doctor.name,
            doctorIp: doctor.ip,
          );
          
          await _connectAndReceive(doctor.ip, doctor.uuid);
        }
      });

      Future.delayed(const Duration(seconds: 15), () {
        if (!doctorFound && state.status == MobileFlowStatus.discoveringDoctor) {
          _discoverySub?.cancel();
          state = state.copyWith(status: MobileFlowStatus.scanningQr);
        }
      });

    } catch (e) {
      state = state.copyWith(status: MobileFlowStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> connectViaQr(String qrData) async {
    try {
      final parts = qrData.split(':');
      if (parts.length < 4) throw Exception("Format QR Code invalide.");

      final ip = parts[0];
      final port = int.parse(parts[1]);
      final uuid = parts[2];
      final key = base64.decode(parts[3]);

      state = state.copyWith(status: MobileFlowStatus.connecting, doctorIp: ip);
      await _connectAndReceive(ip, uuid, port: port, manualKey: key);
    } catch (e) {
      state = state.copyWith(status: MobileFlowStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> _connectAndSend(String ip, File file, String doctorUuid) async {
    state = state.copyWith(status: MobileFlowStatus.connecting);
    final aesKey = EncryptionService.deriveAesKeyFromUuid(doctorUuid);

    _progressSub = _fileTransferService.progressStream.listen((p) {
      state = state.copyWith(
        status: MobileFlowStatus.transferring,
        currentFilename: p.filename,
        progress: p.progress,
      );
    });

    try {
      await _fileTransferService.sendFile(
        ip: ip,
        file: file,
        encryptionKey: aesKey,
      );
      state = state.copyWith(status: MobileFlowStatus.completed);
    } catch (e) {
      state = state.copyWith(status: MobileFlowStatus.error, errorMessage: e.toString());
    } finally {
      await HotspotService.disableHotspot();
    }
  }

  Future<void> _connectAndReceive(String ip, String doctorUuid, {int port = kDefaultTcpPort, Uint8List? manualKey}) async {
    state = state.copyWith(status: MobileFlowStatus.connecting);
    final aesKey = manualKey ?? EncryptionService.deriveAesKeyFromUuid(doctorUuid);

    _progressSub = _fileTransferService.progressStream.listen((p) {
      state = state.copyWith(
        status: MobileFlowStatus.transferring,
        currentFilename: p.filename,
        progress: p.progress,
      );
    });

    try {
      await _fileTransferService.receiveFile(
        ip: ip,
        port: port,
        encryptionKey: aesKey,
      );
    } catch (e) {
      state = state.copyWith(status: MobileFlowStatus.error, errorMessage: e.toString());
    } finally {
      await HotspotService.disableHotspot();
    }
  }
}

final mobileTransferProvider = NotifierProvider<MobileSecureTransferService, MobileTransferState>(() => MobileSecureTransferService());
