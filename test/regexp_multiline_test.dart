import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  late PageNode testNode;
  const html = '''
    <div>
      <p>Line 1</p>
      <p>Line 2</p>
      <p>Line 3</p>
    </div>
  ''';

  setUp(() {
    testNode = PageData('https://example.com', html).getRootElement();
  });

  group('Multiline Regexp Support', () {
    test('multiline matching', () {
      // Should match start of line
      expect(
          QueryString(r'div/@text?regexp=/^\s*Line 2/Matched/')
              .execute(testNode),
          contains('Matched'));
    });

    test('match all keyword', () {
      // \ALL should match everything
      expect(QueryString(r'div/@text?regexp=/\ALL/Replaced/').execute(testNode),
          'Replaced');
    });

    test('dotAll matching', () {
      // (?s) should match newlines
      expect(
          QueryString(r'div/@text?regexp=/\s*Line 1[\s\S]*Line 3/Matched/')
              .execute(testNode),
          contains('Matched'));
    });
  });
}
```
