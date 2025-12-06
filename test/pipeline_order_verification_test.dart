import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';
import 'package:web_query/src/resolver/function.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/core.dart';
import 'package:web_query/src/transforms/selection.dart';
import 'package:web_query/src/transforms/transform_pipeline.dart';

void main() {
  group('Pipeline Order Verification', () {
    test('Verify pipeline order is enforced regardless of map order', () {
      final pageData = PageData('https://example.com', '<html></html>');
      final node = pageData.getRootElement();
      final variables = <String, dynamic>{};

      // Test 1: Map with transforms in "wrong" order (reverse of expected)
      // If pipeline order is enforced, this should still work correctly
      // If map order matters, this will fail

      final value1 = ['hello', 'world', 'test'];

      // Put transforms in REVERSE order: save, index, filter, transform
      final transformsReversed = {
        'save': GroupTransformer([SaveTransformer('myVar')]),
        'index': GroupTransformer([IndexTransformer('0')]),
        'filter': GroupTransformer([FilterTransformer('HELLO')], mapList: true),
        'transform': GroupTransformer([
          SimpleFunctionTransformer(
              functionName: 'upper',
              functionResolver: FunctionResolver(defaultFunctions))
        ], mapList: true),
      };

      final result1 =
          applyAllTransforms(node, value1, transformsReversed, variables)
              .result;

      // If pipeline order is enforced:
      // 1. transform: ['hello', 'world', 'test'] -> ['HELLO', 'WORLD', 'TEST']
      // 2. filter: ['HELLO', 'WORLD', 'TEST'] -> ['HELLO']
      // 3. index: ['HELLO'] -> 'HELLO'
      // 4. save: variables['myVar'] = 'HELLO'
      // Expected: variables['myVar'] == 'HELLO', result is 'HELLO'

      // If map order is used:
      // 1. save: variables['myVar'] = ['hello', 'world', 'test']
      // 2. index: ['hello', 'world', 'test'] -> 'hello'
      // 3. filter: 'hello' (filter for 'HELLO' fails) -> null
      // 4. transform: null -> null
      // Expected: variables['myVar'] is the original list, result is null

      print('Test 1 - Reversed map order:');
      print('  Result: $result1');
      print('  variables["myVar"]: ${variables['myVar']}');

      // Check which behavior we got
      if (result1 == 'HELLO' && variables['myVar'] == 'HELLO') {
        print('  ✓ Pipeline order is enforced (correct behavior)');
      } else {
        print('  ✗ Map entry order is used (incorrect behavior)');
      }

      expect(result1, equals('HELLO'),
          reason: 'Pipeline order should be enforced');
      expect(variables['myVar'], equals('HELLO'),
          reason: 'Save should happen after all transforms');

      // Test 2: Another test with different order
      final variables2 = <String, dynamic>{};
      final value2 = 'test';

      // Put index before filter (which doesn't make sense)
      final transformsWrongOrder = {
        'index': GroupTransformer([IndexTransformer('0')]),
        'filter': GroupTransformer([
          FilterTransformer('TEST'),
        ], mapList: true),
        'transform': GroupTransformer([
          SimpleFunctionTransformer(
              functionName: 'upper',
              functionResolver: FunctionResolver(defaultFunctions))
        ], mapList: true),
      };

      final result2 =
          applyAllTransforms(node, value2, transformsWrongOrder, variables2)
              .result;

      print('\nTest 2 - Wrong logical order (index before filter):');
      print('  Result: $result2');

      // If pipeline order: transform -> filter -> index
      // 'test' -> 'TEST' -> 'TEST' (passes filter) -> 'TEST' (index 0 on non-list returns value)
      // Expected: 'TEST'

      // If map order: index -> filter -> transform
      // 'test' (index 0 on non-list) -> 'test' (filter for 'TEST' fails) -> null
      // Expected: null

      if (result2 == 'TEST') {
        print('  ✓ Pipeline order is enforced');
      } else {
        print('  ✗ Map entry order is used');
      }

      expect(result2, equals('TEST'),
          reason: 'Pipeline order should be enforced');
    });

    test('Explicit test: Does LinkedHashMap preserve insertion order?', () {
      // Dart's Map is a LinkedHashMap by default, which preserves insertion order
      final map = <String, int>{
        'third': 3,
        'first': 1,
        'second': 2,
      };

      final keys = map.keys.toList();
      print('\nMap iteration order test:');
      print('  Keys in order: $keys');

      expect(keys, equals(['third', 'first', 'second']),
          reason: 'Map should preserve insertion order');
    });
  });
}
