import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Debug JSON path alternatives with save', () {
    test('json:vod_id works alone', () {
      const jsonData = '{"vod_id": "12345"}';
      final node =
          PageData('https://example.com', '<html></html>', jsonData: jsonData)
              .getRootElement();

      final result = QueryString('json:vod_id').execute(node);
      print('vod_id alone: $result');
      expect(result, '12345');
    });

    test('json:id works alone', () {
      const jsonData = '{"id": "67890"}';
      final node =
          PageData('https://example.com', '<html></html>', jsonData: jsonData)
              .getRootElement();

      final result = QueryString('json:id').execute(node);
      print('id alone: $result');
      expect(result, '67890');
    });

    test('json:vod_id|id fallback works', () {
      const jsonData = '{"id": "67890"}';
      final node =
          PageData('https://example.com', '<html></html>', jsonData: jsonData)
              .getRootElement();

      final result = QueryString('json:vod_id|id').execute(node);
      print('vod_id|id fallback: $result');
      expect(result, '67890');
    });

    test('json:vod_id|id with save works', () {
      const jsonData = '{"id": "67890"}';
      final node =
          PageData('https://example.com', '<html></html>', jsonData: jsonData)
              .getRootElement();

      final result = QueryString('json:vod_id|id?save=vod ++ template:\${vod}')
          .execute(node);
      print('vod_id|id with save: $result');
      expect(result, '67890');
    });

    test('FULL TEST: json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}',
        () {
      const jsonData = '{"id": "67890"}';
      final node = PageData('https://api.example.com/api.php', '<html></html>',
              jsonData: jsonData)
          .getRootElement();

      final result = QueryString(
              'json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}')
          .execute(node);
      print('FULL RESULT: $result');

      expect(result, isNotNull);
      expect(result, contains('ids=67890'));
    });
  });
}
