import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Variable Syntax Validation', () {
    test('valid variable syntax passes validation', () {
      final query = QueryString('template:\${varName}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('unmatched opening bracket throws error', () {
      final query = QueryString('template:\${varName');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors[0].message, contains('Unmatched "\${"'));
      expect(result.errors[0].position, equals(9)); // Position of ${
    });

    test('multiple variables all matched passes validation', () {
      final query = QueryString('template:\${var1} and \${var2}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('multiple variables with one unmatched throws error', () {
      final query = QueryString('template:\${var1} and \${var2');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors[0].message, contains('Unmatched "\${"'));
      expect(result.errors[0].position, equals(21)); // Position of second ${
    });

    test('nested variables are handled correctly', () {
      final query = QueryString('template:\${outer\${inner}}');
      final result = query.validate();

      // Nested variables are matched correctly (depth tracking handles this)
      // The outer ${ opens, inner ${ opens (depth=2), inner } closes (depth=1), outer } closes (depth=0)
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('closing bracket without opening is ignored', () {
      final query = QueryString('template:test}value');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('variable in multi-part query', () {
      final query = QueryString('json:name?save=n ++ template:\${n}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('unmatched variable in multi-part query reports correct position', () {
      final query = QueryString('json:name?save=n ++ template:\${n');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors[0].message, contains('Unmatched "\${"'));
      // Position should account for the first part and operator
      expect(result.errors[0].position, greaterThan(20));
    });

    test('error message includes example', () {
      final query = QueryString('template:\${varName');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors[0].example, contains('\${varName}'));
    });
  });
}
