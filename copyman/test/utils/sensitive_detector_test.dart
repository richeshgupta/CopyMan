import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/utils/sensitive_detector.dart';

void main() {
  group('SensitiveDetector', () {
    test('detects AWS access keys', () {
      expect(SensitiveDetector.isSensitive('AKIAIOSFODNN7EXAMPLE'), isTrue);
    });

    test('detects GitHub personal tokens', () {
      expect(
        SensitiveDetector.isSensitive(
            'ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij'),
        isTrue,
      );
    });

    test('detects GitHub secret tokens', () {
      expect(
        SensitiveDetector.isSensitive(
            'ghs_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij'),
        isTrue,
      );
    });

    test('detects SSH private keys', () {
      expect(
        SensitiveDetector.isSensitive('-----BEGIN RSA PRIVATE KEY-----'),
        isTrue,
      );
      expect(
        SensitiveDetector.isSensitive('-----BEGIN OPENSSH PRIVATE KEY-----'),
        isTrue,
      );
    });

    test('detects JWTs', () {
      expect(
        SensitiveDetector.isSensitive(
            'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U'),
        isTrue,
      );
    });

    test('detects password patterns', () {
      expect(SensitiveDetector.isSensitive('password: mysecret123'), isTrue);
      expect(SensitiveDetector.isSensitive('api_key=abc123def'), isTrue);
      expect(SensitiveDetector.isSensitive('SECRET: super_secret'), isTrue);
    });

    test('detects database connection strings', () {
      expect(
        SensitiveDetector.isSensitive(
            'postgresql://user:pass@localhost:5432/db'),
        isTrue,
      );
      expect(
        SensitiveDetector.isSensitive('mongodb://admin:secret@host/db'),
        isTrue,
      );
    });

    test('does not flag normal text', () {
      expect(SensitiveDetector.isSensitive('Hello, world!'), isFalse);
      expect(
          SensitiveDetector.isSensitive('Just a regular clipboard entry'),
          isFalse);
      expect(SensitiveDetector.isSensitive('https://example.com'), isFalse);
    });
  });
}
