import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  /// Génère une clé de session AES-256 de 32 octets aléatoires.
  static Uint8List generateSessionKey() {
    final random = Random.secure();
    final key = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// Dérive une clé de taille spécifiée à partir d'un UUID et d'un sel en utilisant PBKDF2-SHA256.
  static Uint8List deriveKey({
    required String password,
    required String salt,
    int iterations = 10000,
    int keyLength = 32,
  }) {
    final passwordBytes = utf8.encode(password) as Uint8List;
    final saltBytes = utf8.encode(salt) as Uint8List;
    
    final hmac = Hmac(sha256, passwordBytes);
    final key = BytesBuilder();
    int blockIndex = 1;
    
    while (key.length < keyLength) {
      final blockIndexBytes = ByteData(4)..setUint32(0, blockIndex, Endian.big);
      final saltAndIndex = Uint8List(saltBytes.length + 4);
      saltAndIndex.setRange(0, saltBytes.length, saltBytes);
      saltAndIndex.setRange(saltBytes.length, saltAndIndex.length, blockIndexBytes.buffer.asUint8List());
      
      var u = Uint8List.fromList(hmac.convert(saltAndIndex).bytes);
      var xorSum = Uint8List.fromList(u);
      
      for (int i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (int j = 0; j < xorSum.length; j++) {
          xorSum[j] ^= u[j];
        }
      }
      
      key.add(xorSum);
      blockIndex++;
    }
    
    return Uint8List.fromList(key.toBytes().sublist(0, keyLength));
  }

  /// Dérive le mot de passe WiFi WPA2 à partir de l'UUID du hotspot.
  static String deriveWifiPassword(String uuid) {
    final keyBytes = deriveKey(
      password: uuid,
      salt: "SantePocket2026_HotspotKey",
      iterations: 10000,
      keyLength: 16,
    );
    
    // Conversion en base62 pour avoir des caractères alphanumériques simples
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final result = StringBuffer();
    for (final byte in keyBytes) {
      result.write(chars[byte % chars.length]);
    }
    return result.toString();
  }

  /// Dérive une clé AES-256 de session à partir de l'UUID du hotspot.
  static Uint8List deriveAesKeyFromUuid(String uuid) {
    return deriveKey(
      password: uuid,
      salt: "SantePocket2026_AESKey",
      iterations: 10000,
      keyLength: 32,
    );
  }

  /// Chiffre les données avec la clé AES spécifiée.
  /// Format de sortie : [16 octets d'IV] + [données chiffrées]
  static Uint8List encrypt(Uint8List data, Uint8List keyBytes) {
    final key = enc.Key(keyBytes);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return Uint8List.fromList(result.toBytes());
  }

  /// Déchiffre les données avec la clé AES spécifiée.
  /// Format d'entrée : [16 octets d'IV] + [données chiffrées]
  static Uint8List decrypt(Uint8List encryptedData, Uint8List keyBytes) {
    if (encryptedData.length < 16) {
      throw ArgumentError("Données chiffrées invalides (trop courtes pour contenir l'IV).");
    }
    
    final key = enc.Key(keyBytes);
    final ivBytes = encryptedData.sublist(0, 16);
    final ciphertextBytes = encryptedData.sublist(16);
    
    final iv = enc.IV(ivBytes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final decrypted = encrypter.decryptBytes(enc.Encrypted(ciphertextBytes), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}
