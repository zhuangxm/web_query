import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    configureJsExecutor(FlutterJsExecutor());
  });

  group('JSON path wildcard matching', () {
    test('json path with wildcard in query', () {
      const html = '''
      <html>
        <script>
          var flashvars_343205161 = {"video_id": "343205161", "title": "Video 1"};
          var flashvars_999888777 = {"video_id": "999888777", "title": "Video 2"};
          var config_data = {"api": "test"};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);

      // Test: jseval >> json:flashvars_*
      final node = pageData.getRootElement();
      final result =
          QueryString('script/@text?transform=jseval >> json:flashvars_*')
              .execute(node);
      print('Result: $result');

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map.containsKey('flashvars_343205161'), true);
      expect(map.containsKey('flashvars_999888777'), true);
      expect(map.containsKey('config_data'), false);
    });

    test('json path wildcard with suffix', () {
      const html = '''
      <html>
        <script>
          var user_id = 123;
          var session_id = 456;
          var config_data = {"api": "test"};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node2 = pageData.getRootElement();

      // Test: jseval >> json:*_id
      final result = QueryString('script/@text?transform=jseval >> json:*_id')
          .execute(node2);
      print('Result: $result');

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map.containsKey('user_id'), true);
      expect(map.containsKey('session_id'), true);
      expect(map['user_id'], 123);
      expect(map['session_id'], 456);
    });

    test('direct json wildcard on map data', () {
      final data = {
        'flashvars_123': {'id': '123'},
        'flashvars_456': {'id': '456'},
        'config': {'api': 'test'}
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      final result = QueryString('json:flashvars_*').execute(node);
      print('Direct result: $result');

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map.length, 2);
      expect(map.containsKey('flashvars_123'), true);
      expect(map.containsKey('flashvars_456'), true);
    });
  });
}
