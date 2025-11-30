import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/js.dart';
import 'package:web_query/query.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    configureJsExecutor(FlutterJsExecutor());
  });

  group('Variable Scope Detection', () {
    test('var in global scope should be auto-detected', () {
      const html = '''
      <html>
        <script>
          var COOKIE_DOMAIN = 'pornhub.com';
          var userId = 123;
          var config = {api: 'test'};
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Test auto-detect
      final autoResult =
          QueryString('script/@text?transform=jseval').execute(node);
      print('Auto-detect result: $autoResult');

      expect(autoResult, isA<Map>());
      final map = autoResult as Map;
      expect(map.containsKey('COOKIE_DOMAIN'), true);
      expect(map['COOKIE_DOMAIN'], 'pornhub.com');
      expect(map.containsKey('userId'), true);
      expect(map['userId'], 123);
    });

    test('var can be extracted specifically', () {
      const html = '''
      <html>
        <script>
          var COOKIE_DOMAIN = 'pornhub.com';
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result = QueryString('script/@text?transform=jseval:COOKIE_DOMAIN')
          .execute(node);

      expect(result, 'pornhub.com');
    });

    test('let/const are NOT auto-detected', () {
      const html = '''
      <html>
        <script>
          let letVar = 'not detected';
          const constVar = 'also not detected';
          var varVar = 'this is detected';
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final autoResult =
          QueryString('script/@text?transform=jseval').execute(node);
      print('Auto-detect with let/const: $autoResult');

      expect(autoResult, isA<Map>());
      final map = autoResult as Map;

      // var should be detected
      expect(map.containsKey('varVar'), true);
      expect(map['varVar'], 'this is detected');

      // let/const should NOT be detected
      expect(map.containsKey('letVar'), false);
      expect(map.containsKey('constVar'), false);
    });

    test('let/const CANNOT be extracted even if specified', () {
      const html = '''
      <html>
        <script>
          let letVar = 'cannot extract';
          const constVar = 'block scoped';
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=jseval:letVar,constVar')
              .execute(node);

      expect(result, isA<Map>());
      final map = result as Map;
      // let/const are block-scoped and cannot be accessed
      expect(map['letVar'], isNull);
      expect(map['constVar'], isNull);
    });
  });
}
