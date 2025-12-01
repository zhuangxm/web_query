import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test('Reproduce URL encoding issue', () {
    const jsonData = '{"vod_id": "12345"}';
    final node = PageData('https://api.example.com/api.php', '<html></html>',
            jsonData: jsonData)
        .getRootElement();

    // This should produce: https://api.example.com/api.php?ac=videolist&ids=12345
    // But user reports getting: ac=videolist&ids=%24%7Bvod%7D
    final result =
        QueryString('json:vod_id?save=vod ++ url:?ac=videolist&ids=\${vod}')
            .execute(node);

    print('Result: $result');
    print('Contains ids=12345: ${result.toString().contains('ids=12345')}');
    print('Contains encoded variable: ${result.toString().contains('%24%7B')}');

    // Check if variable is resolved
    expect(result, contains('ids=12345'),
        reason: 'Variable should be resolved, not URL-encoded');
    expect(result, isNot(contains('%24%7B')),
        reason: 'Should not contain URL-encoded variable placeholder');
  });
}
