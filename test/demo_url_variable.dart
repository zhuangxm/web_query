import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test(
      'Demonstration: json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}',
      () {
    // Example JSON data with vod_id
    const jsonData = '''
    {
      "vod_id": "12345"
    }
    ''';

    final pageData = PageData(
        'https://api.example.com/api.php', '<html></html>',
        jsonData: jsonData);
    final node = pageData.getRootElement();

    // Your exact query pattern
    final result =
        QueryString('json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}')
            .execute(node);

    print('Result: $result');
    // Expected: https://api.example.com/api.php?ac=videolist&ids=12345

    expect(result, contains('ac=videolist'));
    expect(result, contains('ids=12345'));
  });

  test('Demonstration with fallback to "id" field', () {
    // Example JSON data with only "id" (no vod_id)
    const jsonData = '''
    {
      "id": "67890"
    }
    ''';

    final pageData = PageData(
        'https://api.example.com/api.php', '<html></html>',
        jsonData: jsonData);
    final node = pageData.getRootElement();

    // The query will use "id" as fallback since "vod_id" doesn't exist
    final result =
        QueryString('json:vod_id|id?save=vod ++ url:?ac=videolist&ids=\${vod}')
            .execute(node);

    print('Result with fallback: $result');
    // Expected: https://api.example.com/api.php?ac=videolist&ids=67890

    expect(result, contains('ac=videolist'));
    expect(result, contains('ids=67890'));
  });
}
