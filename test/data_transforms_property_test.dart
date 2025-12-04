import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/src/transforms/data_transforms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Configure JavaScript executor for jseval tests
    configureJsExecutor(FlutterJsExecutor());
  });

  group('Data Transforms Property Tests', () {
    final random = Random(42); // Seed for reproducibility

    /// **Feature: transform-reorganization, Property 6: JSON wildcard variable extraction**
    /// **Validates: Requirements 5.2**
    ///
    /// For any JavaScript code containing variable assignments and any wildcard pattern,
    /// the JSON transform should extract the first variable whose name matches the wildcard pattern.
    test('Property 6: JSON wildcard variable extraction', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random variable names with a common prefix
        final prefix = _generateRandomPrefix(random);

        // Use simple JSON values that are guaranteed to work
        final jsonValue = _generateSimpleJsonValue(random);
        final jsonString = _jsonValueToString(jsonValue);

        // Create JavaScript variable assignment with specific name
        final varName = '${prefix}_test';
        final script = 'var $varName = $jsonString;';

        // Test wildcard pattern that should match
        final wildcardPattern = '${prefix}_*';
        final result = applyJsonTransform(script, wildcardPattern);

        // Verify that result extracts the value (skip null case)
        if (jsonValue != null) {
          expect(
            result,
            isNotNull,
            reason:
                'Wildcard pattern "$wildcardPattern" should match variable "$varName" in script: $script',
          );

          // Verify type preservation
          if (jsonValue is Map) {
            expect(result, isA<Map>(), reason: 'Should preserve Map type');
          } else if (jsonValue is List) {
            expect(result, isA<List>(), reason: 'Should preserve List type');
          } else if (jsonValue is num) {
            expect(result, isA<num>(), reason: 'Should preserve num type');
          } else if (jsonValue is bool) {
            expect(result, isA<bool>(), reason: 'Should preserve bool type');
          } else if (jsonValue is String) {
            expect(result, isA<String>(),
                reason: 'Should preserve String type');
          }
        }
      }
    });

    /// **Feature: transform-reorganization, Property 7: JSON type support**
    /// **Validates: Requirements 5.4**
    ///
    /// For any valid JSON string containing objects, arrays, primitives, booleans, or null,
    /// the JSON transform should successfully parse and return the corresponding Dart value.
    test('Property 7: JSON type support', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random JSON value of different types
        final jsonValue = _generateRandomJsonValue(random);

        // Skip null for this test since null is a special case
        if (jsonValue == null) {
          continue;
        }

        final jsonString = _jsonValueToString(jsonValue);

        // Apply JSON transform
        final result = applyJsonTransform(jsonString, null);

        // Verify the result matches the original value
        expect(
          result,
          isNotNull,
          reason:
              'JSON transform should successfully parse valid JSON: $jsonString',
        );

        // Type-specific checks
        if (jsonValue is Map) {
          expect(
            result,
            isA<Map>(),
            reason: 'JSON object should parse to Map',
          );
          if (result is Map) {
            expect(
              result.keys.length,
              equals(jsonValue.keys.length),
              reason: 'Parsed map should have same number of keys',
            );
          }
        } else if (jsonValue is List) {
          expect(
            result,
            isA<List>(),
            reason: 'JSON array should parse to List',
          );
          if (result is List) {
            expect(
              result.length,
              equals(jsonValue.length),
              reason: 'Parsed list should have same length',
            );
          }
        } else if (jsonValue is num) {
          expect(
            result,
            isA<num>(),
            reason: 'JSON number should parse to num',
          );
          expect(
            result,
            equals(jsonValue),
            reason: 'Parsed number should equal original',
          );
        } else if (jsonValue is bool) {
          expect(
            result,
            isA<bool>(),
            reason: 'JSON boolean should parse to bool',
          );
          expect(
            result,
            equals(jsonValue),
            reason: 'Parsed boolean should equal original',
          );
        } else if (jsonValue is String) {
          expect(
            result,
            isA<String>(),
            reason: 'JSON string should parse to String',
          );
          expect(
            result,
            equals(jsonValue),
            reason: 'Parsed string should equal original',
          );
        }
      }
    });

    /// Additional test: Verify JSON extraction from JavaScript variable assignment
    test('Property: JSON extraction from variable assignment', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final varName = _generateRandomVarName(random);
        final jsonValue = _generateSimpleJsonValue(random);
        final jsonString = _jsonValueToString(jsonValue);

        // Create JavaScript variable assignment
        final script = 'var $varName = $jsonString;';

        // Extract using variable name
        final result = applyJsonTransform(script, varName);

        // Verify extraction
        expect(
          result,
          isNotNull,
          reason:
              'Should extract JSON from variable assignment "var $varName = ..." (script: $script)',
        );

        // Verify type preservation
        if (jsonValue is Map) {
          expect(result, isA<Map>(), reason: 'Should preserve Map type');
        } else if (jsonValue is List) {
          expect(result, isA<List>(), reason: 'Should preserve List type');
        } else if (jsonValue is num) {
          expect(result, isA<num>(), reason: 'Should preserve num type');
        } else if (jsonValue is bool) {
          expect(result, isA<bool>(), reason: 'Should preserve bool type');
        } else if (jsonValue is String) {
          expect(result, isA<String>(), reason: 'Should preserve String type');
        }
      }
    });

    /// Additional test: Verify update transform merges objects correctly
    test('Property: Update transform merges objects', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random base object
        final baseObj = _generateRandomMap(random, 2, 5);

        // Generate random update object
        final updateObj = _generateRandomMap(random, 1, 3);
        final updateJson = _jsonValueToString(updateObj);

        // Apply update
        final result = applyUpdate(baseObj, updateJson);

        // Verify result is a map
        expect(
          result,
          isA<Map>(),
          reason: 'Update should return a Map',
        );

        if (result is Map) {
          // Verify all base keys are present (unless overwritten)
          for (var key in baseObj.keys) {
            expect(
              result.containsKey(key),
              isTrue,
              reason: 'Result should contain base key "$key"',
            );
          }

          // Verify all update keys are present and have correct values
          for (var key in updateObj.keys) {
            expect(
              result.containsKey(key),
              isTrue,
              reason: 'Result should contain update key "$key"',
            );
            expect(
              result[key],
              equals(updateObj[key]),
              reason: 'Update key "$key" should have updated value',
            );
          }
        }
      }
    });

    /// Additional test: Verify update on non-map returns original value
    test('Property: Update on non-map returns original', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate non-map value
        final value = _generateNonMapValue(random);
        final updateJson = '{"key": "value"}';

        // Apply update
        final result = applyUpdate(value, updateJson);

        // Verify original value is returned
        expect(
          result,
          equals(value),
          reason: 'Update on non-map should return original value',
        );
      }
    });

    /// **Feature: transform-reorganization, Property 12: JavaScript multi-variable extraction**
    /// **Validates: Requirements 8.3**
    ///
    /// For any JavaScript code and any comma-separated list of variable names,
    /// the jseval transform should extract all specified variables and return them as a structured result.
    test('Property 12: JavaScript multi-variable extraction', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random number of variables (2-5)
        final varCount = 2 + random.nextInt(4);
        final varNames = <String>[];
        final scriptParts = <String>[];

        // Generate JavaScript code with multiple variables
        for (var j = 0; j < varCount; j++) {
          final varName = 'var$j';
          varNames.add(varName);

          // Use simple values for reliability
          final value = _generateSimpleJsValue(random);
          scriptParts.add('var $varName = $value;');
        }

        final script = scriptParts.join('\n');
        final variableNames = varNames.join(',');

        // Apply jseval transform
        final result = applyJsEvalTransform(script, variableNames);

        // Verify result is a map containing all variables
        expect(
          result,
          isNotNull,
          reason:
              'jseval should extract variables from script: $script with names: $variableNames',
        );

        if (result != null) {
          expect(
            result,
            isA<Map>(),
            reason: 'jseval with multiple variables should return a Map',
          );

          if (result is Map) {
            // Verify all requested variables are present
            for (var varName in varNames) {
              expect(
                result.containsKey(varName),
                isTrue,
                reason:
                    'Result should contain variable "$varName" (result: $result)',
              );
            }
          }
        }
      }
    });
  });
}

