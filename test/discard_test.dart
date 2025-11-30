import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test('discard parameter with simplify=true', () {
    const jsonData = '''
    {
      "user": {
        "firstName": "Alice",
        "lastName": "Smith"
      }
    }
    ''';

    final pageData =
        PageData('https://example.com', '<html></html>', jsonData: jsonData);
    final node = pageData.getRootElement();

    // With discard, getValue should only return template
    final result = QueryString(
            'json:user/firstName?save=fn&discard ++ json:user/lastName?save=ln&discard ++ template:\${fn} \${ln}')
        .getValue(node);

    expect(result, 'Alice Smith');
  });

  test('discard parameter with simplify=false', () {
    const jsonData = '''
    {
      "user": {
        "firstName": "Alice",
        "lastName": "Smith"
      }
    }
    ''';

    final pageData =
        PageData('https://example.com', '<html></html>', jsonData: jsonData);
    final node = pageData.getRootElement();

    // With getCollectionValue, should return all values (unwrapped)
    final result = QueryString(
            'json:user/firstName?save=fn&discard ++ json:user/lastName?save=ln&discard ++ template:\${fn} \${ln}')
        .getCollectionValue(node)
        .toList();

    expect(result, ['Alice', 'Smith', 'Alice Smith']);
  });
}
