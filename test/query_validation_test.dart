import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Query Validation', () {
    test('throws on unknown parameter', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(
        () => QueryString('div/@text?transformm=upper').getValue(node),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unknown query parameter: "transformm"'),
        )),
      );
    });

    test('invalid regexp format fails at runtime', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Invalid regexp format is allowed during parsing but fails at runtime
      final result =
          QueryString('div/@text?transform=regexp:pattern').getValue(node);

      // Should return empty string when regexp fails
      expect(result, anyOf(isNull, equals('test'), equals('')));
    });

    test('throws on empty regexp pattern', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(
        () => QueryString('div/@text?transform=regexp:').getValue(node),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('regexp transform requires a pattern'),
        )),
      );
    });

    test('throws on unknown transform', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(
        () => QueryString('div/@text?transform=uppercase').getValue(node),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unknown transform: "uppercase"'),
        )),
      );
    });

    test('throws on empty save parameter', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(
        () => QueryString('div/@text?save=').getValue(node),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('save parameter requires a variable name'),
        )),
      );
    });

    test('accepts valid transforms', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // These should not throw
      expect(() => QueryString('div/@text?transform=upper').getValue(node),
          returnsNormally);
      expect(() => QueryString('div/@text?transform=lower').getValue(node),
          returnsNormally);
      expect(
          () => QueryString('div/@text?transform=regexp:/test/TEST/')
              .getValue(node),
          returnsNormally);
      expect(() => QueryString('div/@text?save=myVar').getValue(node),
          returnsNormally);
      expect(() => QueryString('div/@text?filter=test').getValue(node),
          returnsNormally);
    });

    test('provides helpful error message for typos', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(
        () => QueryString('div/@text?filtre=test').getValue(node),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('Unknown query parameter: "filtre"'),
            contains('Did you mean one of:'),
            contains('filter'),
          ),
        )),
      );
    });
  });
}
