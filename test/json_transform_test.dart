import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('JSON Transform', () {
    test('extract JSON from script tag', () {
      const html = '''
      <html>
        <script type="application/json" id="data">
        {"name": "Alice", "age": 30}
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Extract and parse JSON
      final result =
          QueryString('script#data/@text?transform=json').execute(node);

      expect(result, isA<Map>());
      expect(result['name'], 'Alice');
      expect(result['age'], 30);
    });

    test('extract JSON from JavaScript variable', () {
      const html = '''
      <html>
        <script>
        var config = {"apiUrl": "https://api.example.com", "timeout": 5000};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:config').execute(node);

      expect(result, isA<Map>());
      expect(result['apiUrl'], 'https://api.example.com');
      expect(result['timeout'], 5000);
    });

    test('extract JSON from window variable', () {
      const html = '''
      <html>
        <script>
        window.__INITIAL_STATE__ = {"user": {"id": 123, "name": "Bob"}};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:window.__INITIAL_STATE__')
              .execute(node);

      expect(result, isA<Map>());
      expect(result['user']['id'], 123);
      expect(result['user']['name'], 'Bob');
    });

    test('extract JSON array from variable', () {
      const html = '''
      <html>
        <script>
        var items = [{"id": 1}, {"id": 2}, {"id": 3}];
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:items').execute(node);

      expect(result, isA<List>());
      expect(result.length, 3);
      expect(result[0]['id'], 1);
    });

    test('chain json transform with json query', () {
      const html = '''
      <html>
        <script id="__NEXT_DATA__" type="application/json">
        {"props": {"pageProps": {"posts": [{"title": "First Post"}, {"title": "Second Post"}]}}}
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // This won't work directly because json transform returns an object, not a PageNode
      // We need to use it differently - extract JSON first, then create new PageData
      final jsonText = QueryString('script#__NEXT_DATA__/@text').getValue(node);

      final newPageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonText);
      final newNode = newPageData.getRootElement();

      final titles = QueryString('json:props/pageProps/posts/*/title')
          .getCollectionValue(newNode);

      expect(titles, ['First Post', 'Second Post']);
    });

    test('handle invalid JSON gracefully', () {
      const html = '''
      <html>
        <script>
        var invalid = {not valid json};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:invalid').execute(node);

      expect(result, isNull);
    });
  });
}