/// Generate a random prefix for variable names
String _generateRandomPrefix(Random random) {
  const prefixes = [
    'config',
    'data',
    'flashvars',
    'settings',
    'params',
    'options'
  ];
  return prefixes[random.nextInt(prefixes.length)];
}

/// Generate a random variable name
String _generateRandomVarName(Random random) {
  const names = [
    'config',
    'data',
    'settings',
    'userData',
    'apiKey',
    'items',
    'result',
    '__INITIAL_STATE__',
    '__NEXT_DATA__'
  ];
  return names[random.nextInt(names.length)];
}

/// Generate a random JSON value
dynamic _generateRandomJsonValue(Random random) {
  final type = random.nextInt(6);

  switch (type) {
    case 0:
      // Object
      return _generateRandomMap(random, 1, 4);
    case 1:
      // Array
      return _generateRandomList(random, 1, 5);
    case 2:
      // Number
      return random.nextInt(1000);
    case 3:
      // Boolean
      return random.nextBool();
    case 4:
      // String
      return _generateRandomString(random, 3, 10);
    case 5:
      // Null
      return null;
    default:
      return _generateRandomString(random, 3, 10);
  }
}

/// Generate a simple JSON value (no null, simpler structures)
dynamic _generateSimpleJsonValue(Random random) {
  final type = random.nextInt(5);

  switch (type) {
    case 0:
      // Simple object
      return {'key': 'value', 'num': random.nextInt(100)};
    case 1:
      // Simple array
      return [1, 2, 3];
    case 2:
      // Number
      return random.nextInt(1000);
    case 3:
      // Boolean
      return random.nextBool();
    case 4:
      // String
      return _generateRandomString(random, 3, 10);
    default:
      return _generateRandomString(random, 3, 10);
  }
}

