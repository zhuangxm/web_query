import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/transforms/text_transforms.dart';

void main() {
  group('Text Transforms Property Tests', () {
    final random = Random(42); // Seed for reproducibility

    /// **Feature: transform-reorganization, Property 3: Single value and list consistency**
    /// **Validates: Requirements 3.2**
    ///
    /// For any transform and any value, applying the transform to a single value
    /// should produce the same result as applying it to a list containing only
    /// that value and extracting the first element (when the transform preserves structure).
    test('Property 3: Single value and list consistency', () {
      const iterations = 100;
      final transforms = ['upper', 'lower'];

      for (var i = 0; i < iterations; i++) {
        // Generate random value
        final value = _generateRandomValue(random);

        for (var transform in transforms) {
          // Apply transform to single value
          final singleResult = applyTextTransform(value, transform);

          // Apply transform to list containing only that value
          final listResult = applyTextTransform([value], transform);

          // Extract first element from list result
          final firstElement = (listResult is List && listResult.isNotEmpty)
              ? listResult[0]
              : listResult;

          expect(
            firstElement,
            equals(singleResult),
            reason:
                'Transform "$transform" on value "$value": single result should equal first element of list result',
          );
        }
      }
    });

    /// **Feature: transform-reorganization, Property 4: Null handling gracefully**
    /// **Validates: Requirements 3.3**
    ///
    /// For any transform type, passing null as input should return null
    /// without throwing exceptions.
    test('Property 4: Null handling gracefully', () {
      const iterations = 100;
      final transforms = ['upper', 'lower'];

      for (var i = 0; i < iterations; i++) {
        for (var transform in transforms) {
          // Test null input
          expect(
            () => applyTextTransform(null, transform),
            returnsNormally,
            reason: 'Transform "$transform" should not throw on null input',
          );

          final result = applyTextTransform(null, transform);
          expect(
            result,
            isNull,
            reason: 'Transform "$transform" should return null for null input',
          );
        }

        // Test null in list
        final mixedList = [
          _generateRandomValue(random),
          null,
          _generateRandomValue(random),
        ];

        for (var transform in transforms) {
          expect(
            () => applyTextTransform(mixedList, transform),
            returnsNormally,
            reason:
                'Transform "$transform" should not throw on list with null elements',
          );

          final result = applyTextTransform(mixedList, transform);
          expect(
            result,
            isA<List>(),
            reason:
                'Transform "$transform" should return a list when given a list',
          );

          if (result is List) {
            expect(
              result[1],
              isNull,
              reason:
                  'Transform "$transform" should preserve null in list at index 1',
            );
          }
        }
      }
    });

    /// Additional test: Verify uppercase transformation correctness
    test('Property: Uppercase transformation correctness', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final value = _generateRandomValue(random);
        final result = applyTextTransform(value, 'upper');

        if (value != null) {
          expect(
            result,
            equals(value.toString().toUpperCase()),
            reason: 'Uppercase transform should match toString().toUpperCase()',
          );
        }
      }
    });

    /// Additional test: Verify lowercase transformation correctness
    test('Property: Lowercase transformation correctness', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final value = _generateRandomValue(random);
        final result = applyTextTransform(value, 'lower');

        if (value != null) {
          expect(
            result,
            equals(value.toString().toLowerCase()),
            reason: 'Lowercase transform should match toString().toLowerCase()',
          );
        }
      }
    });

    /// Additional test: Verify list transformation applies to all elements
    test('Property: List transformation applies to all elements', () {
      const iterations = 100;
      final transforms = ['upper', 'lower'];

      for (var i = 0; i < iterations; i++) {
        final listSize = random.nextInt(20) + 1;
        final values = List.generate(
          listSize,
          (_) => _generateRandomValue(random),
        );

        for (var transform in transforms) {
          final result = applyTextTransform(values, transform);

          expect(
            result,
            isA<List>(),
            reason:
                'Transform "$transform" should return a list for list input',
          );

          if (result is List) {
            expect(
              result.length,
              equals(values.length),
              reason: 'Transform "$transform" should preserve list length',
            );

            for (var j = 0; j < values.length; j++) {
              final expectedSingle = applyTextTransform(values[j], transform);
              expect(
                result[j],
                equals(expectedSingle),
                reason:
                    'Transform "$transform" at index $j should match single value transform',
              );
            }
          }
        }
      }
    });
  });
}

/// Generate a random value for testing
dynamic _generateRandomValue(Random random) {
  final type = random.nextInt(5);

  switch (type) {
    case 0:
      // Random string with mixed case
      return _generateRandomString(random, 5, 15);
    case 1:
      // Random number
      return random.nextInt(10000);
    case 2:
      // Random boolean
      return random.nextBool();
    case 3:
      // Random string with special characters
      return _generateStringWithSpecialChars(random);
    case 4:
      // Random string with unicode
      return _generateUnicodeString(random);
    default:
      return _generateRandomString(random, 5, 15);
  }
}

String _generateRandomString(Random random, int minLength, int maxLength) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

String _generateStringWithSpecialChars(Random random) {
  const chars = 'abcABC123!@#\$%^&*()_+-=[]{}|;:,.<>?';
  final length = 5 + random.nextInt(10);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

String _generateUnicodeString(Random random) {
  // Include some common unicode characters
  const chars = 'abcABC123αβγδεζηθικλμνξοπρστυφχψω';
  final length = 5 + random.nextInt(10);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
