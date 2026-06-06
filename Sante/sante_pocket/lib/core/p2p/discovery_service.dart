import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'tcp_utils.dart';

/// Service de découverte d'appareils via UDP Broadcast.
class DiscoveryService {
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

  /// Initialise et démarre la découverte d'appareils.
  Future<void> startDiscovery({int udpPort = kDefaultUdpPort}) async {
    if (_socket != null) return;

    // 1. Obtenir ou générer l'UUID unique de cet appareil
    _myUuid = await _getOrCreateUuid();

    // 2. Récupérer le nom de l'appareil
    _deviceName = await _getDeviceName();

    try {
      // 3. Bind du socket UDP en écoute sur 0.0.0.0
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

      // 5. Lancer le broadcast périodique (toutes les 5 secondes)
      _broadcastTimer = Timer.periodic(
        const Duration(seconds: kBroadcastIntervalSeconds),
        (_) => _broadcastPresence(udpPort),
      );

      // Effectuer un premier broadcast immédiatement
      _broadcastPresence(udpPort);

      // 6. Lancer le nettoyage des appareils expirés (toutes les 2 secondes)
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
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    _socket?.close();
    _socket = null;

    _devices.clear();
    _notifyDevices();
  }

  /// Envoie un paquet UDP Broadcast contenant l'identité de l'appareil.
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
      
      // Diffusion vers l'adresse générale de broadcast
      _socket!.send(
        bytes,
        InternetAddress('255.255.255.255'),
        udpPort,
      );
    } catch (_) {
      // Ignorer silencieusement les erreurs d'envoi UDP temporaires
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

      // Filtrer son propre broadcast
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
      // Ignorer les paquets mal formés
    }
  }

  void _notifyDevices() {
    final activeDevices = _devices.values.where((d) => !d.isExpired).toList();
    _devicesController.add(activeDevices);
  }

  /// Récupère ou génère un UUID persistant pour l'appareil.
  Future<String> _getOrCreateUuid() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(p.join(appDir.path, '.p2p_device_uuid'));
      if (await file.exists()) {
        final uuidStr = (await file.readAsString()).trim();
        if (uuidStr.isNotEmpty) return uuidStr;
      }
      final newUuid = const Uuid().v4();
      await file.writeAsString(newUuid);
      return newUuid;
    } catch (_) {
      return const Uuid().v4();
    }
  }

  /// Récupère le nom de l'appareil.
  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // e.g., "Samsung SM-G991B"
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
