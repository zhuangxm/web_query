import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Manual Validation Tests', () {
    test('validate() returns detailed info for valid query', () {
      final query = QueryString('json:items?save=x&keep ++ template:\${x}');
      final result = query.validate();

      print('\n=== Valid Query Test ===');
      print('Query: ${result.query}');
      print('Is Valid: ${result.isValid}');
      print('Has Warnings: ${result.hasWarnings}');
      print('\nQuery Info:');
      print(result.toString());
      print('\nJSON:');
      print(result.toJson());

      expect(result.isValid, isTrue);
      expect(result.info, isNotNull);
      expect(result.info!.totalParts, equals(2));
      expect(result.info!.operators, equals(['++']));
      expect(result.info!.variables, contains('x'));
    });

    test('validate() returns errors for invalid query', () {
      final query = QueryString(
          'jsn:items?save=x?keep'); // Invalid scheme and parameter syntax
      final result = query.validate();

      print('\n=== Invalid Query Test ===');
      print('Query: ${result.query}');
      print('Is Valid: ${result.isValid}');
      print('Errors: ${result.errors.length}');
      print('\nFormatted Output:');
      print(result.toString());
      print('\nJSON:');
      print(result.toJson());

      expect(result.isValid, isFalse);
      expect(result.info, isNull);
      expect(result.errors.length, greaterThan(0));
    });

    test('validate() does not affect query execution', () {
      final query = QueryString('json:items');

      // Validate first
      final validationResult = query.validate();
      expect(validationResult.isValid, isTrue);

      // Execute query - should work normally
      final pageData = PageData('', '', jsonData: '{"items": ["a", "b", "c"]}');
      final result = query.execute(pageData.getRootElement());

      expect(result, equals(['a', 'b', 'c']));
    });

    test('query with errors can still execute', () {
      // This query has an invalid scheme but might still execute
      // (depending on how the parser handles it)
      final query = QueryString('html:div');

      // Validate
      final validationResult = query.validate();
      print('\n=== Execution Independence Test ===');
      print('Validation result: ${validationResult.isValid}');

      // Try to execute - should not throw from validation
      final pageData = PageData('', '<div>test</div>');
      try {
        final result = query.execute(pageData.getRootElement());
        print('Execution succeeded: $result');
      } catch (e) {
        print('Execution failed (expected for some invalid queries): $e');
      }
    });

    test('complex query with multiple features', () {
      final query = QueryString(
          'json:user/firstName?save=fn ++ json:user/lastName?save=ln&keep&transform=upper ++ template:\${fn} \${ln}');
      final result = query.validate();

      print('\n=== Complex Query Test ===');
      print(result.toString());

      expect(result.isValid, isTrue);
      expect(result.info!.totalParts, equals(3));
      expect(result.info!.operators, equals(['++', '++']));
      expect(result.info!.variables, containsAll(['fn', 'ln']));
      expect(result.info!.parts[0].transforms, containsPair('save', ['fn']));
      expect(result.info!.parts[1].transforms, containsPair('save', ['ln']));
      expect(result.info!.parts[1].transforms, containsPair('keep', ['']));
      expect(result.info!.parts[1].transforms,
          containsPair('transform', ['upper']));
      // Template scheme treats entire content as path, including any ? characters
      expect(result.info!.parts[2].scheme, equals('template'));
    });

    test('query with >>> operator', () {
      final query = QueryString('json:items >>> json:name');
      final result = query.validate();

      print('\n=== Array Pipe Operator Test ===');
      print(result.toString());

      expect(result.isValid, isTrue);
      expect(result.info!.operators, contains('>>>'));
    });

    test('query with || fallback operator', () {
      final query = QueryString('json:title || html:h1/@text');
      final result = query.validate();

      print('\n=== Fallback Operator Test ===');
      print(result.toString());

      expect(result.isValid, isTrue);
      expect(result.info!.operators, equals(['||']));
      // First part is always required, second part after || is not required
      expect(result.info!.parts[0].isRequired, isTrue);
      expect(result.info!.parts[1].isRequired, isFalse);
    });

    test('empty query validation', () {
      final query = QueryString('');
      final result = query.validate();

      print('\n=== Empty Query Test ===');
      print('Is Valid: ${result.isValid}');
      print('Errors: ${result.errors.length}');

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('regexp pattern with unescaped special characters warns', () {
      final query =
          QueryString('div/@text?transform=regexp:/test.com/replaced/');
      final result = query.validate();

      print('\n=== Regexp Pattern Warning Test ===');
      print('Query: ${result.query}');
      print('Is Valid: ${result.isValid}');
      print('Has Warnings: ${result.hasWarnings}');
      print('Warnings: ${result.warnings.length}');
      if (result.hasWarnings) {
        print('\nFormatted Warnings:');
        print(result.toString());
      }

      expect(result.isValid, isTrue); // No errors, just warnings
      expect(result.hasWarnings, isTrue);
      expect(result.warnings.length, greaterThan(0));
      expect(
          result.warnings[0].message, contains('Unescaped special character'));
    });

    test('template with missing dollar sign warns', () {
      final query = QueryString('template:{varName}');
      final result = query.validate();

      print('\n=== Template Missing Dollar Test ===');
      print('Query: ${result.query}');
      print('Is Valid: ${result.isValid}');
      print('Has Warnings: ${result.hasWarnings}');
      if (result.hasWarnings) {
        print('\nFormatted Warnings:');
        print(result.toString());
      }

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.warnings[0].message, contains('missing "\$" prefix'));
    });

    test('template with empty variable warns', () {
      final query = QueryString('template:Hello \${}!');
      final result = query.validate();

      print('\n=== Template Empty Variable Test ===');
      print('Query: ${result.query}');
      print('Has Warnings: ${result.hasWarnings}');
      if (result.hasWarnings) {
        print('\nFormatted Warnings:');
        print(result.toString());
      }

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.warnings[0].message, contains('Empty template variable'));
    });

    test('template with whitespace in variable warns', () {
      final query = QueryString('template:\${ varName }');
      final result = query.validate();

      print('\n=== Template Whitespace Variable Test ===');
      print('Query: ${result.query}');
      print('Has Warnings: ${result.hasWarnings}');
      if (result.hasWarnings) {
        print('\nFormatted Warnings:');
        print(result.toString());
      }

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(
          result.warnings[0].message, contains('leading/trailing whitespace'));
    });

    test('template with dollar without braces warns', () {
      final query = QueryString('template:\$varName');
      final result = query.validate();

      print('\n=== Template Dollar Without Braces Test ===');
      print('Query: ${result.query}');
      print('Has Warnings: ${result.hasWarnings}');
      if (result.hasWarnings) {
        print('\nFormatted Warnings:');
        print(result.toString());
      }

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isTrue);
      expect(result.warnings[0].message, contains('without braces'));
    });

    test('valid regexp pattern does not warn', () {
      final query =
          QueryString('div/@text?transform=regexp:/test\\.com/replaced/');
      final result = query.validate();

      print('\n=== Valid Regexp Pattern Test ===');
      print('Query: ${result.query}');
      print('Has Warnings: ${result.hasWarnings}');

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isFalse);
    });

    test('valid template syntax does not warn', () {
      final query = QueryString('template:\${varName}');
      final result = query.validate();

      print('\n=== Valid Template Syntax Test ===');
      print('Query: ${result.query}');
      print('Has Warnings: ${result.hasWarnings}');

      expect(result.isValid, isTrue);
      expect(result.hasWarnings, isFalse);
    });

    test('common regexp patterns do not warn', () {
      // .* and .+ are common patterns that should not warn
      final query1 =
          QueryString('div/@text?transform=regexp:/.*test.*/replaced/');
      final result1 = query1.validate();
      expect(result1.hasWarnings, isFalse);

      final query2 =
          QueryString('div/@text?transform=regexp:/.+test.+/replaced/');
      final result2 = query2.validate();
      expect(result2.hasWarnings, isFalse);

      // ^ at start and $ at end are intentional
      final query3 =
          QueryString('div/@text?transform=regexp:/^test\$/replaced/');
      final result3 = query3.validate();
      expect(result3.hasWarnings, isFalse);
    });
  });
}
