import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('RegExp S Flag Tests', () {
    test('Should handle s flag in three-part regexp', () {
      final parsed = parseRegexpPattern(r'/a/b/s/');
      expect(parsed, isNotNull);
      expect(parsed!.pattern, equals('a'));
      expect(parsed.replacement, equals('b'));
      expect(parsed.hasReplacement, isFalse,
          reason: 'Three parts with "s" should not be replaceMode');
    });

    test('Should handle s flag in three-part regexp without ending slash', () {
      final parsed = parseRegexpPattern(r'/a/b/s');
      expect(parsed, isNotNull);
      expect(parsed!.pattern, equals('a'));
      expect(parsed.replacement, equals('b'));
      expect(parsed.hasReplacement, isFalse,
          reason: 'Three parts with "s" should not be replaceMode');
    });

    test('Should apply only first match when s flag is used', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = applyRegexpTransform(node, 'aaaaa', r'/a/b/s/');
      expect(result, equals('b'),
          reason:
              'Should only return the result of the first match when s flag is used (extraction mode)');
    });

    test('Should still handle normal replacement without s flag', () {
      const html = '<div>test</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = applyRegexpTransform(node, 'aaaaa', r'/a/b/');
      expect(result, equals('bbbbb'),
          reason: 'Should replace all occurrences when s flag is NOT used');
    });
    test(
        'Should handle s flag in two-part regexp (not requested but good to know)',
        () {
      final parsed = parseRegexpPattern(r'/a/s/');
      // Current behavior based on "three parts" rule:
      expect(parsed, isNotNull);
      expect(parsed!.pattern, equals('a'));
      expect(parsed.replacement, equals('s'));
      expect(parsed.hasReplacement, isTrue,
          reason:
              'Only two parts, so it should be replaceMode with "s" as replacement');
    });
  });
}
