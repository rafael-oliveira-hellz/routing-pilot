import 'package:flutter_test/flutter_test.dart';
import 'package:pilot_app/core/util/validators.dart';

void main() {
  group('isValidEmail', () {
    test('valid emails', () {
      expect(isValidEmail('user@example.com'), true);
      expect(isValidEmail('a@b.co'), true);
      expect(isValidEmail('user.name@domain.com'), true);
    });

    test('invalid emails', () {
      expect(isValidEmail(null), false);
      expect(isValidEmail(''), false);
      expect(isValidEmail('  '), false);
      expect(isValidEmail('invalid'), false);
      expect(isValidEmail('@domain.com'), false);
      expect(isValidEmail('user@'), false);
    });
  });

  group('isStrongPassword', () {
    test('strong password', () {
      expect(isStrongPassword('Abc12345'), true);
      expect(isStrongPassword('Password1'), true);
    });

    test('weak or invalid', () {
      expect(isStrongPassword(null), false);
      expect(isStrongPassword(''), false);
      expect(isStrongPassword('short'), false);
      expect(isStrongPassword('alllowercase1'), false);
      expect(isStrongPassword('ALLUPPERCASE1'), false);
      expect(isStrongPassword('NoNumbers'), false);
      expect(isStrongPassword('Abc1234'), false); // only 7 chars
    });
  });
}
