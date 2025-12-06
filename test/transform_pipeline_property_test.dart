import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';
import 'package:web_query/src/resolver/function.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/core.dart';
import 'package:web_query/src/transforms/selection.dart';
import 'package:web_query/src/transforms/transform_pipeline.dart';

void main() {
  group('Transform Pipeline Property Tests', () {
    late Random random;

    setUp(() {
      random = Random(42); // Fixed seed for reproducibility
    });

    /// **Feature: transform-reorganization, Property 1: Transform pipeline order preservation**
    /// **Validates: Requirements 2.1**
    test('Property: Transform pipeline order preservation', () {
      // Test that transforms are applied in the correct order:
      // transform → update → filter → index → save → discard

      for (var iteration = 0; iteration < 100; iteration++) {
        // Create a test page node
        final pageData = PageData('https://example.com', '<html></html>');
        final node = pageData.getRootElement();
        final variables = <String, dynamic>{};

        // Test case 1: Transform then filter
        // Apply uppercase transform, then filter for uppercase strings
        final value1 = 'hello';
        final transforms1 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]),
          'filter': GroupTransformer([FilterTransformer('HELLO')]),
        };
        final result1 =
            applyAllTransforms(node, value1, transforms1, variables).result;
        expect(result1, equals('HELLO'),
            reason: 'Transform should be applied before filter');

        // Test case 2: Filter then index
        // Filter a list, then get specific index
        final value2 = ['apple', 'banana', 'cherry', 'date'];
        final transforms2 = {
          'filter': GroupTransformer(
              [FilterTransformer('a')]), // Keep items containing 'a'
          'index': GroupTransformer(
              [IndexTransformer('1')]), // Get second item from filtered list
        };
        final result2 =
            applyAllTransforms(node, value2, transforms2, variables).result;
        expect(result2, equals('banana'),
            reason: 'Filter should be applied before index');

        // Test case 3: Save value
        // Save a value to variables
        final value3 = 'test_value';
        final transforms3 = {
          'save': GroupTransformer([SaveTransformer('myVar')]),
        };
        final result3 =
            applyAllTransforms(node, value3, transforms3, variables).result;
        expect(variables['myVar'], equals('test_value'),
            reason: 'Save should store the value');
        expect(result3, equals('test_value'),
            reason: 'Save should not modify the result');

        // Test case 4: Transform, filter, index in sequence
        final value4 = ['hello', 'world', 'test', 'data'];
        final transforms4 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]),
          'filter': GroupTransformer(
              [FilterTransformer('!TEST')]), // Exclude items containing 'TEST'
          'index': GroupTransformer([IndexTransformer('0')]),
        };
        final result4 =
            applyAllTransforms(node, value4, transforms4, variables).result;
        expect(result4, equals('HELLO'),
            reason: 'Transform → filter → index should work in order');

        // Test case 5: All transforms in order
        final value5 = ['item1', 'item2', 'item3'];
        final transforms5 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]),
          'filter': GroupTransformer(
              [FilterTransformer('ITEM')]), // Keep items containing 'ITEM'
          'index': GroupTransformer([IndexTransformer('1')]),
          'save': GroupTransformer([SaveTransformer('allVar')]),
        };
        final result5 =
            applyAllTransforms(node, value5, transforms5, variables).result;
        expect(variables['allVar'], equals('ITEM2'),
            reason: 'Save should capture value after transform/filter/index');
        expect(result5, equals('ITEM2'),
            reason: 'Result should be the final transformed value');
      }
    });

    /// **Feature: transform-reorganization, Property 2: Transform chaining consistency**
    /// **Validates: Requirements 2.2**
    test('Property: Transform chaining consistency', () {
      // Test that the output of each transform becomes the input to the next

      for (var iteration = 0; iteration < 100; iteration++) {
        final pageData = PageData('https://example.com', '<html></html>');
        final node = pageData.getRootElement();
        final variables = <String, dynamic>{};

        // Test case 1: Multiple text transforms chain correctly
        final value1 = 'Hello World';
        final transforms1 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions)),
            SimpleFunctionTransformer(
                functionName: 'lower',
                functionResolver: FunctionResolver(defaultFunctions))
          ]), // upper then lower
        };
        final result1 =
            applyAllTransforms(node, value1, transforms1, variables).result;
        expect(result1, equals('hello world'),
            reason: 'Second transform should receive output of first');

        // Test case 2: Transform output feeds into filter
        final value2 = ['hello', 'WORLD', 'Test'];
        final transforms2 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]), // All become uppercase
          'filter': GroupTransformer(
              [FilterTransformer('WORLD')]), // Then filter for WORLD
        };
        final result2 =
            applyAllTransforms(node, value2, transforms2, variables).result;
        expect(result2, contains('WORLD'),
            reason: 'Filter should work on transformed values');
        expect(result2, isA<List>(), reason: 'Should return filtered list');

        // Test case 3: Filter output feeds into index
        final value3 = ['apple', 'apricot', 'banana', 'avocado'];
        final transforms3 = {
          'filter':
              GroupTransformer([FilterTransformer('a')]), // Keep items with 'a'
          'index': GroupTransformer(
              [IndexTransformer('-1')]), // Get last item from filtered list
        };
        final result3 =
            applyAllTransforms(node, value3, transforms3, variables).result;
        expect(result3, equals('avocado'),
            reason: 'Index should work on filtered list');

        // Test case 4: Index output feeds into save
        final value4 = ['first', 'second', 'third'];
        final transforms4 = {
          'index': GroupTransformer([IndexTransformer('1')]), // Get 'second'
          'save': GroupTransformer([SaveTransformer('chainVar')]),
        };
        final result4 =
            applyAllTransforms(node, value4, transforms4, variables).result;
        expect(variables['chainVar'], equals('second'),
            reason: 'Save should receive indexed value');

        // Test case 5: Complex chain with all transform types
        final value5 = ['test1', 'test2', 'other', 'test3'];
        final transforms5 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]), // ['TEST1', 'TEST2', 'OTHER', 'TEST3']
          'filter': GroupTransformer(
              [FilterTransformer('TEST')]), // ['TEST1', 'TEST2', 'TEST3']
          'index': GroupTransformer([IndexTransformer('1')]), // 'TEST2'
          'save': GroupTransformer([SaveTransformer('complexVar')]),
        };
        final result5 =
            applyAllTransforms(node, value5, transforms5, variables).result;
        expect(variables['complexVar'], equals('TEST2'),
            reason: 'Complex chain should pass values correctly');
        expect(result5, equals('TEST2'),
            reason: 'Final result should be the chained value');

        // Test case 6: Verify null propagation through chain
        final value6 = null;
        final transforms6 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]),
          'filter': GroupTransformer([FilterTransformer('test')]),
          'index': GroupTransformer([IndexTransformer('0')]),
        };
        final result6 =
            applyAllTransforms(node, value6, transforms6, variables).result;
        expect(result6, isNull,
            reason: 'Null should propagate through transform chain');

        // Test case 7: Empty list propagation
        final value7 = <String>[];
        final transforms7 = {
          'transform': GroupTransformer([
            SimpleFunctionTransformer(
                functionName: 'upper',
                functionResolver: FunctionResolver(defaultFunctions))
          ]),
          'filter': GroupTransformer([FilterTransformer('test')]),
          'index': GroupTransformer([IndexTransformer('0')]),
        };
        final result7 =
            applyAllTransforms(node, value7, transforms7, variables).result;
        expect(result7, isNull,
            reason: 'Empty list should result in null after index');
      }
    });
  });
}
