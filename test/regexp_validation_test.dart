import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Regexp Pattern Validation', () {
    test('\\d+ pattern should not warn', () {
      final query = QueryString('json:items?transform=regexp:/\\d+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, false,
          reason: '\\d+ is a valid regex pattern and should not warn');
    });

    test('\\w+ pattern should not warn', () {
      final query = QueryString('json:items?transform=regexp:/\\w+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, false,
          reason: '\\w+ is a valid regex pattern and should not warn');
    });

    test('[a-z]+ pattern should not warn', () {
      final query = QueryString('json:items?transform=regexp:/[a-z]+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, false,
          reason: '[a-z]+ is a valid regex pattern and should not warn');
    });

    test('.+ pattern should not warn', () {
      final query = QueryString('json:items?transform=regexp:/.+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, false,
          reason: '.+ is a common regex pattern and should not warn');
    });

    test('(abc)+ pattern should not warn', () {
      final query = QueryString('json:items?transform=regexp:/(abc)+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, false,
          reason: '(abc)+ is a valid regex pattern and should not warn');
    });

    test('literal + after text should warn', () {
      final query = QueryString('json:items?transform=regexp:/test+/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, true,
          reason: 'Unescaped + after literal text is likely a mistake');
      expect(
          result.warnings[0].message, contains('Unescaped special character'));
    });

    test('test.com pattern should warn about unescaped dot', () {
      final query =
          QueryString('div/@text?transform=regexp:/test.com/replaced/');
      final result = query.validate();

      expect(result.isValid, true);
      expect(result.hasWarnings, true);
      expect(result.warnings[0].message,
          contains('Unescaped special character "."'));
    });
  });
}
