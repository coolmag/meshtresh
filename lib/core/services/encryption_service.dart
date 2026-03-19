import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

/// Service responsible for end-to-end encryption of messages
class EncryptionService {
  final _logger = Logger();

  /// Generates a deterministic 32-byte key based on the sender and recipient IDs.
  /// This ensures both parties can generate the same symmetric key without prior handshake.
  /// In a real-world scenario, this would use ECDH (Elliptic-curve Diffie-Hellman)
  /// with public/private key pairs. For this mesh POC, we derive a shared secret
  /// from the unique device IDs.
  encrypt.Key _getSharedKey(String userA, String userB) {
    // Sort IDs so both users generate the exact same string
    final users = [userA, userB]..sort();
    final combined = users.join(':');
    final bytes = utf8.encode(combined);
    // sha256 produces exactly 32 bytes (256 bits), perfect for AES-256
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts message content using AES-256-CBC
  String encryptMessage(String content, String senderId, String recipientId) {
    try {
      final key = _getSharedKey(senderId, recipientId);
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // We use AES in CBC mode with PKCS7 padding (default in encrypt package)
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      final encrypted = encrypter.encrypt(content, iv: iv);
      // Format: Base64(IV) : Base64(Ciphertext)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      _logger.e('Encryption failed: $e');
      // If encryption fails, return original to prevent complete failure, 
      // but in production we should throw an error.
      return content; 
    }
  }

  /// Decrypts message content using AES-256-CBC
  String decryptMessage(String encryptedContent, String senderId, String recipientId) {
    try {
      final parts = encryptedContent.split(':');
      if (parts.length != 2) {
        _logger.w('Invalid encrypted payload format');
        return encryptedContent;
      }

      final key = _getSharedKey(senderId, recipientId);
      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (e) {
      _logger.e('Decryption failed: $e');
      return '[ОШИБКА ДЕШИФРОВКИ]';
    }
  }
}
