library;

/// Utilitaires TCP bas-niveau pour le protocole P2P.
/// Gère la lecture exacte d'octets (TCP fragmente !), l'encodage
/// big-endian, la compression zlib et le calcul CRC32.
///
/// Aucune dépendance Flutter — pur Dart + package archive.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import '../services/encryption_service.dart';

/// Taille d'un chunk de fichier en octets (64 KB).
const int kChunkSize = 65536;

/// Port TCP par défaut pour le transfert de fichiers.
const int kDefaultTcpPort = 9876;

/// Port UDP par défaut pour la découverte d'appareils.
const int kDefaultUdpPort = 9877;

/// Intervalle de broadcast UDP en secondes.
const int kBroadcastIntervalSeconds = 5;

/// Durée d'expiration d'un appareil en secondes.
const int kDeviceExpirySeconds = 15;

// ---------------------------------------------------------------------------
// Lecture TCP exacte — CRITIQUE : TCP fragmente, on doit boucler.
// ---------------------------------------------------------------------------

/// Lit exactement [count] octets depuis un [Stream<Uint8List>].
///
/// Accumule les morceaux TCP jusqu'à avoir exactement [count] octets.
/// Lève une [SocketException] si le stream se termine prématurément.
///
/// Retourne un tuple (les octets lus, le stream restant avec le surplus).
class ExactReader {
  final StreamIterator<Uint8List> _iterator;
  final List<int> _buffer = [];

  ExactReader(Stream<Uint8List> stream)
      : _iterator = StreamIterator(stream);

  /// Lit exactement [count] octets.
  Future<Uint8List> readExactly(int count) async {
    while (_buffer.length < count) {
      final hasMore = await _iterator.moveNext();
      if (!hasMore) {
        throw SocketException(
          'Connexion fermée prématurément. '
          'Attendu $count octets, reçu ${_buffer.length}.',
        );
      }
      _buffer.addAll(_iterator.current);
    }
    final result = Uint8List.fromList(_buffer.sublist(0, count));
    _buffer.removeRange(0, count);
    return result;
  }

  /// Lit tous les octets restants jusqu'à la fermeture du stream.
  Future<Uint8List> readRemaining() async {
    while (await _iterator.moveNext()) {
      _buffer.addAll(_iterator.current);
    }
    final result = Uint8List.fromList(_buffer);
    _buffer.clear();
    return result;
  }

  Future<void> cancel() async {
    await _iterator.cancel();
  }
}

// ---------------------------------------------------------------------------
// Encodage / Décodage Big-Endian 32 bits
// ---------------------------------------------------------------------------

/// Encode un entier 32 bits en 4 octets big-endian.
Uint8List encodeUint32(int value) {
  final data = ByteData(4);
  data.setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}

/// Décode 4 octets big-endian en entier 32 bits.
int decodeUint32(Uint8List bytes) {
  if (bytes.length < 4) {
    throw ArgumentError('Besoin de 4 octets, reçu ${bytes.length}');
  }
  return ByteData.sublistView(bytes).getUint32(0, Endian.big);
}

// ---------------------------------------------------------------------------
// Écriture socket avec flush
// ---------------------------------------------------------------------------

/// Écrit un entier 32 bits sur le socket et flush immédiatement.
Future<void> writeUint32(Socket socket, int value) async {
  socket.add(encodeUint32(value));
  await socket.flush();
}

/// Écrit des bytes bruts sur le socket et flush immédiatement.
Future<void> writeBytes(Socket socket, Uint8List data) async {
  socket.add(data);
  await socket.flush();
}

// ---------------------------------------------------------------------------
// CRC32 — Calculé sur les données BRUTES, AVANT compression.
// ---------------------------------------------------------------------------

/// Calcule le CRC32 d'un buffer de données.
int computeCrc32(Uint8List data) {
  // Le package archive fournit getCrc32 directement.
  return getCrc32(data);
}

// ---------------------------------------------------------------------------
// Compression / Décompression zlib
// ---------------------------------------------------------------------------

/// Compresse des données avec zlib.
Uint8List compressZlib(Uint8List data) {
  final encoder = ZLibEncoder();
  return Uint8List.fromList(encoder.encode(data));
}

/// Décompresse des données zlib.
Uint8List decompressZlib(Uint8List data) {
  final decoder = ZLibDecoder();
  return Uint8List.fromList(decoder.decodeBytes(data));
}

// ---------------------------------------------------------------------------
// Sérialisation JSON pour les métadonnées de transfert
// ---------------------------------------------------------------------------

/// Encode les métadonnées du fichier en JSON bytes.
Uint8List encodeFileMetadata({
  required String filename,
  required int size,
  required String mime,
}) {
  final json = jsonEncode({
    'filename': filename,
    'size': size,
    'mime': mime,
  });
  return Uint8List.fromList(utf8.encode(json));
}

/// Décode les métadonnées du fichier depuis des JSON bytes.
Map<String, dynamic> decodeFileMetadata(Uint8List data) {
  return jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
}

// ---------------------------------------------------------------------------
// Helpers d'écriture et de lecture chiffrées (AES-256)
// ---------------------------------------------------------------------------

/// Écrit des données chiffrées sur le socket.
Future<void> writeEncrypted(Socket socket, Uint8List data, Uint8List? key) async {
  if (key != null) {
    final encrypted = EncryptionService.encrypt(data, key);
    await writeUint32(socket, encrypted.length);
    await writeBytes(socket, encrypted);
  } else {
    await writeUint32(socket, data.length);
    await writeBytes(socket, data);
  }
}

/// Lit des données chiffrées depuis le reader.
Future<Uint8List> readDecrypted(ExactReader reader, Uint8List? key) async {
  final sizeBytes = await reader.readExactly(4);
  final size = decodeUint32(sizeBytes);
  final block = await reader.readExactly(size);
  if (key != null) {
    return EncryptionService.decrypt(block, key);
  }
  return block;
}
