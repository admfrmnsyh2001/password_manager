import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // Derive a 32-byte key from the master password using SHA-256
  static enc.Key _deriveKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts the plaintext using AES-256.
  /// Generates a random 16-byte IV, prepends it to the ciphertext as base64, separated by a colon.
  static String encrypt(String text, String masterPassword) {
    if (text.isEmpty) return '';
    final key = _deriveKey(masterPassword);
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(text, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the ciphertext using AES-256.
  /// Expects the input to be in the format 'IV_BASE64:CIPHERTEXT_BASE64'.
  static String decrypt(String encryptedText, String masterPassword) {
    if (encryptedText.isEmpty) return '';
    final parts = encryptedText.split(':');
    if (parts.length != 2) {
      throw ArgumentError('Invalid encrypted text format');
    }
    
    try {
      final key = _deriveKey(masterPassword);
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw FormatException('Decryption failed: wrong password or corrupted data');
    }
  }
}
