// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    configureJsExecutor(FlutterJsExecutor());
  });

  group('jseval specific variable extraction', () {
    test('specific variable extraction should work like auto-detect', () {
      const html = '''
      <html>
        <script>
          var flashvars_343205161 = {
            "video_id": "343205161",
            "title": "Test Video"
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Test auto-detect (works)
      final autoResult =
          QueryString('script/@text?transform=jseval').execute(node);
      print('Auto-detect result: $autoResult');
      expect(autoResult, isA<Map>());
      expect((autoResult as Map).containsKey('flashvars_343205161'), true);

      // Test specific extraction (should also work now)
      final specificResult =
          QueryString('script/@text?transform=jseval:flashvars_343205161')
              .execute(node);
      print('Specific result: $specificResult');
      expect(specificResult, isA<Map>());
      expect(specificResult['video_id'], '343205161');
      expect(specificResult['title'], 'Test Video');
    });

    test('piped jseval with json extraction', () {
      const html = '''
      <html>
        <script>
          var flashvars_343205161 = {
            "video_id": "343205161",
            "title": "Test Video"
          };
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);

      // Test: jseval >> json:flashvars_343205161
      final node2 = pageData.getRootElement();
      final result = QueryString(
              'script/@text?transform=jseval >> json:flashvars_343205161')
          .execute(node2);
      print('Piped result: $result');
      expect(result, isA<Map>());
      expect((result as Map)['video_id'], '343205161');
    });

    test('wildcard matching with jseval', () {
      const html = '''
      <html>
        <script>
          var flashvars_343205161 = {"video_id": "343205161"};
          var flashvars_999888777 = {"video_id": "999888777"};
          var config_data = {"api": "test"};
          var user_id = 123;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Test wildcard: flashvars_*
      final result1 = QueryString('script/@text?transform=jseval:flashvars_*')
          .execute(node);
      print('Wildcard flashvars_* result: $result1');
      expect(result1, isA<Map>());
      final map1 = result1 as Map;
      expect(map1.containsKey('flashvars_343205161'), true);
      expect(map1.containsKey('flashvars_999888777'), true);
      expect(map1.containsKey('config_data'), false);

      // Test wildcard: *_data
      final result2 =
          QueryString('script/@text?transform=jseval:*_data').execute(node);
      print('Wildcard *_data result: $result2');
      expect(result2, isA<Map>());
      final map2 = result2 as Map;
      expect(map2.containsKey('config_data'), true);
      expect(map2.containsKey('flashvars_343205161'), false);

      // Test wildcard: *_id
      final result3 =
          QueryString('script/@text?transform=jseval:*_id').execute(node);
      print('Wildcard *_id result: $result3');
      expect(result3, isA<Map>());
      final map3 = result3 as Map;
      expect(map3.containsKey('user_id'), true);
      expect(map3['user_id'], 123);
    });

    test('multiple wildcard patterns', () {
      const html = '''
      <html>
        <script>
          var flashvars_123 = {"id": "123"};
          var config_data = {"api": "test"};
          var user_info = {"name": "Alice"};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Test multiple patterns
      final result =
          QueryString('script/@text?transform=jseval:flashvars_*,*_info')
              .execute(node);
      print('Multiple patterns result: $result');
      expect(result, isA<Map>());
      final map = result as Map;
      expect(map.containsKey('flashvars_123'), true);
      expect(map.containsKey('user_info'), true);
      expect(map.containsKey('config_data'), false);
    });
  });
}
