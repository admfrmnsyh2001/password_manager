import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String _hashKey = 'master_password_hash';
  
  // In-memory storage for the active master password (never written to disk)
  String? _masterPassword;

  String? get activeMasterPassword => _masterPassword;

  /// Hashes a password using SHA-256.
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Checks if a master password has already been set.
  Future<bool> hasMasterPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_hashKey);
  }

  /// Sets a new master password by storing its hash on disk.
  /// Also caches the raw password in memory for active session.
  Future<bool> setMasterPassword(String password) async {
    if (password.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPassword(password);
    final success = await prefs.setString(_hashKey, hash);
    if (success) {
      _masterPassword = password;
    }
    return success;
  }

  /// Verifies if the entered password matches the stored hash.
  /// Caches the raw password in memory if successful.
  Future<bool> verifyMasterPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString(_hashKey);
    if (storedHash == null) return false;

    final inputHash = _hashPassword(password);
    if (storedHash == inputHash) {
      _masterPassword = password;
      return true;
    }
    return false;
  }

  /// Clears the master password from memory (logout).
  void clearSession() {
    _masterPassword = null;
  }
}
