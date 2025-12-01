import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Reproduction Tests', () {
    test('use variable in filter', () {
      const jsonData = '''
      {
        "filterWord": "apple",
        "items": ["apple pie", "banana bread", "apple cider", "cherry tart"]
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save filterWord, then filter items using it
      final result =
          QueryString('json:filterWord?save=fw ++ json:items/*?filter=\${fw}')
              .execute(node);

      expect(result, ['apple pie', 'apple cider']);
    });

    test('use variable in filter with keep', () {
      const jsonData = '''
      {
        "filterWord": "apple",
        "items": ["apple pie", "banana bread", "apple cider", "cherry tart"]
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save filterWord with keep, then filter items using it
      final result = QueryString(
              'json:filterWord?save=fw&keep ++ json:items/*?filter=\${fw}')
          .execute(node);

      expect(result, ['apple', 'apple pie', 'apple cider']);
    });

    test('use variable in url parameters', () {
      const jsonData = '{"newHost": "api.example.com"}';
      final pageData = PageData('https://example.com/path', '<html></html>',
          jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save newHost, then use it to modify the URL's host
      final result =
          QueryString('json:newHost?save=h ++ url:?_host=\${h}').execute(node);

      expect(result, 'https://api.example.com/path');
    });

    test('use variable in transform within QueryPart', () {
      const jsonData = '''
      {
        "pattern": "old",
        "text": "This is old text"
      }
      ''';

      final pageData =
          PageData('https://example.com', '<html></html>', jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save pattern, then use it in regexp transform
      final result =
          QueryString('json:pattern?save=p ++ json:text?regexp=/\${p}/new/')
              .execute(node);

      expect(result, 'This is new text');
    });
  });
}
