import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Scheme Validation', () {
    test('valid schemes pass validation', () {
      final queries = [
        'html:div',
        'json:items',
        'url:_host',
        'template:\${var}',
        'div', // defaults to html
      ];

      for (var query in queries) {
        final result = QueryString(query).validate();
        expect(result.isValid, isTrue,
            reason: 'Query "$query" should be valid');
      }
    });

    test('invalid scheme is detected', () {
      final query = QueryString('jsn:items');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.message, contains('Invalid scheme "jsn"'));
      expect(result.errors.first.suggestion, contains('Did you mean "json"?'));
      expect(result.errors.first.example,
          contains('Valid schemes: html, json, url, template'));
    });

    test('missing colon after scheme is detected', () {
      final query = QueryString('json items');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.message, contains('Missing ":" after scheme'));
      expect(result.errors.first.suggestion, contains('Use: json:path'));
    });

    test('typo suggestions work for schemes', () {
      final testCases = {
        'jsn:items': 'json',
        'htm:div': 'html',
        'urll:_host': 'url',
        'templat:\${x}': 'template',
      };

      for (var entry in testCases.entries) {
        final query = QueryString(entry.key);
        final result = query.validate();

        expect(result.isValid, isFalse,
            reason: 'Query "${entry.key}" should be invalid');
        expect(result.errors.first.suggestion, contains(entry.value),
            reason: 'Query "${entry.key}" should suggest "${entry.value}"');
      }
    });

    test('multiple query parts are validated', () {
      final query = QueryString('jsn:items ++ htm:div');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(2));
      expect(result.errors[0].message, contains('Invalid scheme "jsn"'));
      expect(result.errors[1].message, contains('Invalid scheme "htm"'));
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

    test('error position is reported correctly', () {
      final query = QueryString('html:div ++ jsn:items');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      // Position should be at the start of 'jsn' (after 'html:div ++ ')
      expect(result.errors.first.position, equals(12));
    });

    test('toString formats errors nicely', () {
      final query = QueryString('jsn:items');
      final result = query.validate();

      final formatted = result.toString();
      expect(formatted, contains('Error at position 0'));
      expect(formatted, contains('Invalid scheme "jsn"'));
      expect(formatted, contains('Query: jsn:items'));
      expect(formatted, contains('Did you mean "json"?'));
    });

    test('toJson returns valid JSON', () {
      final query = QueryString('jsn:items');
      final result = query.validate();

      final json = result.toJson();
      expect(json, isNotEmpty);
      expect(json, contains('"isValid":false'));
      expect(json, contains('"errors"'));
    });
  });
}
