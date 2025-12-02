import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Parameter Validation', () {
    test('valid single ? parameter passes validation', () {
      final query = QueryString('json:items?save=x');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors.length, equals(0));
    });

    test('valid ? and & parameters pass validation', () {
      final query = QueryString('json:items?save=x&keep');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors.length, equals(0));
    });

    test('multiple ? without & is detected', () {
      final query = QueryString('json:items?save=x?keep');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.message,
          contains('Multiple "?" found in parameters'));
      expect(result.errors.first.suggestion,
          contains('Replace additional "?" with "&"'));
      expect(
          result.errors.first.example, contains('?param1=value&param2=value'));
    });

    test('error position is correct for parameter error', () {
      final query = QueryString('json:items?save=x?keep');
      final result = query.validate();

      expect(result.isValid, isFalse);
      // Position should be at the second ? (after 'json:items?save=x')
      expect(result.errors.first.position, equals(17));
    });

    test('multiple ? in multi-part query is detected', () {
      final query = QueryString('json:items?save=x?keep ++ template:\${x}');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.message,
          contains('Multiple "?" found in parameters'));
    });

    test('valid parameters in multi-part query pass validation', () {
      final query = QueryString('json:items?save=x&keep ++ template:\${x}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors.length, equals(0));
    });

    test('three ? characters are all detected', () {
      final query = QueryString('json:items?save=x?keep?filter=test');
      final result = query.validate();

      expect(result.isValid, isFalse);
      // Should report errors for the 2nd and 3rd ?
      expect(result.errors.length, equals(2));
      expect(result.errors[0].message,
          contains('Multiple "?" found in parameters'));
      expect(result.errors[1].message,
          contains('Multiple "?" found in parameters'));
    });

    test('validation does not affect query execution', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final query = QueryString('div/@text');

      // Validate first
      final result = query.validate();
      expect(result.isValid, isTrue);

      // Execute should still work
      final value = query.getValue(node);
      expect(value, equals('test'));
    });

    test('toString formats parameter errors nicely', () {
      final query = QueryString('json:items?save=x?keep');
      final result = query.validate();

      final formatted = result.toString();
      expect(formatted, contains('Error at position 17'));
      expect(formatted, contains('Multiple "?" found in parameters'));
      expect(formatted, contains('Query: json:items?save=x?keep'));
      expect(formatted, contains('Replace additional "?" with "&"'));
    });
  });
}
