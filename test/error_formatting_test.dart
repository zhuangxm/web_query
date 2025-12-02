import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Error Formatting and Position Tracking', () {
    test('error includes query part index for multi-part queries', () {
      final query = QueryString('html:div ++ jsn:items ++ url:_host');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));

      // The error should be in the second query part (index 1)
      expect(result.errors.first.queryPartIndex, equals(1));

      // The formatted error should mention the query part
      final formatted = result.errors.first.format(query.query!);
      expect(formatted, contains('in query part 2'));
    });

    test('error formatting shows snippet for long queries', () {
      // Create a very long query
      final longQuery =
          'html:div/span/p/a/strong/em/code/pre/blockquote/ul/li ++ jsn:items/data/values/results/output/final';
      final query = QueryString(longQuery);
      final result = query.validate();

      expect(result.isValid, isFalse);

      final formatted = result.errors.first.format(longQuery);

      // Should show a snippet with ellipsis, not the entire query
      expect(formatted, contains('...'));
      expect(formatted, contains('jsn'));
    });

    test('error formatting shows full query for short queries', () {
      final shortQuery = 'jsn:items';
      final query = QueryString(shortQuery);
      final result = query.validate();

      expect(result.isValid, isFalse);

      final formatted = result.errors.first.format(shortQuery);

      // Should show the full query without ellipsis
      expect(formatted, isNot(contains('...')));
      expect(formatted, contains('Query: jsn:items'));
    });

    test('error pointer aligns correctly with error position', () {
      final query = QueryString('html:div ++ jsn:items');
      final result = query.validate();

      expect(result.isValid, isFalse);

      final formatted = result.errors.first.format(query.query!);
      final lines = formatted.split('\n');

      // Find the query line and pointer line
      int queryLineIndex = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('Query:')) {
          queryLineIndex = i;
          break;
        }
      }

      expect(queryLineIndex, greaterThan(-1));

      // The next line should be the pointer
      if (queryLineIndex + 1 < lines.length) {
        final pointerLine = lines[queryLineIndex + 1];
        expect(pointerLine, contains('^'));
      }
    });

    test('multiple errors in different parts show correct part indices', () {
      final query = QueryString('jsn:items ++ htm:div ++ urll:_host');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(3));

      // Each error should have the correct part index
      expect(result.errors[0].queryPartIndex, equals(0));
      expect(result.errors[1].queryPartIndex, equals(1));
      expect(result.errors[2].queryPartIndex, equals(2));
    });

    test('error in first part has part index 0', () {
      final query = QueryString('jsn:items ++ html:div');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.queryPartIndex, equals(0));
    });

    test('operator errors do not have part index', () {
      final query = QueryString('html:div + json:items');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));

      // Operator errors span across parts, so no specific part index
      expect(result.errors.first.queryPartIndex, isNull);
    });

    test('parameter error includes part index', () {
      final query = QueryString('html:div ++ json:items?save=x?keep');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.queryPartIndex, equals(1));

      final formatted = result.errors.first.format(query.query!);
      expect(formatted, contains('in query part 2'));
    });

    test('variable error includes part index', () {
      final query = QueryString('html:div ++ template:\${unclosed');
      final result = query.validate();

      expect(result.isValid, isFalse);
      expect(result.errors.length, equals(1));
      expect(result.errors.first.queryPartIndex, equals(1));
    });

    test('toMap includes queryPartIndex when present', () {
      final query = QueryString('html:div ++ jsn:items');
      final result = query.validate();

      expect(result.isValid, isFalse);

      final errorMap = result.errors.first.toMap();
      expect(errorMap, containsPair('queryPartIndex', 1));
    });

    test('toJson includes queryPartIndex in JSON output', () {
      final query = QueryString('html:div ++ jsn:items');
      final result = query.validate();

      expect(result.isValid, isFalse);

      final json = result.toJson();
      expect(json, contains('"queryPartIndex":1'));
    });
  });
}
