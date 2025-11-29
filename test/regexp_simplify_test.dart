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
}
