import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../p2p/models.dart';
import '../p2p/p2p_provider.dart';
import '../p2p/tcp_utils.dart';
import 'database_service.dart';
import 'msh_parser_service.dart';
import 'msh_generator_service.dart';
import 'encryption_service.dart';
import 'user_profile_service.dart';
import 'wifi_manager_service.dart';

enum FlowType { receiveFromPatient, returnToPatient }

enum FlowStatus {
  idle,
  scanningWifi,         // "Recherche du patient..."
  connectingWifi,       // "Connexion au hotspot du patient..."
  wifiConnected,        // "Connecté au réseau du patient"
  discoveringDevice,    // "Recherche de l'appareil du patient..."
  deviceFound,          // "Patient trouvé !"
  transferring,         // "Transfert du dossier en cours..."
  showingQrCode,        // "Affichez ce QR Code au patient"
  waitingForConnection, // "En attente de connexion du patient..."
  completed,            // "Transfert terminé !"
  error,                // "Une erreur est survenue"
}

class TransferState {
  final FlowType? flowType;
  final FlowStatus status;
  final Map<String, dynamic>? patientRecord;
  final String? localIp;
  final String? remoteIp;
  final int port;
  final String? currentTransferFilename;
  final double? transferProgress;
  final String? errorMessage;
  final String? qrCodeData;
  final String? pairedPatientName;
  final String? pairedPatientUuid;

  TransferState({
    this.flowType,
    this.status = FlowStatus.idle,
    this.patientRecord,
    this.localIp,
    this.remoteIp,
    this.port = 9876,
    this.currentTransferFilename,
    this.transferProgress,
    this.errorMessage,
    this.qrCodeData,
    this.pairedPatientName,
    this.pairedPatientUuid,
  });

  TransferState copyWith({
    FlowType? flowType,
    FlowStatus? status,
    Map<String, dynamic>? patientRecord,
    String? localIp,
    String? remoteIp,
    int? port,
    String? currentTransferFilename,
    double? transferProgress,
    String? errorMessage,
    String? qrCodeData,
    String? pairedPatientName,
    String? pairedPatientUuid,
  }) {
    return TransferState(
      flowType: flowType ?? this.flowType,
      status: status ?? this.status,
      patientRecord: patientRecord ?? this.patientRecord,
      localIp: localIp ?? this.localIp,
      remoteIp: remoteIp ?? this.remoteIp,
      port: port ?? this.port,
      currentTransferFilename: currentTransferFilename ?? this.currentTransferFilename,
      transferProgress: transferProgress ?? this.transferProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      pairedPatientName: pairedPatientName ?? this.pairedPatientName,
      pairedPatientUuid: pairedPatientUuid ?? this.pairedPatientUuid,
    );
  }
}

class DesktopSecureTransferService extends Notifier<TransferState> {
  StreamSubscription<ReceivedFile>? _fileSub;
  StreamSubscription<TransferProgress>? _progressSub;
  StreamSubscription<List<DiscoveredDevice>>? _discoverySub;
  
  final wifiManager = WifiManagerService();
  ServerSocket? _passiveSendServer;
  String? _connectedSsid;

  @override
  TransferState build() {
    ref.onDispose(() {
      resetState();
    });
    return TransferState();
  }

  /// Réinitialise l'état, ferme les serveurs et annule les abonnements.
  void resetState() {
    _cancelSubs();
    _stopPassiveSendServer();
    ref.read(discoveryServiceProvider).stopDiscovery();
    ref.read(fileTransferServiceProvider).stopServer();
    state = TransferState();
  }

  void _cancelSubs() {
    _fileSub?.cancel();
    _fileSub = null;
    _progressSub?.cancel();
    _progressSub = null;
    _discoverySub?.cancel();
    _discoverySub = null;
  }

  Future<void> _stopPassiveSendServer() async {
    await _passiveSendServer?.close();
    _passiveSendServer = null;
  }

  Future<void> _cleanupConnection() async {
    _cancelSubs();
    if (_connectedSsid != null) {
      await wifiManager.disconnectFromHotspot(_connectedSsid!);
      _connectedSsid = null;
    }
  }

