import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Advanced Query Features', () {
    test('wildcard JSON variable matching', () {
      const html = '''
      <html>
        <script>
        var myConfigData = {"id": 1};
        window.__APP_STATE__ = {"user": "admin"};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Match *Config*
      final config =
          QueryString('script/@text?transform=json:*Config*').execute(node);
      expect(config['id'], 1);

      // Match *STATE*
      final state =
          QueryString('script/@text?transform=json:*STATE*').execute(node);
      expect(state['user'], 'admin');
    });

    test('JSON keys extraction', () {
      const jsonData = '''
      {
        "users": {
          "alice": {"age": 30},
          "bob": {"age": 25}
        }
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      final keys = QueryString('json:users/@keys').execute(node);
      expect(keys, ['alice', 'bob']);
    });

    test('query piping (>>)', () {
      const html = '''
      <html>
        <div class="container">
          <p>Item 1</p>
          <p>Item 2</p>
        </div>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Pipe: Get container -> Get paragraphs -> Get text
      final result = QueryString('.container >> *p >> @text').execute(node);
      expect(result, ['Item 1', 'Item 2']);

      // Pipe with transforms
      final result2 =
          QueryString('.container >> *p/@text?transform=upper').execute(node);
      expect(result2, ['ITEM 1', 'ITEM 2']);
    });

    test('query piping with JSON', () {
      const jsonData = '''
      {
        "items": [
          {"id": 1, "tags": ["a", "b"]},
          {"id": 2, "tags": ["c", "d"]}
        ]
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Pipe: Get items -> Get tags -> Get all tags flattened
      final tags = QueryString('json:items/* >> json:tags/*').execute(node);
      expect(tags, ['a', 'b', 'c', 'd']);
    });

    test('combined advanced features', () {
      const html = '''
      <html>
        <script>
        var data = {
          "users": {
            "u1": {"name": "Alice"},
            "u2": {"name": "Bob"}
          }
        };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Extract JSON -> Get users -> Get keys
      final userIds =
          QueryString('script/@text?transform=json:data >> json:users/@keys')
              .execute(node);

      expect(userIds, ['u1', 'u2']);
    });
  });
}
