import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'tcp_utils.dart';

/// Service de transfert de fichiers TCP P2P.
/// Gère l'envoi et la réception de fichiers via un protocole binaire structuré.
class FileTransferService {
  ServerSocket? _serverSocket;
  bool _isServerRunning = false;

  final _progressController = StreamController<TransferProgress>.broadcast();
  final _receivedFileController = StreamController<ReceivedFile>.broadcast();

  /// Stream des progrès de transfert (envoi et réception).
  Stream<TransferProgress> get progressStream => _progressController.stream;

  /// Stream des fichiers entièrement reçus.
  Stream<ReceivedFile> get receivedFileStream => _receivedFileController.stream;

  bool get isServerRunning => _isServerRunning;

  /// Démarre le serveur TCP pour écouter les fichiers entrants.
  Future<void> startServer({int port = kDefaultTcpPort}) async {
    if (_isServerRunning) return;

    try {
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port, shared: true);
      _isServerRunning = true;
      _serverSocket!.listen(
        _handleConnection,
        onError: (error) {
          _isServerRunning = false;
        },
        onDone: () {
          _isServerRunning = false;
        },
      );
    } catch (e) {
      _isServerRunning = false;
      rethrow;
    }
  }

  /// Arrête le serveur TCP.
  Future<void> stopServer() async {
    if (!_isServerRunning) return;
    await _serverSocket?.close();
    _serverSocket = null;
    _isServerRunning = false;
  }

  /// Envoie un fichier à un appareil distant.
  Future<void> sendFile({
    required String ip,
    required File file,
    int port = kDefaultTcpPort,
  }) async {
    final filename = p.basename(file.path);
    final totalSize = await file.length();
    
    _progressController.add(TransferProgress(
      filename: filename,
      bytesTransferred: 0,
      totalBytes: totalSize,
      status: TransferStatus.waiting,
    ));

    Socket? socket;
    RandomAccessFile? raf;

    try {
      socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 10));
      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: 0,
        totalBytes: totalSize,
        status: TransferStatus.sending,
      ));

      // 1. Envoyer les métadonnées (taille JSON sur 4 octets, puis le JSON)
      final metadataBytes = encodeFileMetadata(
        filename: filename,
        size: totalSize,
        mime: _getMimeType(filename),
      );

      await writeUint32(socket, metadataBytes.length);
      await writeBytes(socket, metadataBytes);

      // 2. Envoyer le fichier par chunks de 64 KB
      raf = await file.open(mode: FileMode.read);
      int bytesTransferred = 0;

      while (bytesTransferred < totalSize) {
        final chunk = await raf.read(kChunkSize);
        if (chunk.isEmpty) break;

        final chunkData = Uint8List.fromList(chunk);
        final crc32 = computeCrc32(chunkData);
        final compressed = compressZlib(chunkData);

        // Envoyer l'en-tête du chunk : CRC32 (4 octets), Taille compressée (4 octets)
        await writeUint32(socket, crc32);
        await writeUint32(socket, compressed.length);
        
        // Envoyer les données compressées
        await writeBytes(socket, compressed);

        bytesTransferred += chunk.length;

        _progressController.add(TransferProgress(
          filename: filename,
          bytesTransferred: bytesTransferred,
          totalBytes: totalSize,
          status: TransferStatus.sending,
        ));
      }

      await raf.close();
      raf = null;

      // 3. Attendre la réponse finale ("OK" ou "ER")
      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: totalSize,
        totalBytes: totalSize,
        status: TransferStatus.verifying,
      ));

      final reader = ExactReader(socket);
      final responseBytes = await reader.readExactly(2);
      final response = utf8.decode(responseBytes);

      if (response == 'OK') {
        _progressController.add(TransferProgress(
          filename: filename,
          bytesTransferred: totalSize,
          totalBytes: totalSize,
          status: TransferStatus.done,
        ));
      } else {
        throw Exception('Le destinataire a signalé une erreur lors de la réception.');
      }
    } catch (e) {
      if (raf != null) {
        try {
          await raf.close();
        } catch (_) {}
      }
      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: 0,
        totalBytes: totalSize,
        status: TransferStatus.error,
        errorMessage: e.toString(),
      ));
      rethrow;
    } finally {
      socket?.destroy();
    }
  }

  /// Gère une connexion TCP entrante (Réception).
  void _handleConnection(Socket socket) async {
    final reader = ExactReader(socket);
    String filename = 'inconnu';
    int totalSize = 0;
    String? tempFilePath;
    File? tempFile;
    RandomAccessFile? raf;

    try {
      // 1. Lire la taille des métadonnées (4 octets)
      final metaSizeBuf = await reader.readExactly(4);
      final metaSize = decodeUint32(metaSizeBuf);

      // 2. Lire les métadonnées JSON
      final metaBytes = await reader.readExactly(metaSize);
      final metadata = decodeFileMetadata(metaBytes);

      filename = metadata['filename'] as String? ?? 'fichier_inconnu';
      totalSize = metadata['size'] as int? ?? 0;

      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: 0,
        totalBytes: totalSize,
        status: TransferStatus.receiving,
      ));

      // 3. Préparer le fichier de destination temporaire
      final systemTempDir = await getTemporaryDirectory();
      tempFilePath = p.join(systemTempDir.path, 'transfer_${DateTime.now().millisecondsSinceEpoch}_$filename');
      tempFile = File(tempFilePath);
      raf = await tempFile.open(mode: FileMode.write);

      // 4. Recevoir les chunks
      int bytesReceived = 0;

      while (bytesReceived < totalSize) {
        // Lire CRC32 (4 octets)
        final crc32Buf = await reader.readExactly(4);
        final expectedCrc32 = decodeUint32(crc32Buf);

        // Lire taille compressée (4 octets)
        final compSizeBuf = await reader.readExactly(4);
        final compSize = decodeUint32(compSizeBuf);

        // Lire les données compressées
        final compressedData = await reader.readExactly(compSize);

        // Décompresser
        final decompressed = decompressZlib(compressedData);

        // Valider CRC32
        final actualCrc32 = computeCrc32(decompressed);
        if (actualCrc32 != expectedCrc32) {
          throw Exception('Erreur de validation CRC32 pour le chunk.');
        }

        // Écrire dans le fichier
        await raf.writeFrom(decompressed);
        bytesReceived += decompressed.length;

        _progressController.add(TransferProgress(
          filename: filename,
          bytesTransferred: bytesReceived,
          totalBytes: totalSize,
          status: TransferStatus.receiving,
        ));
      }

      await raf.close();
      raf = null;

      // 5. Déplacer le fichier temporaire vers le dossier final de l'application
      final appDir = await getApplicationDocumentsDirectory();
      
      // S'assurer que le nom de fichier est unique pour éviter d'écraser
      String finalPath = p.join(appDir.path, filename);
      int counter = 1;
      while (await File(finalPath).exists()) {
        final extension = p.extension(filename);
        final nameWithoutExt = p.basenameWithoutExtension(filename);
        finalPath = p.join(appDir.path, '${nameWithoutExt}_($counter)$extension');
        counter++;
      }

      final finalFile = await tempFile.rename(finalPath);

      // Répondre OK
      socket.add(utf8.encode('OK'));
      await socket.flush();

      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: totalSize,
        totalBytes: totalSize,
        status: TransferStatus.done,
      ));

      _receivedFileController.add(ReceivedFile(
        path: finalFile.path,
        filename: p.basename(finalFile.path),
        size: totalSize,
        senderName: socket.remoteAddress.address,
        receivedAt: DateTime.now(),
      ));

    } catch (e) {
      if (raf != null) {
        try {
          await raf.close();
        } catch (_) {}
      }
      if (tempFilePath != null) {
        try {
          final f = File(tempFilePath);
          if (await f.exists()) {
            await f.delete();
          }
        } catch (_) {}
      }

      _progressController.add(TransferProgress(
        filename: filename,
        bytesTransferred: 0,
        totalBytes: totalSize,
        status: TransferStatus.error,
        errorMessage: e.toString(),
      ));

      // Signaler l'erreur à l'émetteur
      try {
        socket.add(utf8.encode('ER'));
        await socket.flush();
      } catch (_) {}
      
    } finally {
      socket.destroy();
      await reader.cancel();
    }
  }

  String _getMimeType(String filename) {
    final ext = p.extension(filename).toLowerCase();
    switch (ext) {
      case '.msh':
        return 'application/octet-stream';
      case '.pdf':
        return 'application/pdf';
      case '.json':
        return 'application/json';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}
