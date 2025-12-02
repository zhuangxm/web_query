import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Index Parameter', () {
    test('Static index - get 3rd element', () {
      const html = '''
      <html>
        <div>item0</div>
        <div>item1</div>
        <div>item2</div>
        <div>item3</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result = QueryString('*div@?index=2').execute(node);

      print('Result: $result');
      expect(result, 'item2');
    });

    test('Negative index - get last element', () {
      const html = '''
      <html>
        <div>item0</div>
        <div>item1</div>
        <div>item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result = QueryString('*div@?index=-1').execute(node);

      print('Result: $result');
      expect(result, 'item2');
    });

    test('Index with variable', () {
      const html = '''
      <html>
        <a href="/video/2">Link</a>
        <div>item0</div>
        <div>item1</div>
        <div>item2</div>
        <div>item3</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result =
          QueryString('a@href?regexp=/\\d+/&save=idx ++ *div@?index=\${idx}')
              .execute(node);

      print('Result: $result');
      expect(result, 'item2');
    });

    test('Index out of bounds returns null', () {
      const html = '<html><div>item0</div></html>';
      final node = PageData('https://example.com', html).getRootElement();

      final result = QueryString('*div@?index=999').execute(node);
      expect(result, isNull);
    });

    test('Index on empty list returns null', () {
      const html = '<html></html>';
      final node = PageData('https://example.com', html).getRootElement();

      final result = QueryString('*div@?index=0').execute(node);
      expect(result, isNull);
    });

    test('Index combined with transform', () {
      const html = '''
      <html>
        <div>hello</div>
        <div>world</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result = QueryString('*div@?index=1&transform=upper').execute(node);

      print('Result: $result');
      expect(result, 'WORLD');
    });

    test('Index on non-list value', () {
      const html = '<div>single</div>';
      final node = PageData('https://example.com', html).getRootElement();

      // index=0 should return the value
      final result1 = QueryString('div@?index=0').execute(node);
      expect(result1, 'single');

      // index=1 should return null
      final result2 = QueryString('div@?index=1').execute(node);
      expect(result2, isNull);
    });

    test('User scenario: extract index from href and use it', () {
      const html = '''
      <html>
        <div class="module-play-list">
          <a href="/video/2">Video 2</a>
        </div>
        <div class="module-tab-item">["ep0", "ep1", "ep2", "ep3"]</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result = QueryString(
              '.module-play-list a@href?regexp=/\\d+/&save=idx ++ .module-tab-item@?transform=json >> json:\${idx}')
          .execute(node);

      print('Result: $result');
      expect(result, 'ep2');
    });

    test('User scenario: get nth item from HTML elements', () {
      const html = '''
      <html>
        <a href="/page/1">Link</a>
        <div class="module-tab-item">item0</div>
        <div class="module-tab-item">item1</div>
        <div class="module-tab-item">item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();
      final result = QueryString(
              'a@href?regexp=/\\d+/&save=idx ++ *.module-tab-item@?index=\${idx}')
          .execute(node);

      print('Result: $result');
      expect(result, 'item1');
    });
  });
}
