import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/transforms/selection_transforms.dart';

void main() {
  group('Selection Transforms Property Tests', () {
    final random = Random(42); // Seed for reproducibility

    /// **Feature: transform-reorganization, Property 8: Filter include and exclude patterns**
    /// **Validates: Requirements 6.1**
    ///
    /// For any list of values and any filter pattern, include patterns (without !)
    /// should keep only values containing the pattern, while exclude patterns
    /// (with ! prefix) should remove values containing the pattern.
    test('Property 8: Filter include and exclude patterns', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random list of strings
        final listSize = random.nextInt(20) + 1;
        final values = List.generate(
          listSize,
          (_) => _generateRandomString(random, 5, 15),
        );

        // Test include pattern
        final includePattern = _generateRandomPattern(random, 1, 3);
        final includeResult = applyFilter(values, includePattern);

        if (includeResult is List) {
          // All results should contain the pattern
          for (var value in includeResult) {
            expect(
              value.toString().contains(includePattern),
              isTrue,
              reason:
                  'Include filter: "$value" should contain "$includePattern"',
            );
          }

          // All values containing the pattern should be in results
          for (var value in values) {
            if (value.contains(includePattern)) {
              expect(
                includeResult.contains(value),
                isTrue,
                reason:
                    'Include filter: "$value" contains "$includePattern" so should be in results',
              );
            }
          }
        }

        // Test exclude pattern
        final excludePattern = _generateRandomPattern(random, 1, 3);
        final excludeResult = applyFilter(values, '!$excludePattern');

        if (excludeResult is List) {
          // No results should contain the pattern
          for (var value in excludeResult) {
            expect(
              value.toString().contains(excludePattern),
              isFalse,
              reason:
                  'Exclude filter: "$value" should not contain "$excludePattern"',
            );
          }

          // All values not containing the pattern should be in results
          for (var value in values) {
            if (!value.contains(excludePattern)) {
              expect(
                excludeResult.contains(value),
                isTrue,
                reason:
                    'Exclude filter: "$value" does not contain "$excludePattern" so should be in results',
              );
            }
          }
        }

        // Test combined include and exclude
        final pattern1 = _generateRandomPattern(random, 1, 2);
        final pattern2 = _generateRandomPattern(random, 1, 2);
        final combinedResult = applyFilter(values, '$pattern1 !$pattern2');

        if (combinedResult is List) {
          for (var value in combinedResult) {
            final str = value.toString();
            expect(
              str.contains(pattern1),
              isTrue,
              reason: 'Combined filter: "$value" should contain "$pattern1"',
            );
            expect(
              str.contains(pattern2),
              isFalse,
              reason:
                  'Combined filter: "$value" should not contain "$pattern2"',
            );
          }
        }
      }
    });

    /// **Feature: transform-reorganization, Property 9: Filter special character escaping**
    /// **Validates: Requirements 6.2**
    ///
    /// For any filter pattern containing escaped special characters (\\ , \\;, \\&),
    /// the filter should treat them as literal characters in the pattern match.
    test('Property 9: Filter special character escaping', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random list of strings with special characters
        final listSize = random.nextInt(20) + 1;
        final values = List.generate(
          listSize,
          (_) => _generateStringWithSpecialChars(random),
        );

        // Test escaped space
        final withSpace = values.where((v) => v.contains(' ')).toList();
        if (withSpace.isNotEmpty) {
          final result = applyFilter(values, r'\ ');
          if (result is List) {
            // All results should contain a literal space
            for (var value in result) {
              expect(
                value.toString().contains(' '),
                isTrue,
                reason: 'Escaped space filter: "$value" should contain a space',
              );
            }
            // All values with space should be in results
            for (var value in withSpace) {
              expect(
                result.contains(value),
                isTrue,
                reason:
                    'Escaped space filter: "$value" contains space so should be in results',
              );
            }
          }
        }

        // Test escaped semicolon
        final withSemicolon = values.where((v) => v.contains(';')).toList();
        if (withSemicolon.isNotEmpty) {
          final result = applyFilter(values, r'\;');
          if (result is List) {
            // All results should contain a literal semicolon
            for (var value in result) {
              expect(
                value.toString().contains(';'),
                isTrue,
                reason:
                    'Escaped semicolon filter: "$value" should contain a semicolon',
              );
            }
            // All values with semicolon should be in results
            for (var value in withSemicolon) {
              expect(
                result.contains(value),
                isTrue,
                reason:
                    'Escaped semicolon filter: "$value" contains semicolon so should be in results',
              );
            }
          }
        }

        // Test escaped ampersand
        final withAmpersand = values.where((v) => v.contains('&')).toList();
        if (withAmpersand.isNotEmpty) {
          final result = applyFilter(values, r'\&');
          if (result is List) {
            // All results should contain a literal ampersand
            for (var value in result) {
              expect(
                value.toString().contains('&'),
                isTrue,
                reason:
                    'Escaped ampersand filter: "$value" should contain an ampersand',
              );
            }
            // All values with ampersand should be in results
            for (var value in withAmpersand) {
              expect(
                result.contains(value),
                isTrue,
                reason:
                    'Escaped ampersand filter: "$value" contains ampersand so should be in results',
              );
            }
          }
        }

        // Test combined escaped characters
        final pattern = _generateEscapedPattern(random);
        final unescapedPattern = pattern
            .replaceAll(r'\ ', ' ')
            .replaceAll(r'\;', ';')
            .replaceAll(r'\&', '&');

        final result = applyFilter(values, pattern);
        if (result is List) {
          for (var value in result) {
            expect(
              value.toString().contains(unescapedPattern),
              isTrue,
              reason:
                  'Escaped pattern "$pattern" -> "$unescapedPattern": "$value" should contain it',
            );
          }
        }
      }
    });

    /// **Feature: transform-reorganization, Property 10: Index positive and negative support**
    /// **Validates: Requirements 6.3**
    ///
    /// For any list and any valid index, positive indices should select from the start
    /// (0-based) and negative indices should select from the end (-1 for last element).
    test('Property 10: Index positive and negative support', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random list
        final listSize = random.nextInt(20) + 1;
        final values = List.generate(
          listSize,
          (index) => 'item_$index',
        );

        // Test positive indices
        for (var idx = 0; idx < listSize; idx++) {
          final result = applyIndex(values, idx.toString());
          expect(
            result,
            equals(values[idx]),
            reason: 'Positive index $idx should return ${values[idx]}',
          );
        }

        // Test negative indices
        for (var idx = -1; idx >= -listSize; idx--) {
          final result = applyIndex(values, idx.toString());
          final expectedIndex = listSize + idx;
          expect(
            result,
            equals(values[expectedIndex]),
            reason:
                'Negative index $idx should return ${values[expectedIndex]}',
          );
        }

        // Test out of bounds positive index
        final outOfBoundsPos = listSize + random.nextInt(10);
        final resultPos = applyIndex(values, outOfBoundsPos.toString());
        expect(
          resultPos,
          isNull,
          reason:
              'Out of bounds positive index $outOfBoundsPos should return null',
        );

        // Test out of bounds negative index
        final outOfBoundsNeg = -(listSize + 1 + random.nextInt(10));
        final resultNeg = applyIndex(values, outOfBoundsNeg.toString());
        expect(
          resultNeg,
          isNull,
          reason:
              'Out of bounds negative index $outOfBoundsNeg should return null',
        );

        // Test index on single value (not a list)
        final singleValue = 'single_value';
        expect(
          applyIndex(singleValue, '0'),
          equals(singleValue),
          reason: 'Index 0 on single value should return the value',
        );
        expect(
          applyIndex(singleValue, '1'),
          isNull,
          reason: 'Index 1 on single value should return null',
        );
        expect(
          applyIndex(singleValue, '-1'),
          isNull,
          reason: 'Negative index on single value should return null',
        );
      }
    });
  });
}

String _generateRandomString(Random random, int minLength, int maxLength) {
  // Note: We include space in the generated strings but not in patterns
  // because space is a delimiter in filter syntax
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

String _generateRandomPattern(Random random, int minLength, int maxLength) {
  // Patterns should not contain spaces (they're delimiters) or special chars
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

String _generateStringWithSpecialChars(Random random) {
  const chars = 'abcdefghijklmnopqrstuvwxyz ;&';
  final length = 5 + random.nextInt(10);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

String _generateEscapedPattern(Random random) {
  final specialChars = [r'\ ', r'\;', r'\&'];
  final numChars = 1 + random.nextInt(3);
  final buffer = StringBuffer();

  for (var i = 0; i < numChars; i++) {
    if (random.nextBool()) {
      // Add a regular character
      const chars = 'abcdefghijklmnopqrstuvwxyz';
      buffer.write(chars[random.nextInt(chars.length)]);
    } else {
      // Add an escaped special character
      buffer.write(specialChars[random.nextInt(specialChars.length)]);
    }
  }

  return buffer.toString();
}
