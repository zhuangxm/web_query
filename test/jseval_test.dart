import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Configure JavaScript executor
    configureJsExecutor(FlutterJsExecutor());
  });

  group('JavaScript Evaluation', () {
    test('extract simple variable', () {
      const html = '''
      <html>
        <script>
          var config = {"apiUrl": "https://api.example.com", "version": "1.0"};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:config').execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['apiUrl'], 'https://api.example.com');
      expect(map['version'], '1.0');
    });

    test('extract multiple variables', () {
      const html = '''
      <html>
        <script>
          var userId = 123;
          var userName = "Alice";
          var isActive = true;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:userId,userName,isActive')
              .execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['userId'], 123);
      expect(map['userName'], 'Alice');
      expect(map['isActive'], true);
    });

    test('extract from eval code', () {
      const html = '''
      <html>
        <script>
          eval('var secret = "hidden_value";');
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=jseval:secret').execute(node);

      expect(result, 'hidden_value');
    });

    test('extract object with nested properties', () {
      const html = '''
      <html>
        <script>
          var __INITIAL_STATE__ = {
            "user": {"id": 456, "name": "Bob"},
            "settings": {"theme": "dark"}
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:__INITIAL_STATE__')
              .execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['user']['id'], 456);
      expect(map['user']['name'], 'Bob');
    });

    test('combine with other transforms', () {
      const html = '''
      <html>
        <script>
          var title = "Hello World";
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Extract variable and transform to uppercase
      final result = QueryString('script/@text?transform=jseval:title;upper')
          .execute(node);

      expect(result, 'HELLO WORLD');
    });

    test('extract and use in subsequent query', () {
      const html = '''
      <html>
        <script>
          var apiKey = "abc123";
        </script>
        <div id="result"></div>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Extract the API key
      final result =
          QueryString('script/@text?transform=jseval:apiKey').execute(node);

      expect(result, 'abc123');
    });

    test('extract array data', () {
      const html = '''
      <html>
        <script>
          var items = [{"id": 1, "name": "Item 1"}, {"id": 2, "name": "Item 2"}];
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:items').execute(node);

      expect(result, isA<List>());
      final list = result as List;
      expect(list.length, 2);
      expect(list[0]['name'], 'Item 1');
    });
  });
}
