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
  group('Unique Transform', () {
    test('remove duplicate strings', () {
      const html = '''
      <html>
        <body>
          <div class="item">apple</div>
          <div class="item">banana</div>
          <div class="item">apple</div>
          <div class="item">cherry</div>
          <div class="item">banana</div>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('*div.item/@text?transform=unique').execute(node);

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
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('remove duplicate objects with deep equality', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          [
            {"id": 1, "name": "Alice"},
            {"id": 2, "name": "Bob"},
            {"id": 1, "name": "Alice"},
            {"id": 3, "name": "Charlie"},
            {"id": 2, "name": "Bob"}
          ]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result.length, 3);
      expect(result[0], {'id': 1, 'name': 'Alice'});
      expect(result[1], {'id': 2, 'name': 'Bob'});
      expect(result[2], {'id': 3, 'name': 'Charlie'});
    });

    test('remove duplicate nested arrays', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          [[1, 2], [3, 4], [1, 2], [5, 6], [3, 4]]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result.length, 3);
      expect(result[0], [1, 2]);
      expect(result[1], [3, 4]);
      expect(result[2], [5, 6]);
    });

    test('handle mixed types', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          [1, "1", 2, "2", 1, "1", 3]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, [1, "1", 2, "2", 3]);
    });

    test('preserve order of first occurrence', () {
      const html = '''
      <html>
        <body>
          <div class="item">zebra</div>
          <div class="item">apple</div>
          <div class="item">banana</div>
          <div class="item">apple</div>
          <div class="item">zebra</div>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('*div.item/@text?transform=unique').execute(node);

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

      final result =
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, null);
    });

    test('handle single value (non-list)', () {
      const html = '''
      <html>
        <body>
          <div class="item">single</div>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('div.item/@text?transform=unique').execute(node);

      expect(result, 'single');
    });

    test('handle null values in list', () {
      const html = '''
      <html>
        <body>
          <script type="application/json">
          [1, null, 2, null, 3, null]
          </script>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json >> json:*?transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, [1, 2, 3]);
    });

    test('distinct alias works', () {
      const html = '''
      <html>
        <body>
          <div class="item">apple</div>
          <div class="item">banana</div>
          <div class="item">apple</div>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('*div.item/@text?transform=unique').execute(node);

      expect(result, isA<List>());
      expect(result, ['apple', 'banana']);
    });

    test('combine with other transforms', () {
      const html = '''
      <html>
        <body>
          <div class="item">Apple</div>
          <div class="item">banana</div>
          <div class="item">APPLE</div>
          <div class="item">Banana</div>
        </body>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('*div.item/@text?transform=lower&transform=unique')
              .execute(node);

      expect(result, isA<List>());
      expect(result, ['apple', 'banana']);
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
  });
}
