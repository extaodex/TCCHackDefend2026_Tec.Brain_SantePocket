import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'tcp_utils.dart';

/// Service de transfert de fichiers TCP P2P.
/// Supporte l'envoi et la réception, en tant que client ou serveur.
class FileTransferService {
  ServerSocket? _serverSocket;
  bool _isServerRunning = false;
  Uint8List? _serverEncryptionKey;

  final _progressController = StreamController<TransferProgress>.broadcast();
  final _receivedFileController = StreamController<ReceivedFile>.broadcast();

  Stream<TransferProgress> get progressStream => _progressController.stream;
  Stream<ReceivedFile> get receivedFileStream => _receivedFileController.stream;

  bool get isServerRunning => _isServerRunning;

  // --- SERVEUR ---

  Future<void> startServer({int port = kDefaultTcpPort, Uint8List? encryptionKey}) async {
    if (_isServerRunning) return;
    _serverEncryptionKey = encryptionKey;
    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
      _isServerRunning = true;
      _serverSocket!.listen((socket) => receiveFileFromSocket(socket, encryptionKey: _serverEncryptionKey));
    } catch (e) {
      _isServerRunning = false;
      rethrow;
    }
  }

  Future<void> stopServer() async {
    await _serverSocket?.close();
    _serverSocket = null;
    _serverEncryptionKey = null;
    _isServerRunning = false;
  }

  // --- CLIENT ---

  Future<void> sendFile({
    required String ip,
    required File file,
    int port = kDefaultTcpPort,
    Uint8List? encryptionKey,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      await sendFileToSocket(socket: socket, file: file, encryptionKey: encryptionKey);
    } finally {
      socket?.destroy();
    }
  }

  Future<void> receiveFile({
    required String ip,
    int port = kDefaultTcpPort,
    Uint8List? encryptionKey,
  }) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      await receiveFileFromSocket(socket, encryptionKey: encryptionKey);
    } finally {
      socket?.destroy();
    }
  }

  // --- LOGIQUE COMMUNE ---

  Future<void> sendFileToSocket({
    required Socket socket,
    required File file,
    Uint8List? encryptionKey,
  }) async {
    final filename = p.basename(file.path);
    final totalSize = await file.length();
    final reader = ExactReader(socket);
    
    try {
      _progressController.add(TransferProgress(filename: filename, bytesTransferred: 0, totalBytes: totalSize, status: TransferStatus.sending));

      // 1. Métadonnées
      final metadataBytes = encodeFileMetadata(filename: filename, size: totalSize, mime: _getMimeType(filename));
      await writeEncrypted(socket, metadataBytes, encryptionKey);

      // 2. Chunks
      final raf = await file.open(mode: FileMode.read);
      int bytesTransferred = 0;
      while (bytesTransferred < totalSize) {
        final currentPos = await raf.position();
        final chunk = await raf.read(kChunkSize);
        if (chunk.isEmpty) break;

        final chunkData = Uint8List.fromList(chunk);
        final crc32 = computeCrc32(chunkData);
        final compressed = compressZlib(chunkData);

        final chunkPayload = BytesBuilder();
        chunkPayload.add(encodeUint32(crc32));
        chunkPayload.add(encodeUint32(compressed.length));
        chunkPayload.add(compressed);

        await writeEncrypted(socket, chunkPayload.toBytes(), encryptionKey);

        // ACK du chunk
        final ackBytes = await readDecrypted(reader, encryptionKey);
        if (utf8.decode(ackBytes) == 'ER') {
          await raf.setPosition(currentPos);
          continue;
        }

        bytesTransferred += chunk.length;
        _progressController.add(TransferProgress(filename: filename, bytesTransferred: bytesTransferred, totalBytes: totalSize, status: TransferStatus.sending));
      }
      await raf.close();

      // 3. ACK Final
      final finalAckBytes = await readDecrypted(reader, encryptionKey);
      if (utf8.decode(finalAckBytes) != 'OK') throw Exception('Erreur finale signalée par le destinataire.');
      
      _progressController.add(TransferProgress(filename: filename, bytesTransferred: totalSize, totalBytes: totalSize, status: TransferStatus.done));
    } catch (e) {
      _progressController.add(TransferProgress(filename: filename, bytesTransferred: 0, totalBytes: totalSize, status: TransferStatus.error, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<void> receiveFileFromSocket(Socket socket, {Uint8List? encryptionKey}) async {
    final reader = ExactReader(socket);
    String filename = 'inconnu';
    int totalSize = 0;
    RandomAccessFile? raf;
    File? tempFile;

    try {
      final metaBytes = await readDecrypted(reader, encryptionKey);
      final metadata = decodeFileMetadata(metaBytes);
      filename = metadata['filename'] ?? 'inconnu';
      totalSize = metadata['size'] ?? 0;

      _progressController.add(TransferProgress(filename: filename, bytesTransferred: 0, totalBytes: totalSize, status: TransferStatus.receiving));

      final tempDir = await getTemporaryDirectory();
      tempFile = File(p.join(tempDir.path, 'p2p_${DateTime.now().millisecondsSinceEpoch}_$filename'));
      raf = await tempFile.open(mode: FileMode.write);

      int bytesReceived = 0;
      while (bytesReceived < totalSize) {
        try {
          final payload = await readDecrypted(reader, encryptionKey);
          final expectedCrc = decodeUint32(payload.sublist(0, 4));
          final compressed = payload.sublist(8);
          final decompressed = decompressZlib(compressed);

          if (computeCrc32(decompressed) != expectedCrc) {
            await writeEncrypted(socket, utf8.encode('ER'), encryptionKey);
            continue;
          }

          await raf.writeFrom(decompressed);
          bytesReceived += decompressed.length;
          await writeEncrypted(socket, utf8.encode('OK'), encryptionKey);

          _progressController.add(TransferProgress(filename: filename, bytesTransferred: bytesReceived, totalBytes: totalSize, status: TransferStatus.receiving));
        } catch (e) {
          await writeEncrypted(socket, utf8.encode('ER'), encryptionKey);
          rethrow;
        }
      }
      await raf.close();

      final appDir = await getApplicationDocumentsDirectory();
      final finalPath = p.join(appDir.path, filename);
      await tempFile.rename(finalPath);

      await writeEncrypted(socket, utf8.encode('OK'), encryptionKey);
      _progressController.add(TransferProgress(filename: filename, bytesTransferred: totalSize, totalBytes: totalSize, status: TransferStatus.done));
      _receivedFileController.add(ReceivedFile(path: finalPath, filename: filename, size: totalSize, senderName: socket.remoteAddress.address, receivedAt: DateTime.now()));
    } catch (e) {
      _progressController.add(TransferProgress(filename: filename, bytesTransferred: 0, totalBytes: totalSize, status: TransferStatus.error, errorMessage: e.toString()));
      try { await writeEncrypted(socket, utf8.encode('ER'), encryptionKey); } catch (_) {}
    } finally {
      await reader.cancel();
    }
  }

  String _getMimeType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    if (ext == '.pdf') return 'application/pdf';
    if (ext == '.msh') return 'application/octet-stream';
    return 'application/octet-stream';
  }
}
