import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Operator Validation', () {
    test('valid ++ operator passes validation', () {
      final query = QueryString('json:items ++ template:result');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('valid || operator passes validation', () {
      final query = QueryString('json:items || json:fallback');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('valid >> operator passes validation', () {
      final query = QueryString('json:items >> json:name');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('valid >>> operator passes validation', () {
      final query = QueryString('*div@ >>> json:0-2');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('single + is detected as invalid operator', () {
      final query = QueryString('json:items + json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator "+"'));
      expect(result.errors[0].suggestion, contains('Did you mean "++"?'));
    });

    test('single | is detected as invalid operator', () {
      final query = QueryString('json:items | json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator "|"'));
      expect(result.errors[0].suggestion, contains('Did you mean "||"?'));
    });

    test('single > is detected as invalid operator', () {
      final query = QueryString('json:items > json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator ">"'));
      expect(
          result.errors[0].suggestion, contains('Did you mean ">>" or ">>>"?'));
    });

    test('triple + is detected as invalid operator', () {
      final query = QueryString('json:items +++ json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator "+++"'));
      expect(result.errors[0].suggestion, contains('Did you mean "++"?'));
    });

    test('triple | is detected as invalid operator', () {
      final query = QueryString('json:items ||| json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator "|||"'));
      expect(result.errors[0].suggestion, contains('Did you mean "||"?'));
    });

    test('quadruple > is detected as invalid operator', () {
      final query = QueryString('json:items >>>> json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator ">>>>"'));
      expect(
          result.errors[0].suggestion, contains('Did you mean ">>>" or ">>"?'));
    });

    test('multiple valid operators in one query pass validation', () {
      final query = QueryString('json:a ++ json:b >> json:c || json:d');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('operator without spaces is not treated as operator', () {
      // This should be valid - the ++ is part of the path, not an operator
      final query = QueryString('json:items++other');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('operator with only leading space is not treated as operator', () {
      // This should be valid - the ++ is part of the path, not an operator
      final query = QueryString('json:items ++other');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('operator with only trailing space is not treated as operator', () {
      // This should be valid - the ++ is part of the path, not an operator
      final query = QueryString('json:items++ other');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('error position is reported correctly for invalid operator', () {
      final query = QueryString('json:items + json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors[0].position, 11); // Position of the '+'
    });

    test('multiple invalid operators are all detected', () {
      final query = QueryString('json:a + json:b | json:c');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 2);
      expect(result.errors[0].message, contains('Invalid operator "+"'));
      expect(result.errors[1].message, contains('Invalid operator "|"'));
    });

    test('invalid operator in multi-part query is detected', () {
      final query =
          QueryString('json:items?save=x ++ template:\${x} + json:other');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, 1);
      expect(result.errors[0].message, contains('Invalid operator "+"'));
    });

    test('valid operators with complex query parts pass validation', () {
      final query = QueryString(
          'json:items?save=x&keep ++ json:other?transform=upper >> template:\${x}');
      final result = query.validate();

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });
  });
}
