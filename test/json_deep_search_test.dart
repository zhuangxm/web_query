import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('JSON Deep Search', () {
    test('find single key deeply', () {
      final data = {
        'a': {
          'b': {'c': 'found'}
        }
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      // Should find 'c' anywhere
      final result = QueryString('json:..c').execute(node);
      expect(result, 'found');
    });

    test('find multiple keys deeply', () {
      final data = {
        'id': 1,
        'items': [
          {'id': 2, 'name': 'item2'},
          {
            'id': 3,
            'name': 'item3',
            'nested': {'id': 4}
          }
        ],
        'other': {'id': 5}
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      // Should find all 'id's
      final result = QueryString('json:..id').execute(node);
      expect(result, isA<List>());
      final list = result as List;
      // Order might depend on traversal, but usually document order
      expect(list, containsAll([1, 2, 3, 4, 5]));
      expect(list.length, 5);
    });

    test('deep search after path', () {
      final data = {
        'wrapper': {
          'a': {'target': 1},
          'b': {'target': 2},
          'c': {'ignore': 3}
        },
        'outside': {'target': 4}
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      // Search 'target' only inside 'wrapper'
      final result = QueryString('json:wrapper/..target').execute(node);
      expect(result, isA<List>());
      final list = result as List;
      expect(list, containsAll([1, 2]));
      expect(list.contains(4), false);
    });

    test('deep search with wildcards', () {
      final data = {
        'a': {'user_id': 1},
        'b': {'group_id': 2},
        'c': {'other': 3}
      };

      final pageData = PageData('https://example.com', '');
      final node = pageData.getRootElement();
      node.jsonData = data;

      // Search for any key ending in _id deeply
      // Syntax: ..*_id
      final result = QueryString('json:..*_id').execute(node);
      expect(result, isA<List>());
      final list = result as List;
      expect(list, containsAll([1, 2]));
    });
  });
}
