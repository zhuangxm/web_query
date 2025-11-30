import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test('pipe HTML text to JSON query', () {
    const html = '''
    <html>
      <script id="data">
        {"user": "Alice", "id": 123}
      </script>
    </html>
    ''';

    final pageData = PageData('https://example.com', html);
    final node = pageData.getRootElement();

    // Should extract text, parse as JSON, and extract user
    final result = QueryString('#data/@text >> json:user').execute(node);

    expect(result, 'Alice');
  });
}
