library;

/// Modèles de données pour le système P2P.
/// Aucune dépendance Flutter — pur Dart.

/// Appareil découvert sur le réseau local.
class DiscoveredDevice {
  final String uuid;
  final String name;
  final String type; // 'mobile' ou 'pc'
  final String ip;
  final int tcpPort;
  DateTime lastSeen;

  DiscoveredDevice({
    required this.uuid,
    required this.name,
    required this.type,
    required this.ip,
    required this.tcpPort,
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(lastSeen).inSeconds > 15;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  @override
  String toString() => 'DiscoveredDevice($name, $type, $ip:$tcpPort)';
}

/// État d'un transfert.
enum TransferStatus {
  waiting,
  sending,
  receiving,
  verifying,
  done,
  error,
}

/// Progression d'un transfert en cours.
class TransferProgress {
  final String filename;
  final int bytesTransferred;
  final int totalBytes;
  final TransferStatus status;
  final String? errorMessage;

  const TransferProgress({
    required this.filename,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.status,
    this.errorMessage,
  });

  double get progress =>
      totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;

  String get progressPercent =>
      '${(progress * 100).toStringAsFixed(1)}%';

  TransferProgress copyWith({
    String? filename,
    int? bytesTransferred,
    int? totalBytes,
    TransferStatus? status,
    String? errorMessage,
  }) {
    return TransferProgress(
      filename: filename ?? this.filename,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Fichier reçu avec succès.
class ReceivedFile {
  final String path;
  final String filename;
  final int size;
  final String senderName;
  final DateTime receivedAt;

  const ReceivedFile({
    required this.path,
    required this.filename,
    required this.size,
    required this.senderName,
    required this.receivedAt,
  });
}

/// Erreur de transfert.
class TransferError {
  final String message;
  final bool isRecoverable;

  const TransferError({
    required this.message,
    this.isRecoverable = false,
  });

  @override
  String toString() => 'TransferError($message)';
}
