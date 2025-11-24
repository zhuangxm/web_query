import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  late PageNode testNode;

  setUp(() {
    const html = '''
      <html>
        <body>
          <ul>
            <li>Apple</li>
            <li>Banana</li>
            <li>Cherry</li>
            <li>Date Fruit</li>
            <li>Elderberry</li>
            <li>Fig & Grape</li>
          </ul>
        </body>
      </html>
    ''';
    testNode = PageData('https://example.com/page', html).getRootElement();
  });

  group('Filter Transform', () {
    test('basic include filter', () {
      // Select all list items
      final result = QueryString('*li/@text?filter=Apple').execute(testNode);
      // Should return only Apple, simplified to string
      expect(result, 'Apple');
    });

    test('exclude filter', () {
      final result = QueryString('*li/@text?filter=!Apple').execute(testNode);
      expect(result,
          ['Banana', 'Cherry', 'Date Fruit', 'Elderberry', 'Fig & Grape']);
    });

    test('include and exclude', () {
      // Must contain "a" and not contain "Banana"
      // Apple: No 'a' (case sensitive).
      // Banana: Has 'a', has 'Banana'. Drop.
      // Cherry: No 'a'.
      // Date Fruit: Has 'a'. Keep.
      // Elderberry: No 'a'.
      final result =
          QueryString('*li/@text?filter=a !Banana').execute(testNode);
      expect(result, ['Date Fruit', 'Fig & Grape']);
    });

    test('escaped space', () {
      final result =
          QueryString('*li/@text?filter=Date\\ Fruit').execute(testNode);
      expect(result, 'Date Fruit');
    });

    test('multiple filters', () {
      // filter=a;!Banana
      final result =
          QueryString('*li/@text?filter=a;!Banana').execute(testNode);
      expect(result, ['Date Fruit', 'Fig & Grape']);
    });

    test('filter on single value', () {
      // Should return null if filtered out
      expect(QueryString('li/@text?filter=Banana').execute(testNode), null);
      // Should return value if matches
      expect(QueryString('li/@text?filter=Apple').execute(testNode), 'Apple');
    });

    test('filter with ampersand', () {
      final result = QueryString('*li/@text?filter=&').execute(testNode);
      expect(result, 'Fig & Grape');
    });

    test('filter with escaped ampersand', () {
      final result = QueryString(r'*li/@text?filter=\&').execute(testNode);
      expect(result, 'Fig & Grape');
    });

    test('transform and filter with ampersand', () {
      // transform: replace 'Fig' with 'Big'
      // filter: keep 'Big & Grape' (contains &)
      final result =
          QueryString('*li/@text?transform=regexp:/Fig/Big/&filter=&')
              .execute(testNode);
      expect(result, 'Big & Grape');
    });

    test('semicolon in regexp and filter with escaped semicolon', () {
      // transform: replace 'Apple' with 'A;le' (semicolon in replacement)
      // filter: match 'A;le' (escaped semicolon)
      final result =
          QueryString('*li/@text?transform=regexp:/Apple/A\\;le/&filter=A\\;le')
              .execute(testNode);
      expect(result, 'A;le');
    });
  });
}
