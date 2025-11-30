import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  group('JSON Transform - Primitive Values', () {
    test('extract number variable', () {
      const html = '''
      <html>
        <script>
          var count = 42;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:count').execute(node);
      expect(result, 42);
    });

    test('extract string variable', () {
      const html = '''
      <html>
        <script>
          var message = "Hello World";
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:message').execute(node);
      expect(result, 'Hello World');
    });

    test('extract boolean variable', () {
      const html = '''
      <html>
        <script>
          var isActive = true;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:isActive').execute(node);
      expect(result, true);
    });

    test('extract null variable', () {
      const html = '''
      <html>
        <script>
          var data = null;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:data').execute(node);
      expect(result, null);
    });

    test('extract decimal number', () {
      const html = '''
      <html>
        <script>
          var price = 19.99;
        </script>
      </html>
      ''';

      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      final result =
          QueryString('script/@text?transform=json:price').execute(node);
      expect(result, 19.99);
    });
  });
}
