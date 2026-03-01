import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

void main() {
  setUp(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  });

  group('Unique Transform - Simple Tests', () {
    test('remove duplicate strings from JSON array', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          ["apple", "banana", "apple", "cherry", "banana"]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, ['apple', 'banana', 'cherry']);
    });

    test('remove duplicate numbers', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          [1, 2, 3, 2, 1, 4, 3, 5]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('preserve order of first occurrence', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          ["zebra", "apple", "banana", "apple", "zebra"]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, ['zebra', 'apple', 'banana']);
    });

    test('handle empty list', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          []
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script/@text?transform=json&transform=unique')
          .execute(node);

      expect(result, isA<List>());
      expect(result, isEmpty);
    });

    test('handle single value (non-list)', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          "single"
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script/@text?transform=json&transform=unique')
          .execute(node);

      expect(result, 'single');
    });

    test('use in piped query', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          {
            "tags": ["javascript", "dart", "javascript", "flutter", "dart"]
          }
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString(
              'script/@text?transform=json >> json:tags?transform=unique')
          .execute(node);

      expect(result, isA<List>());
      expect(result, ['javascript', 'dart', 'flutter']);
    });

    test('combine with other transforms', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          ["Apple", "banana", "APPLE", "Banana"]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString(
              'script/@text?transform=json >> json:?transform=lower;unique')
          .execute(node);

      expect(result, isA<List>());
      expect(result, ['apple', 'banana']);
    });
  });
}
