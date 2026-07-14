import 'package:flutter_test/flutter_test.dart';
import 'package:password_manager/services/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    const masterPassword = 'super_secret_master_password_123';
    const plainText = 'MySecretPasswordToEncrypt!';

    test('Encryption and Decryption matches', () {
      final encrypted = EncryptionService.encrypt(plainText, masterPassword);
      
      // Encrypted string should not be equal to plainText
      expect(encrypted, isNot(equals(plainText)));
      // Encrypted string should contain a separator
      expect(encrypted.contains(':'), isTrue);

      final decrypted = EncryptionService.decrypt(encrypted, masterPassword);
      expect(decrypted, equals(plainText));
    });

    test('Decryption fails with wrong master password', () {
      final encrypted = EncryptionService.encrypt(plainText, masterPassword);
      
      expect(
        () => EncryptionService.decrypt(encrypted, 'wrong_master_password'),
        throwsFormatException,
      );
    });

    test('Empty text returns empty string', () {
      final encrypted = EncryptionService.encrypt('', masterPassword);
      expect(encrypted, equals(''));

      final decrypted = EncryptionService.decrypt('', masterPassword);
      expect(decrypted, equals(''));
    });

    test('Invalid format throws ArgumentError', () {
      expect(
        () => EncryptionService.decrypt('invalidformatwithoutcolon', masterPassword),
        throwsArgumentError,
      );
    });
  });
}
