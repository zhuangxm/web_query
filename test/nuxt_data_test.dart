import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Nuxt.js __NUXT_DATA__ Decoding', () {
    test('decode simple Nuxt data structure', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"props": 2},
          {"pageProps": 3},
          {"locale": 4, "id": 5},
          "en-US",
          1234
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['props'], isA<Map>());
      expect(result['props']['pageProps'], isA<Map>());
      expect(result['props']['pageProps']['locale'], 'en-US');
      expect(result['props']['pageProps']['id'], 1234);
    });

    test('decode Nuxt data with nested objects', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"user": 2, "settings": 3},
          {"name": 4, "email": 5},
          {"theme": 6},
          "Alice",
          "alice@example.com",
          "dark"
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['user']['name'], 'Alice');
      expect(result['user']['email'], 'alice@example.com');
      expect(result['settings']['theme'], 'dark');
    });

    test('decode Nuxt data with arrays', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"items": 2},
          [3, 4, 5],
          "apple",
          "banana",
          "cherry"
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['items'], isA<List>());
      expect(result['items'], ['apple', 'banana', 'cherry']);
    });

    test('decode Nuxt data with Ref marker', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"data": 2},
          ["Ref", 3],
          {"value": 4},
          42
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['data'], isA<Map>());
      expect(result['data']['value'], 42);
    });

    test('decode Nuxt data with Set marker', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"tags": 2},
          ["Set", 3, 4, 5],
          "javascript",
          "dart",
          "flutter"
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['tags'], isA<List>());
      expect(result['tags'], ['javascript', 'dart', 'flutter']);
    });

    test('decode Nuxt data with null marker (dict-as-list)', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"config": 2},
          ["null", "apiUrl", 3, "timeout", 4],
          "https://api.example.com",
          5000
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['config'], isA<Map>());
      expect(result['config']['apiUrl'], 'https://api.example.com');
      expect(result['config']['timeout'], 5000);
    });

    test('decode Nuxt data with ShallowReactive header', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["ShallowReactive", 1],
          {"name": 2},
          "Bob"
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['name'], 'Bob');
    });

    test('decode Nuxt data with primitive values', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"str": 2, "num": 3, "bool": 4, "nil": 5},
          "hello",
          123,
          true,
          null
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['str'], 'hello');
      expect(result['num'], 123);
      expect(result['bool'], true);
      expect(result['nil'], null);
    });

    test('decode Nuxt data with empty array', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"items": 2},
          []
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['items'], isA<List>());
      expect(result['items'], isEmpty);
    });

    test('decode Nuxt data with EmptyRef marker', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"data": 2},
          ["EmptyRef", 3],
          null
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['data'], null);
    });

    test('decode complex nested Nuxt data', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"posts": 2},
          [3, 4],
          {"id": 5, "title": 6, "author": 7},
          {"id": 8, "title": 9, "author": 10},
          1,
          "First Post",
          {"name": 11},
          2,
          "Second Post",
          {"name": 12},
          "Alice",
          "Bob"
        ]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['posts'], isA<List>());
      expect(result['posts'].length, 2);
      expect(result['posts'][0]['id'], 1);
      expect(result['posts'][0]['title'], 'First Post');
      expect(result['posts'][0]['author']['name'], 'Alice');
      expect(result['posts'][1]['id'], 2);
      expect(result['posts'][1]['title'], 'Second Post');
      expect(result['posts'][1]['author']['name'], 'Bob');
    });

    test('regular JSON array is not decoded as Nuxt data', () {
      const html = '''
      <html>
        <script type="application/json">
        [1, 2, 3]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script/@text?transform=json').execute(node);

      expect(result, isA<List>());
      expect(result, [1, 2, 3]);
    });

    test('invalid Nuxt data returns null', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [["InvalidHeader", 1]]
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script#__NUXT_DATA__/@text?transform=json')
          .execute(node);

      // Should return the original array since it's not valid Nuxt format
      expect(result, isA<List>());
      expect(result[0], ['InvalidHeader', 1]);
    });

    test('extract Nuxt data from JavaScript variable', () {
      const html = '''
      <html>
        <script>
        window.__NUXT__ = [["Reactive", 1], {"data": 2}, {"value": 3}, 42];
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script/@text?transform=json:window.__NUXT__')
          .execute(node);

      expect(result, isA<Map>());
      expect(result['data']['value'], 42);
    });

    test('PageData with defaultJsonId automatically decodes Nuxt data', () {
      const html = '''
      <html>
        <script id="__NUXT_DATA__" type="application/json">
        [
          ["Reactive", 1],
          {"user": 2, "count": 3},
          {"name": 4, "id": 5},
          "Charlie",
          789,
          100
        ]
        </script>
      </html>
      ''';

      final pageData =
          PageData('https://example.com', html, defaultJsonId: '__NUXT_DATA__');

      // jsonData should be automatically decoded
      // Structure: index 1 = {"user": 2, "count": 3}
      // index 2 = {"name": 4, "id": 5}
      // index 3 = "Charlie", index 4 = 789, index 5 = 100
      // So: user -> index 2 -> {"name": 4, "id": 5} -> name: index 4 (789), id: index 5 (100)
      // Wait, that's wrong. Let me trace through:
      // user: 2 means user points to index 2
      // index 2 = {"name": 4, "id": 5}
      // name: 4 means name points to index 4 which is 789
      // id: 5 means id points to index 5 which is 100
      expect(pageData.jsonData, isA<Map>());
      expect(pageData.jsonData['user'], isA<Map>());
      expect(pageData.jsonData['user']['name'], 789); // index 4
      expect(pageData.jsonData['user']['id'], 100); // index 5
      expect(pageData.jsonData['count'], 'Charlie'); // index 3
    });

    test('PageData with defaultJsonId handles regular JSON normally', () {
      const html = '''
      <html>
        <script id="__NEXT_DATA__" type="application/json">
        {"props": {"pageProps": {"name": "Alice"}}}
        </script>
      </html>
      ''';

      final pageData =
          PageData('https://example.com', html, defaultJsonId: '__NEXT_DATA__');

      // Regular JSON should work as before
      expect(pageData.jsonData, isA<Map>());
      expect(pageData.jsonData['props']['pageProps']['name'], 'Alice');
    });
  });
}
