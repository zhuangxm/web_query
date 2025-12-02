import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Variable Scope with >>> Array Pipe Operator', () {
    test('Single variable saved before >>> and used after', () {
      const html = '''
      <html>
        <div id="name">Alice</div>
        <div>item1</div>
        <div>item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Save variable before >>>, use it in template after >>>
      final result = QueryString(
              '#name@?save=userName ++ *div@ >>> json:1-2 ++ template:\${userName}')
          .execute(node);

      // Result includes array items and template
      expect(result, ['item1', 'item2', 'Alice']);
    });

    test('Multiple variables saved before >>> and used after', () {
      const html = '''
      <html>
        <div id="first">Alice</div>
        <div id="last">Smith</div>
        <div>item1</div>
        <div>item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Save multiple variables before >>>, use them in template after >>>
      final result = QueryString(
              '#first@?save=fn ++ #last@?save=ln ++ *div@ >>> json:2-3 ++ template:\${fn} \${ln}')
          .execute(node);

      // Result includes array items and template
      expect(result, ['item1', 'item2', 'Alice Smith']);
    });

    test('Variable in path after >>>', () {
      const jsonData = '''
      {
        "targetKey": "name",
        "items": [
          {"name": "Alice", "age": 30},
          {"name": "Bob", "age": 25}
        ]
      }
      ''';

      final node = PageData('https://example.com', '', jsonData: jsonData)
          .getRootElement();

      // Save variable before >>>, use it in JSON path after >>>
      final result = QueryString(
              'json:targetKey?save=key ++ json:items/* >>> json:* >> json:\${key}')
          .execute(node);

      expect(result, ['Alice', 'Bob']);
    });

    test('initialVariables parameter with >>>', () {
      const html = '''
      <html>
        <div>item1</div>
        <div>item2</div>
        <div>item3</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Pass initial variables, use them after >>>
      final result = QueryString('*div@ >>> json:0-1 ++ template:\${prefix}')
          .execute(node, initialVariables: {'prefix': 'test'});

      // Result includes array items and template
      expect(result, ['item1', 'item2', 'test']);
    });

    test('Variables persist through query chain with >>>', () {
      const jsonData = '''
      {
        "prefix": "Item",
        "suffix": "End",
        "items": ["A", "B"]
      }
      ''';

      final node = PageData('https://example.com', '', jsonData: jsonData)
          .getRootElement();

      // Save two variables before >>>, use both after >>>
      final result = QueryString(
              'json:prefix?save=p ++ json:suffix?save=s ++ json:items/* >>> json:* ++ template:\${p}-\${s}')
          .execute(node);

      // Both variables should be accessible after >>>
      expect(result, ['A', 'B', 'Item-End']);
    });

    test('Edge case: No variables saved', () {
      const html = '''
      <html>
        <div>item1</div>
        <div>item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // No variables saved, should work as before
      final result = QueryString('*div@ >>> json:*').execute(node);

      expect(result, ['item1', 'item2']);
    });

    test('Edge case: Empty string variable values', () {
      const jsonData = '''
      {
        "emptyValue": "",
        "items": ["a", "b"]
      }
      ''';

      final node = PageData('https://example.com', '', jsonData: jsonData)
          .getRootElement();

      // Save empty string, use it after >>>
      final result = QueryString(
              'json:emptyValue?save=ev ++ json:items/* >>> json:* ++ template:[\${ev}]')
          .execute(node);

      // Empty string should be preserved in template
      // Result includes array items and template with empty brackets
      expect(result, ['a', 'b', '[]']);
    });

    test('Edge case: Variable name conflicts', () {
      const html = '''
      <html>
        <div id="first">Alice</div>
        <div id="second">Bob</div>
        <div>item1</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Save same variable twice, later value should win
      final result = QueryString(
              '#first@?save=name ++ #second@?save=name ++ *div@ >>> json:0-1 ++ template:\${name}')
          .execute(node);

      // Later value (Bob) should be used, result includes array items and template
      expect(result, ['Alice', 'Bob', 'Bob']);
    });

    test('Edge case: Empty query results before >>>', () {
      const html = '''
      <html>
        <div id="name">Alice</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Save variable, but query before >>> returns empty (no spans)
      // When the array is empty, >>> creates empty JSON array
      final result = QueryString(
              '#name@?save=userName ++ *span@ >>> json:* ++ template:\${userName}')
          .execute(node);

      // Empty array from query before >>>, but template should still work with saved variable
      // Since ?save auto-discards and span query returns nothing, only template is returned
      expect(result, 'Alice');
    });

    test('Variable with numeric string used as JSON array index', () {
      const jsonData = '''
      {
        "index": "2",
        "items": ["Item0", "Item1", "Item2"]
      }
      ''';

      final node = PageData('https://example.com', '', jsonData: jsonData)
          .getRootElement();

      // Save numeric string, then use it to index into array
      final result =
          QueryString('json:index?save=idx ++ json:items/* >>> json:\${idx}')
              .execute(node);

      // Should get Item2 (the item at index 2)
      expect(result, 'Item2');
    });

    test('Variable from regexp used as JSON array index', () {
      const html = '''
      <html>
        <a href="/video/2">Video Link</a>
        <div class="item">Item0</div>
        <div class="item">Item1</div>
        <div class="item">Item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Extract index from href using regexp, then use it to index into array
      // Note: Use & to separate parameters, not ?
      final result = QueryString(
              'a@href?regexp=/\\d+/&save=index ++ *.item@ >>> json:\${index}')
          .execute(node);

      // Should get Item2 (the item at index 2)
      expect(result, 'Item2');
    });
  });
}
