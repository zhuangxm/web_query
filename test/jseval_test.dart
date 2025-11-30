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

    test('browser globals are available', () {
      const html = '''
      <html>
        <script>
          // Use window object
          window.myData = {"source": "window"};
          
          // Use document object
          var docTitle = document.title || "default";
          
          // Use navigator
          var ua = navigator.userAgent;
          
          var result = {
            windowData: window.myData,
            docTitle: docTitle,
            hasNavigator: typeof navigator !== "undefined"
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:result').execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['windowData']['source'], 'window');
      expect(map['docTitle'], 'default');
      expect(map['hasNavigator'], true);
    });

    test('handles circular references gracefully', () {
      const html = '''
      <html>
        <script>
          // Create object with circular reference
          var obj = {name: "test", value: 123};
          obj.self = obj;
          
          var data = {
            name: obj.name,
            value: obj.value,
            hasCircular: obj.self === obj
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:data').execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['name'], 'test');
      expect(map['value'], 123);
      expect(map['hasCircular'], true);
    });

    test('handles window.screen assignment', () {
      const html = '''
      <html>
        <script>
          window.screen = {width: 1920, height: 1080};
          var screenData = {
            width: window.screen.width,
            height: window.screen.height
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final dynamic result =
          QueryString('script/@text?transform=jseval:screenData').execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['width'], 1920);
      expect(map['height'], 1080);
    });

    test('handles large scripts gracefully', () {
      // Create a large script (over 1MB)
      final largeData = List.filled(2 * 1024 * 1024, 'x').join();
      final html = '''
      <html>
        <script>
          var largeData = "$largeData";
          var test = "value";
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Should not crash, returns empty or null due to size limit
      final result =
          QueryString('script/@text?transform=jseval:test').execute(node);

      // Large script should be rejected
      expect(result, anyOf(isNull, equals({}), isEmpty));
    });

    test('truncate large scripts when enabled', () {
      // Configure executor with truncation
      final executor = FlutterJsExecutor(
        maxScriptSize: 200,
        truncateLargeScripts: true,
      );
      configureJsExecutor(executor);

      const html = '''
      <html>
        <script>
          var test = "hello";
          // Add lots of extra code that will be truncated
          var unused1 = "data1";
          var unused2 = "data2";
          var unused3 = "data3";
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Should extract from truncated script
      final result =
          QueryString('script/@text?transform=jseval:test').execute(node);

      expect(result, 'hello');

      // Reset to default executor
      configureJsExecutor(FlutterJsExecutor());
    });
  });
}