  /// Flux 1 — Recevoir un patient
  Future<void> receiveFromPatient() async {
    resetState();
    state = TransferState(
      flowType: FlowType.receiveFromPatient,
      status: FlowStatus.scanningWifi,
    );

    try {
      // 1. Scanner le WiFi pour trouver le hotspot MediShare_*_v1 du patient
      String? ssid;
      for (int i = 0; i < 3; i++) {
        ssid = await wifiManager.scanForMediShareHotspot();
        if (ssid != null) break;
        await Future.delayed(const Duration(seconds: 5));
      }

      if (ssid == null) {
        state = state.copyWith(
          status: FlowStatus.error,
          errorMessage: "Aucun patient détecté. Assurez-vous que le patient a activé le partage P2P sur son mobile.",
        );
        return;
      }

      _connectedSsid = ssid;
      final uuid = WifiManagerService.extractUuidFromSsid(ssid);
      if (uuid == null) {
        throw Exception("SSID du patient invalide.");
      }

      // 2. Connexion au hotspot
      state = state.copyWith(status: FlowStatus.connectingWifi);
      final password = EncryptionService.deriveWifiPassword(uuid);
      final connectSuccess = await wifiManager.connectToHotspot(ssid, password);

      if (!connectSuccess) {
        state = state.copyWith(
          status: FlowStatus.error,
          errorMessage: "Échec de connexion au réseau WiFi du patient.",
        );
        return;
      }

      state = state.copyWith(status: FlowStatus.wifiConnected);

      // 3. Obtenir l'IP locale et configurer le serveur
      final ip = await _getLocalIp();
      state = state.copyWith(localIp: ip, status: FlowStatus.discoveringDevice);

      // 4. Dériver la clé AES
      final aesKey = EncryptionService.deriveAesKeyFromUuid(uuid);

      // 5. Démarrer le serveur TCP chiffré
      final transfer = ref.read(fileTransferServiceProvider);
      await transfer.startServer(port: kDefaultTcpPort, encryptionKey: aesKey);

      // 6. S'abonner aux événements de transfert de fichiers
      _fileSub = transfer.receivedFileStream.listen((receivedFile) async {
        try {
          final patientData = await MshParserService.parseMshFile(receivedFile.path);
          await DatabaseService.savePatient(patientData);

          state = state.copyWith(
            status: FlowStatus.completed,
            patientRecord: patientData,
            transferProgress: 1.0,
            remoteIp: receivedFile.senderName,
          );

          await _cleanupConnection();
        } catch (e) {
          state = state.copyWith(
            status: FlowStatus.error,
            errorMessage: "Erreur de traitement du fichier reçu : $e",
          );
        }
      });

      _progressSub = transfer.progressStream.listen((progress) {
        if (progress.status == TransferStatus.receiving) {
          state = state.copyWith(
            status: FlowStatus.transferring,
            currentTransferFilename: progress.filename,
            transferProgress: progress.progress,
          );
        } else if (progress.status == TransferStatus.error) {
          state = state.copyWith(
            status: FlowStatus.error,
            errorMessage: progress.errorMessage ?? "Erreur lors de la réception.",
          );
        }
      });

      // 7. Lancer la découverte pour identifier le patient
      final discovery = ref.read(discoveryServiceProvider);
      await discovery.startDiscovery();

      _discoverySub = discovery.devicesStream.listen((devices) {
        final device = devices.where((d) => d.uuid == uuid).firstOrNull;
        if (device != null) {
          state = state.copyWith(
            status: FlowStatus.deviceFound,
            pairedPatientName: device.name,
            pairedPatientUuid: device.uuid,
            remoteIp: device.ip,
          );
          _discoverySub?.cancel();
          _discoverySub = null;
        }
      });

    } catch (e) {
      state = state.copyWith(
        status: FlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Flux 2 — Retourner au patient (Envoyer le dossier mis à jour)
  Future<void> returnToPatient(Map<String, dynamic> record) async {
    resetState();
    state = TransferState(
      flowType: FlowType.returnToPatient,
      status: FlowStatus.scanningWifi,
      patientRecord: record,
    );

    try {
      // 1. Générer l'archive .msh immédiatement
      final mshPath = await MshGeneratorService.generateMshFromRecord(record);

      // 2. Scanner le WiFi pour trouver le hotspot
      String? ssid;
      for (int i = 0; i < 3; i++) {
        ssid = await wifiManager.scanForMediShareHotspot();
        if (ssid != null) break;
        await Future.delayed(const Duration(seconds: 5));
      }

      final transfer = ref.read(fileTransferServiceProvider);

      if (ssid != null) {
        // Flux 2.A : Hotspot trouvé -> Connexion automatique
        _connectedSsid = ssid;
        final uuid = WifiManagerService.extractUuidFromSsid(ssid);
        if (uuid == null) throw Exception("SSID du patient invalide.");

        state = state.copyWith(status: FlowStatus.connectingWifi);
        final password = EncryptionService.deriveWifiPassword(uuid);
        final connectSuccess = await wifiManager.connectToHotspot(ssid, password);

        if (!connectSuccess) {
          // Si la connexion auto échoue, on bascule en QR code fallback !
          await _fallbackToQrCode(mshPath);
          return;
        }

        state = state.copyWith(status: FlowStatus.wifiConnected);

        final aesKey = EncryptionService.deriveAesKeyFromUuid(uuid);
        state = state.copyWith(status: FlowStatus.discoveringDevice);

        // Découvrir l'IP du mobile
        final discovery = ref.read(discoveryServiceProvider);
        await discovery.startDiscovery();

        _discoverySub = discovery.devicesStream.listen((devices) async {
          final device = devices.where((d) => d.uuid == uuid).firstOrNull;
          if (device != null) {
            _discoverySub?.cancel();
            _discoverySub = null;

            state = state.copyWith(
              status: FlowStatus.deviceFound,
              pairedPatientName: device.name,
              pairedPatientUuid: device.uuid,
              remoteIp: device.ip,
            );

            // Envoyer le fichier
            state = state.copyWith(status: FlowStatus.transferring, transferProgress: 0.0);
            
            _progressSub = transfer.progressStream.listen((progress) {
              if (progress.status == TransferStatus.sending) {
                state = state.copyWith(
                  currentTransferFilename: progress.filename,
                  transferProgress: progress.progress,
                );
              } else if (progress.status == TransferStatus.error) {
                state = state.copyWith(
                  status: FlowStatus.error,
                  errorMessage: progress.errorMessage ?? "Erreur lors de l'envoi.",
                );
              }
            });

            try {
              await transfer.sendFile(
                ip: device.ip,
                file: File(mshPath),
                port: kDefaultTcpPort,
                encryptionKey: aesKey,
              );
              state = state.copyWith(status: FlowStatus.completed, transferProgress: 1.0);
              await _cleanupConnection();
            } catch (e) {
              state = state.copyWith(status: FlowStatus.error, errorMessage: e.toString());
            }
          }
        });
      } else {
        // Flux 2.B : Hotspot non trouvé -> QR Code Fallback
        await _fallbackToQrCode(mshPath);
      }
    } catch (e) {
      state = state.copyWith(
        status: FlowStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Initialise le serveur passif pour le QR Code fallback (port 9878)
  Future<void> _fallbackToQrCode(String mshPath) async {
    state = state.copyWith(status: FlowStatus.showingQrCode);
    try {
      final localIp = await _getLocalIp();
      final myUuid = await UserProfileService.getDoctorUuid();
      final qrSessionKey = EncryptionService.generateSessionKey();
      
      // Démarrer notre serveur passif sur le port 9878 pour l'envoi
      _passiveSendServer = await ServerSocket.bind(InternetAddress.anyIPv4, 9878);
      
      final qrPayload = "$localIp:9878:$myUuid:${base64.encode(qrSessionKey)}";
      
      state = state.copyWith(
        status: FlowStatus.waitingForConnection,
        qrCodeData: qrPayload,
        localIp: localIp,
        port: 9878,
      );

      _passiveSendServer!.listen((socket) async {
        state = state.copyWith(status: FlowStatus.transferring, transferProgress: 0.0);
        
        final transfer = ref.read(fileTransferServiceProvider);
        _progressSub = transfer.progressStream.listen((progress) {
          if (progress.status == TransferStatus.sending) {
            state = state.copyWith(
              currentTransferFilename: progress.filename,
              transferProgress: progress.progress,
            );
          }
        });

        try {
          await transfer.sendFileToSocket(
            socket: socket,
            file: File(mshPath),
            encryptionKey: qrSessionKey,
          );
          state = state.copyWith(status: FlowStatus.completed, transferProgress: 1.0);
        } catch (e) {
          state = state.copyWith(status: FlowStatus.error, errorMessage: "Échec du transfert QR : $e");
        } finally {
          socket.destroy();
          await _stopPassiveSendServer();
        }
      }, onError: (err) {
        state = state.copyWith(status: FlowStatus.error, errorMessage: "Erreur serveur : $err");
      });
    } catch (e) {
      state = state.copyWith(status: FlowStatus.error, errorMessage: "Impossible d'initier le partage QR : $e");
    }
  }

  /// Arrête et nettoie le transfert en cours
  Future<void> cancelTransfer() async {
    resetState();
    if (_connectedSsid != null) {
      await wifiManager.disconnectFromHotspot(_connectedSsid!);
      _connectedSsid = null;
    }
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
