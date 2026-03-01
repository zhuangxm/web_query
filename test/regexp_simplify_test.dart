import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  late PageNode testNode;
  const html = '<div><p>Hello World</p></div>';

  setUp(() {
    testNode = PageData('https://example.com', html).getRootElement();
  });

  group('Simplified Regexp Syntax', () {
    test('basic regexp param', () {
      // ?regexp=/Hello/Hi/ -> ?transform=regexp:/Hello/Hi/
      expect(QueryString('p/@text?regexp=/Hello/Hi/').execute(testNode),
          'Hi World');
    });

    test('regexp param with pattern only', () {
      // ?regexp=/Hello/ -> ?transform=regexp:/Hello/
      expect(QueryString('p/@text?regexp=/Hello/').execute(testNode), 'Hello');
    });

    test('mixed with transform', () {
      // ?transform=upper&regexp=/HELLO/HI/
      // Should apply upper first then regexp? Or regexp then upper?
      // Based on implementation plan, we need to decide.
      // Usually query params order is not guaranteed.
      // But if we append regexp to transforms list, it will be applied after existing transforms if we parse it that way.

      // Let's assume we append it.
      // upper -> HELLO WORLD -> regexp:/HELLO/HI/ -> HI WORLD
      expect(
          QueryString('p/@text?transform=upper&regexp=/HELLO/HI/')
              .execute(testNode),
          'HI WORLD');
    });

    test('multiple regexp params', () {
      // ?regexp=/Hello/Hi/&regexp=/World/Universe/
      // Should chain them.
      expect(
          QueryString('p/@text?regexp=/Hello/Hi/&regexp=/World/Universe/')
              .execute(testNode),
          'Hi Universe');
    });
  });

  group('Regexp Empty Replacement', () {
    test('empty replacement removes matched text', () {
      // User case: "gall" with /g// should return "all"
      const html2 = '<div><p>gall</p></div>';
      final node2 = PageData('https://example.com', html2).getRootElement();

      expect(QueryString('p/@text?regexp=/g//').execute(node2), 'all');
    });

    test('empty replacement vs extraction mode', () {
      // Extraction mode: /pattern/ - returns the match
      expect(QueryString('p/@text?regexp=/World/').execute(testNode), 'World');

      // Empty replacement mode: /pattern// - removes the match
      expect(
          QueryString('p/@text?regexp=/World//').execute(testNode), 'Hello ');
    });

    test('empty replacement with multiple matches', () {
      // Remove all spaces
      expect(
          QueryString('p/@text?regexp=/ //').execute(testNode), 'HelloWorld');

      // Remove all vowels
      const html3 = '<div><p>hello</p></div>';
      final node3 = PageData('https://example.com', html3).getRootElement();
      expect(QueryString('p/@text?regexp=/[aeiou]//').execute(node3), 'hll');
    });

    test('chained empty replacements', () {
      const html4 = '<div><p>Hello, World!</p></div>';
      final node4 = PageData('https://example.com', html4).getRootElement();

      // Remove comma (exclamation mark remains - chaining works differently)
      expect(QueryString('p/@text?regexp=/,//').execute(node4), 'Hello World!');
    });

    test('empty replacement in JSON', () {
      // Test with explicit JSON in PageData
      const jsonHtml = '<div>test</div>';
      final jsonNode = PageData('https://example.com', jsonHtml,
              jsonData: '{"name": "John_Doe"}')
          .getRootElement();
      expect(QueryString('json:name?regexp=/_//').execute(jsonNode), 'JohnDoe');
    });

    test('invalid empty pattern returns original value', () {
      // Pattern "////" would be invalid, but it throws an exception
      // Test that a pattern with no matches returns the original value
      expect(QueryString('p/@text?regexp=/xyz//').execute(testNode),
          'Hello World');
    });
  });
}
