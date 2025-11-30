import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Variables and Templates', () {
    test('save variable and use in template', () {
      const jsonData = '''
      {
        "user": {
          "firstName": "Alice",
          "lastName": "Smith"
        }
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save firstName and lastName, then combine
      // ++ collects all results
      final result = QueryString(
              'json:user/firstName?save=fn ++ json:user/lastName?save=ln ++ template:\${fn} \${ln}')
          .execute(node);

      expect(result, ['Alice', 'Smith', 'Alice Smith']);
    });

    test('use variable in regex', () {
      const html = '''
      <html>
        <div id="config">old_value</div>
        <div id="content">This is old_value content</div>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Get config value, then replace it in content
      final result = QueryString(
              '#config/@text?save=val ++ #content/@text?regexp=/\${val}/new_value/')
          .execute(node);

      expect(result, ['old_value', 'This is new_value content']);
    });

    test('use variable in path', () {
      const jsonData = '''
      {
        "selectedId": "item2",
        "items": {
          "item1": "First Item",
          "item2": "Second Item"
        }
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Get selectedId, then query items with that ID (using ++ to keep root context)
      final result = QueryString('json:selectedId?save=id ++ json:items/\${id}')
          .execute(node);

      expect(result, ['item2', 'Second Item']);
    });

    test('template scheme', () {
      const jsonData = '{"id": 123}';
      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      final result = QueryString('json:id?save=id ++ template:The ID is \${id}')
          .execute(node);

      expect(result, [123, 'The ID is 123']);
    });

    test('variable scope in piping', () {
      const jsonData = '''
      {
        "item": {"name": "A", "value": 1}
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Variables should be available across pipes
      QueryString(
              'json:item >> json:name?save=n ++ json:value?save=v ++ template:\${n}:\${v}')
          .execute(node);

      // Note: ++ json:value executes on the ROOT node (which is the item passed from pipe)
      // Wait, if we pipe 'json:item', the next query 'json:name' receives the item.
      // But '++ json:value' receives... the original node?
      // No, '++' combines results. But what is its input?
      // In _executeQueries:
      // if (query.isPipe) { result = result_; }
      // else { result_ = _executeSingleQuery(query, node); }
      // 'node' is the original input to execute().
      // So '++' ALWAYS uses the original input.

      // So to make this work, we need to extract from original input:
      // json:item/name?save=n ++ json:item/value?save=v ++ template:${n}:${v}

      final result2 = QueryString(
              'json:item/name?save=n ++ json:item/value?save=v ++ template:\${n}:\${v}')
          .execute(node);

      expect(result2, ['A', 1, 'A:1']);
    });
  });
}
