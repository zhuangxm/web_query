import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('JSON Deep Search Flattening', () {
    test('flatten list values in deep search', () {
      final data = {
        'section1': {
          'tags': ['a', 'b']
        },
        'section2': {
          'tags': ['c', 'd']
        }
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      // Should find both 'tags' lists and flatten them into one list
      // Expected: ['a', 'b', 'c', 'd']
      // Current behavior (likely): [['a', 'b'], ['c', 'd']]
      final result = QueryString('json:..tags').execute(node);
      print('Result: $result');

      expect(result, isA<List>());
      final list = result as List;
      expect(list.length, 4);
      expect(list, containsAll(['a', 'b', 'c', 'd']));
    });
  });
}
