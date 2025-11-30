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

      // Save firstName and lastName (auto-discarded), then show template
      final result = QueryString(
              'json:user/firstName?save=fn ++ json:user/lastName?save=ln ++ template:\${fn} \${ln}')
          .execute(node);

      expect(result, 'Alice Smith');
    });

    test('save with keep preserves intermediate values', () {
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

      // Save with keep to preserve intermediate values
      final result = QueryString(
              'json:user/firstName?save=fn&keep ++ json:user/lastName?save=ln&keep ++ template:\${fn} \${ln}')
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

      // Get config value (auto-discarded), then replace it in content
      final result = QueryString(
              '#config/@text?save=val ++ #content/@text?regexp=/\${val}/new_value/')
          .execute(node);

      expect(result, 'This is new_value content');
    });

    test('use variable in regex with keep', () {
      const html = '''
      <html>
        <div id="config">old_value</div>
        <div id="content">This is old_value content</div>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Get config value with keep, then replace it in content
      final result = QueryString(
              '#config/@text?save=val&keep ++ #content/@text?regexp=/\${val}/new_value/')
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

      // Get selectedId (auto-discarded), then query items with that ID
      final result = QueryString('json:selectedId?save=id ++ json:items/\${id}')
          .execute(node);

      expect(result, 'Second Item');
    });

    test('use variable in path with keep', () {
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

      // Get selectedId with keep, then query items with that ID
      final result =
          QueryString('json:selectedId?save=id&keep ++ json:items/\${id}')
              .execute(node);

      expect(result, ['item2', 'Second Item']);
    });

    test('template scheme', () {
      const jsonData = '{"id": 123}';
      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // save auto-discards, only template result is returned
      final result = QueryString('json:id?save=id ++ template:The ID is \${id}')
          .execute(node);

      expect(result, 'The ID is 123');
    });

    test('template scheme with keep', () {
      const jsonData = '{"id": 123}';
      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // save with keep preserves the id value
      final result =
          QueryString('json:id?save=id&keep ++ template:The ID is \${id}')
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

      // Variables are auto-discarded with save, only template is returned
      final result = QueryString(
              'json:item/name?save=n ++ json:item/value?save=v ++ template:\${n}:\${v}')
          .execute(node);

      expect(result, 'A:1');
    });

    test('variable scope with keep', () {
      const jsonData = '''
      {
        "item": {"name": "A", "value": 1}
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // With keep, intermediate values are preserved
      final result = QueryString(
              'json:item/name?save=n&keep ++ json:item/value?save=v&keep ++ template:\${n}:\${v}')
          .execute(node);

      expect(result, ['A', 1, 'A:1']);
    });
  });
}
