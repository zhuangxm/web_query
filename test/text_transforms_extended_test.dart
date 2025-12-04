import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/transforms/text_transforms.dart';

void main() {
  group('Base64 Encoding', () {
    test('encode simple string', () {
      expect(base64Encode('Hello'), 'SGVsbG8=');
    });

    test('encode string with spaces', () {
      expect(base64Encode('Hello World'), 'SGVsbG8gV29ybGQ=');
    });

    test('encode empty string', () {
      expect(base64Encode(''), '');
    });

    test('encode null returns null', () {
      expect(base64Encode(null), null);
    });

    test('encode numbers', () {
      expect(base64Encode(123), 'MTIz');
    });

    test('encode unicode', () {
      final result = base64Encode('Hello 世界');
      expect(result, isNotNull);
      // Verify it can be decoded back
      expect(base64Decode(result), 'Hello 世界');
    });
  });

  group('Base64 Decoding', () {
    test('decode simple string', () {
      expect(base64Decode('SGVsbG8='), 'Hello');
    });

    test('decode string with spaces', () {
      expect(base64Decode('SGVsbG8gV29ybGQ='), 'Hello World');
    });

    test('decode empty string', () {
      expect(base64Decode(''), '');
    });

    test('decode null returns null', () {
      expect(base64Decode(null), null);
    });

    test('decode invalid base64 returns null', () {
      expect(base64Decode('invalid!!!'), null);
    });

    test('round trip encoding and decoding', () {
      const original = 'Test String 123!@#';
      final encoded = base64Encode(original);
      final decoded = base64Decode(encoded);
      expect(decoded, original);
    });
  });

  group('String Reversal', () {
    test('reverse simple string', () {
      expect(reverseString('Hello'), 'olleH');
    });

    test('reverse numbers', () {
      expect(reverseString('12345'), '54321');
    });

    test('reverse single character', () {
      expect(reverseString('a'), 'a');
    });

    test('reverse empty string', () {
      expect(reverseString(''), '');
    });

    test('reverse null returns null', () {
      expect(reverseString(null), null);
    });

    test('reverse palindrome', () {
      expect(reverseString('racecar'), 'racecar');
    });

    test('reverse with spaces', () {
      expect(reverseString('Hello World'), 'dlroW olleH');
    });
  });

  group('MD5 Hashing', () {
    test('hash simple string', () {
      expect(md5Hash('password'), '5f4dcc3b5aa765d61d8327deb882cf99');
    });

    test('hash test string', () {
      expect(md5Hash('test'), '098f6bcd4621d373cade4e832627b4f6');
    });

    test('hash empty string', () {
      expect(md5Hash(''), 'd41d8cd98f00b204e9800998ecf8427e');
    });

    test('hash null returns null', () {
      expect(md5Hash(null), null);
    });

    test('hash is consistent', () {
      final hash1 = md5Hash('same input');
      final hash2 = md5Hash('same input');
      expect(hash1, hash2);
    });

    test('different inputs produce different hashes', () {
      final hash1 = md5Hash('input1');
      final hash2 = md5Hash('input2');
      expect(hash1, isNot(hash2));
    });

    test('hash is lowercase', () {
      final hash = md5Hash('test');
      expect(hash, equals(hash!.toLowerCase()));
    });

    test('hash is 32 characters', () {
      final hash = md5Hash('test');
      expect(hash!.length, 32);
    });
  });

  group('applyTextTransform with new transforms', () {
    test('apply base64 transform', () {
      expect(applyTextTransform('Hello', 'base64'), 'SGVsbG8=');
    });

    test('apply base64decode transform', () {
      expect(applyTextTransform('SGVsbG8=', 'base64decode'), 'Hello');
    });

    test('apply reverse transform', () {
      expect(applyTextTransform('Hello', 'reverse'), 'olleH');
    });

    test('apply md5 transform', () {
      expect(
        applyTextTransform('test', 'md5'),
        '098f6bcd4621d373cade4e832627b4f6',
      );
    });

    test('apply transforms to list', () {
      expect(
        applyTextTransform(['Hello', 'World'], 'base64'),
        ['SGVsbG8=', 'V29ybGQ='],
      );
    });

    test('apply reverse to list', () {
      expect(
        applyTextTransform(['abc', 'xyz'], 'reverse'),
        ['cba', 'zyx'],
      );
    });

    test('chain transforms conceptually', () {
      // First reverse, then base64
      final reversed = applyTextTransform('Hello', 'reverse');
      final encoded = applyTextTransform(reversed, 'base64');
      expect(encoded, 'b2xsZUg='); // Base64 of 'olleH'
    });
  });

  group('Integration with existing transforms', () {
    test('upper then base64', () {
      final upper = applyTextTransform('hello', 'upper');
      final encoded = applyTextTransform(upper, 'base64');
      expect(encoded, 'SEVMTE8='); // Base64 of 'HELLO'
    });

    test('base64decode then lower', () {
      final decoded = applyTextTransform('SEVMTE8=', 'base64decode');
      final lower = applyTextTransform(decoded, 'lower');
      expect(lower, 'hello');
    });

    test('reverse then md5', () {
      final reversed = applyTextTransform('password', 'reverse');
      final hashed = applyTextTransform(reversed, 'md5');
      expect(hashed, isNotNull);
      expect(hashed, isNot(md5Hash('password'))); // Different from original
    });
  });
}
