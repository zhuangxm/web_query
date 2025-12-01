import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('URL Query with Variables', () {
    test('use variable in url query parameter value', () {
      const jsonData = '''
      {
        "vod_id": "12345"
      }
      ''';

      final pageData = PageData(
          'https://api.example.com/api.php', '<html></html>',
          jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save vod_id, then use it in URL query parameter
      final result =
          QueryString('json:vod_id?save=vod ++ url:?ac=videolist&ids=\${vod}')
              .execute(node);

      expect(result, contains('ac=videolist'));
      expect(result, contains('ids=12345'));
    });

    test('use variable with json path alternatives', () {
      const jsonData = '''
      {
        "id": "67890"
      }
      ''';

      final pageData = PageData(
          'https://api.example.com/api.php', '<html></html>',
          jsonData: jsonData);
      final node = pageData.getRootElement();

      // Save using path alternatives (vod_id|id), then use in URL
      final result = QueryString(
              'json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}')
          .execute(node);

      expect(result, contains('ac=videolist'));
      expect(result, contains('ids=67890'));
    });
  });
}
