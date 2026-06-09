import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bonsoir/bonsoir.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../services/user_profile_service.dart';
import 'models.dart';
import 'tcp_utils.dart';

/// Service de découverte d'appareils via mDNS (Bonsoir) et UDP Broadcast.
class DiscoveryService {
  // mDNS (Principal)
  BonsoirBroadcast? _bonsoirBroadcast;
  BonsoirDiscovery? _bonsoirDiscovery;

  // UDP (Fallback)
  RawDatagramSocket? _socket;
  Timer? _broadcastTimer;
  Timer? _expiryTimer;

  String? _myUuid;
  String? _deviceName;
  late final String _deviceType;

  final Map<String, DiscoveredDevice> _devices = {};
  final _devicesController = StreamController<List<DiscoveredDevice>>.broadcast();

  /// Stream émettant la liste des appareils découverts actifs en temps réel.
  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  /// Liste actuelle des appareils actifs découverts.
  List<DiscoveredDevice> get currentDevices =>
      _devices.values.where((d) => !d.isExpired).toList();

  DiscoveryService() {
    _deviceType = Platform.isAndroid ? 'mobile' : 'pc';
  }

  /// Initialise et démarre la découverte d'appareils (mDNS + UDP).
  Future<void> startDiscovery({int udpPort = kDefaultUdpPort}) async {
    if (_socket != null || _bonsoirBroadcast != null) return;

    // 1. Obtenir ou générer l'UUID unique de cet appareil
    _myUuid = await UserProfileService.getUserUuid();

    // 2. Récupérer le nom de l'appareil
    _deviceName = await UserProfileService.getUserName() ?? await _getDeviceName();

    try {
      // --- mDNS BROADCAST ---
      final service = BonsoirService(
        name: _deviceName!,
        type: '_medishare._tcp',
        port: kDefaultTcpPort,
        attributes: {
          'uuid': _myUuid!,
          'type': _deviceType,
        },
      );
      _bonsoirBroadcast = BonsoirBroadcast(service: service);
      await _bonsoirBroadcast!.ready;
      await _bonsoirBroadcast!.start();

      // --- mDNS DISCOVERY ---
      _bonsoirDiscovery = BonsoirDiscovery(type: '_medishare._tcp');
      await _bonsoirDiscovery!.ready;
      _bonsoirDiscovery!.eventStream!.listen(_handleBonsoirEvent);
      await _bonsoirDiscovery!.start();

      // --- UDP BROADCAST (Fallback) ---
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        udpPort,
        reuseAddress: true,
        reusePort: true,
      );
      _socket!.broadcastEnabled = true;

      // 4. Écouter les messages entrants
      _socket!.listen(
        _handlePacket,
        onError: (error) {
          stopDiscovery();
        },
      );

      // 5. Lancer le broadcast périodique
      _broadcastTimer = Timer.periodic(
        const Duration(seconds: kBroadcastIntervalSeconds),
        (_) => _broadcastPresence(udpPort),
      );

      _broadcastPresence(udpPort);

      // 6. Lancer le nettoyage des appareils expirés
      _expiryTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        final initialLength = _devices.length;
        _devices.removeWhere((uuid, device) => device.isExpired);
        if (_devices.length != initialLength) {
          _notifyDevices();
        }
      });

    } catch (e) {
      stopDiscovery();
      rethrow;
    }
  }

  /// Arrête la découverte et libère les ressources.
  void stopDiscovery() {
    _bonsoirBroadcast?.stop();
    _bonsoirBroadcast = null;

    _bonsoirDiscovery?.stop();
    _bonsoirDiscovery = null;

    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    _socket?.close();
    _socket = null;

    _devices.clear();
    _notifyDevices();
  }

  void _handleBonsoirEvent(BonsoirDiscoveryEvent event) {
    if (event.type == BonsoirDiscoveryEventType.discoveryServiceResolved) {
      final service = event.service;
      if (service is ResolvedBonsoirService) {
        final attributes = service.attributes;
        if (attributes == null || attributes['uuid'] == _myUuid) return;

        final uuid = attributes['uuid'];
        final type = attributes['type'] ?? 'unknown';
        final ip = service.host;

        if (uuid != null && ip != null) {
          _devices[uuid] = DiscoveredDevice(
            uuid: uuid,
            name: service.name,
            type: type,
            ip: ip,
            tcpPort: service.port,
            lastSeen: DateTime.now(),
          );
          _notifyDevices();
        }
      }
    } else if (event.type == BonsoirDiscoveryEventType.discoveryServiceLost) {
      final service = event.service;
      if (service != null) {
        final attributes = service.attributes;
        if (attributes != null) {
          final uuid = attributes['uuid'];
          if (uuid != null) {
            _devices.remove(uuid);
            _notifyDevices();
          }
        }
      }
    }
  }

  /// Envoie un paquet UDP Broadcast (Fallback).
  void _broadcastPresence(int udpPort) {
    if (_socket == null || _myUuid == null || _deviceName == null) return;

    try {
      final payload = jsonEncode({
        'uuid': _myUuid,
        'name': _deviceName,
        'type': _deviceType,
        'tcpPort': kDefaultTcpPort,
      });

      final bytes = utf8.encode(payload);
      
      _socket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        udpPort,
      );
    } catch (_) {
    }
  }

  /// Gère les paquets UDP reçus.
  void _handlePacket(RawSocketEvent event) {
    if (event != RawSocketEvent.read || _socket == null) return;

    final datagram = _socket!.receive();
    if (datagram == null) return;

    try {
      final dataStr = utf8.decode(datagram.data);
      final json = jsonDecode(dataStr) as Map<String, dynamic>;

      final uuid = json['uuid'] as String?;
      final name = json['name'] as String?;
      final type = json['type'] as String?;
      final tcpPort = json['tcpPort'] as int?;
      final ip = datagram.address.address;

      if (uuid != null && uuid != _myUuid && name != null && type != null && tcpPort != null) {
        final device = DiscoveredDevice(
          uuid: uuid,
          name: name,
          type: type,
          ip: ip,
          tcpPort: tcpPort,
          lastSeen: DateTime.now(),
        );

        _devices[uuid] = device;
        _notifyDevices();
      }
    } catch (_) {
    }
  }

  void _notifyDevices() {
    final activeDevices = _devices.values.where((d) => !d.isExpired).toList();
    _devicesController.add(activeDevices);
  }

  /// Récupère le nom de l'appareil.
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return macInfo.computerName;
      }
    } catch (_) {}
    return Platform.localHostname;
  }
}
