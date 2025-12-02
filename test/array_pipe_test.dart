import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('>>> Array Pipe Operator', () {
    test('Basic array pipe with range', () {
      const html = '''
      <html>
        <div>item0</div>
        <div>item1</div>
        <div>item2</div>
        <div>item3</div>
        <div>item4</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Get first 3 elements using array pipe
      final result = QueryString('*div@ >>> json:0-2').execute(node);

      print('Result: $result');
      expect(result, ['item0', 'item1', 'item2']);
    });

    test('Array pipe with multi-index selection', () {
      const html = '''
      <html>
        <div>a</div>
        <div>b</div>
        <div>c</div>
        <div>d</div>
        <div>e</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Get elements at indices 1, 3
      final result = QueryString('*div@ >>> json:1,3').execute(node);

      print('Result: $result');
      expect(result, ['b', 'd']);
    });

    test('Array pipe combined with regular pipe', () {
      const html = '''
      <html>
        <div>{"name": "Alice"}</div>
        <div>{"name": "Bob"}</div>
        <div>{"name": "Charlie"}</div>
        <div>{"name": "David"}</div>
      </html>
      ''';

      final node =
          PageData('https://example.example.com', html).getRootElement();

      // Get first 2 elements, then parse JSON and extract name from each
      final result =
          QueryString('*div@ >>> json:0-1 >> json:name').execute(node);

      print('Result: $result');
      expect(result, ['Alice', 'Bob']);
    });

    test('Array pipe with single index', () {
      const html = '''
      <html>
        <div>item0</div>
        <div>item1</div>
        <div>item2</div>
      </html>
      ''';

      final node = PageData('https://example.com', html).getRootElement();

      // Get element at index 1
      final result = QueryString('*div@ >>> json:1').execute(node);

      print('Result: $result');
      expect(result, 'item1');
    });
  });
}
