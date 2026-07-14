import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'encryption_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String _hashKey = 'master_password_hash';
  static const String _biometricWrappingKey = 'biometric_wrapping_salt_key_98765';

  final LocalAuthentication _localAuth = LocalAuthentication();
  
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
      // Auto enable biometrics setup when setting up password
      await enableBiometrics(password);
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
      // Auto update biometric payload to keep it fresh
      await enableBiometrics(password);
      return true;
    }
    return false;
  }

  /// Clears the master password from memory (logout).
  void clearSession() {
    _masterPassword = null;
  }

  // --- Biometric Authentication Actions ---

  /// Checks if biometrics are supported and set up on this device.
  Future<bool> canAuthenticateWithBiometrics() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  /// Checks if biometric login has been enabled in app settings.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  /// Encrypts and wraps the master password with a constant local key and registers it.
  Future<void> enableBiometrics(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = EncryptionService.encrypt(password, _biometricWrappingKey);
    await prefs.setString('biometric_encrypted_master_pass', encrypted);
    await prefs.setBool('biometric_enabled', true);
  }

  /// Disables biometric login.
  Future<void> disableBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_encrypted_master_pass');
    await prefs.setBool('biometric_enabled', false);
  }

  /// Authenticates using biometrics, retrieves and decrypts the master password.
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Gunakan sidik jari untuk masuk ke Password Manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        final encryptedMaster = prefs.getString('biometric_encrypted_master_pass');
        if (encryptedMaster != null) {
          _masterPassword = EncryptionService.decrypt(encryptedMaster, _biometricWrappingKey);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
