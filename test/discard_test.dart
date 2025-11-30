import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  test('save auto-discards without keep', () {
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

    // With save (no keep), getValue should only return template
    final result = QueryString(
            'json:user/firstName?save=fn ++ json:user/lastName?save=ln ++ template:\${fn} \${ln}')
        .getValue(node);

    expect(result, 'Alice Smith');
  });

  test('keep parameter preserves intermediate values', () {
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

    // With keep, getCollectionValue should return all values
    final result = QueryString(
            'json:user/firstName?save=fn&keep ++ json:user/lastName?save=ln&keep ++ template:\${fn} \${ln}')
        .getCollectionValue(node)
        .toList();

    expect(result, ['Alice', 'Smith', 'Alice Smith']);
  });

  test('selective keep - only some values kept', () {
    const jsonData = '''
    {
      "user": {
        "firstName": "Alice",
        "lastName": "Smith",
        "age": 30
      }
    }
    ''';

    final pageData =
        PageData('https://example.com', '<html></html>', jsonData: jsonData);
    final node = pageData.getRootElement();

    // Only keep lastName, discard firstName and age
    final result = QueryString(
            'json:user/firstName?save=fn ++ json:user/lastName?save=ln&keep ++ json:user/age?save=age ++ template:\${fn} \${ln} (\${age})')
        .getCollectionValue(node)
        .toList();

    expect(result, ['Smith', 'Alice Smith (30)']);
  });
}
