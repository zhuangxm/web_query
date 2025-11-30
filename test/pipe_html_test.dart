import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test('pipe JSON string to HTML query', () {
    const jsonData = '''
    {
      "comments": [
        "<div class='user'>Alice</div>",
        "<div class='user'>Bob</div>"
      ]
    }
    ''';

    final pageData =
        PageData('https://example.com', '<html></html>', jsonData: jsonData);
    final node = pageData.getRootElement();

    // Should extract HTML strings, parse them, and extract text
    final result =
        QueryString('json:comments/* >> html:.user/@text').execute(node);

    expect(result, ['Alice', 'Bob']);
  });
}
