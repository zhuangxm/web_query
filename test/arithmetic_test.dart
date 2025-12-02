import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('Variable Arithmetic', () {
    test('Simple arithmetic', () {
      const html = '<html><div>test</div></html>';
      final node = PageData('https://example.com', html).getRootElement();

      // Define variables
      final variables = {'a': 10, 'b': 20};

      // Use arithmetic in index
      // *div@?index=${a + b - 30} -> index=0
      final result = QueryString('*div@?index=\${a + b - 30}')
          .execute(node, simplify: true, initialVariables: variables);

      expect(result, 'test');
    });

    test('Arithmetic with multiplication and precedence', () {
      const html = '''
      <html>
        <div>0</div>
        <div>1</div>
        <div>2</div>
        <div>3</div>
        <div>4</div>
        <div>5</div>
      </html>
      ''';
      final node = PageData('https://example.com', html).getRootElement();

      final variables = {'x': 2, 'y': 3};

      // index = 2 * 3 - 1 = 5
      final result = QueryString('*div@?index=\${x * y - 1}')
          .execute(node, initialVariables: variables);

      expect(result, '5');
    });

    test('Arithmetic with parentheses', () {
      const html = '''
      <html>
        <div>0</div>
        <div>1</div>
        <div>2</div>
        <div>3</div>
        <div>4</div>
        <div>5</div>
      </html>
      ''';
      final node = PageData('https://example.com', html).getRootElement();

      final variables = {'x': 2, 'y': 3};

      // index = 2 * (3 - 1) = 4
      final result = QueryString('*div@?index=\${x * (y - 1)}')
          .execute(node, initialVariables: variables);

      expect(result, '4');
    });

    test('String concatenation with +', () {
      const html = '<html><div id="test1">content</div></html>';
      final node = PageData('https://example.com', html).getRootElement();

      final variables = {'prefix': 'test', 'id': 1};

      // #test1
      final result = QueryString('#\${prefix + id}@text')
          .execute(node, initialVariables: variables);

      expect(result, 'content');
    });

    test('Arithmetic in save variable', () {
      // This is a bit tricky because save happens after extraction.
      // But we can use a variable in a subsequent query.

      const html = '''
      <html>
        <div class="item">10</div>
        <div class="result">Result</div>
      </html>
      ''';
      final node = PageData('https://example.com', html).getRootElement();

      // 1. Extract 10 into 'val'
      // 2. Use val in next query: index=${val / 2 - 5} = 0

      // Note: 'val' will be a string "10". The parser should handle parsing it to int.
      final result = QueryString(
              '.item@text?save=val ++ .result@text?index=\${val / 2 - 5}')
          .execute(node);

      expect(result, 'Result');
    });
  });
}