/// Generate a random map
Map<String, dynamic> _generateRandomMap(
    Random random, int minSize, int maxSize) {
  final size = minSize + random.nextInt(maxSize - minSize + 1);
  final map = <String, dynamic>{};

  for (var i = 0; i < size; i++) {
    final key = 'key$i';
    // Use simpler values to avoid deep nesting
    final valueType = random.nextInt(4);
    dynamic value;
    switch (valueType) {
      case 0:
        value = random.nextInt(100);
        break;
      case 1:
        value = random.nextBool();
        break;
      case 2:
        value = _generateRandomString(random, 3, 8);
        break;
      case 3:
        value = null;
        break;
    }
    map[key] = value;
  }

  return map;
}

/// Generate a random list
List<dynamic> _generateRandomList(Random random, int minSize, int maxSize) {
  final size = minSize + random.nextInt(maxSize - minSize + 1);
  final list = <dynamic>[];

  for (var i = 0; i < size; i++) {
    // Use simpler values to avoid deep nesting
    final valueType = random.nextInt(4);
    dynamic value;
    switch (valueType) {
      case 0:
        value = random.nextInt(100);
        break;
      case 1:
        value = random.nextBool();
        break;
      case 2:
        value = _generateRandomString(random, 3, 8);
        break;
      case 3:
        value = null;
        break;
    }
    list.add(value);
  }

  return list;
}

/// Generate a non-map value
dynamic _generateNonMapValue(Random random) {
  final type = random.nextInt(4);

  switch (type) {
    case 0:
      return _generateRandomList(random, 1, 5);
    case 1:
      return random.nextInt(1000);
    case 2:
      return _generateRandomString(random, 3, 10);
    case 3:
      return random.nextBool();
    default:
      return _generateRandomString(random, 3, 10);
  }
}

/// Convert JSON value to string
String _jsonValueToString(dynamic value) {
  if (value == null) {
    return 'null';
  } else if (value is String) {
    // Escape quotes in string
    return '"${value.replaceAll('"', '\\"')}"';
  } else if (value is Map) {
    final entries = value.entries
        .map((e) => '"${e.key}": ${_jsonValueToString(e.value)}')
        .join(', ');
    return '{$entries}';
  } else if (value is List) {
    final items = value.map((v) => _jsonValueToString(v)).join(', ');
    return '[$items]';
  } else {
    return value.toString();
  }
}

/// Generate a random string
String _generateRandomString(Random random, int minLength, int maxLength) {
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

/// Generate a simple JavaScript value (for jseval tests)
String _generateSimpleJsValue(Random random) {
  final type = random.nextInt(4);

  switch (type) {
    case 0:
      // Number
      return random.nextInt(1000).toString();
    case 1:
      // Boolean
      return random.nextBool().toString();
    case 2:
      // String
      return '"${_generateRandomString(random, 3, 8)}"';
    case 3:
      // Simple object
      return '{"key": "${_generateRandomString(random, 3, 8)}"}';
    default:
      return random.nextInt(1000).toString();
  }
}
