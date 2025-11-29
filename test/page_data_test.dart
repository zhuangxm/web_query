import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/page_data.dart';

void main() {
  group('PageData.auto', () {
    test('parses HTML content', () {
      final html = '<html><body><h1>Hello</h1></body></html>';
      final pageData = PageData.auto('http://example.com', html);

      expect(pageData.document, isNotNull);
      expect(pageData.document!.querySelector('h1')!.text, equals('Hello'));
      expect(pageData.jsonData, isNull);
    });

    test('parses JSON content', () {
      final json = '{"key": "value", "list": [1, 2, 3]}';
      final pageData = PageData.auto('http://example.com', json);

      expect(pageData.jsonData, isNotNull);
      expect(pageData.jsonData['key'], equals('value'));
      expect(pageData.jsonData['list'], equals([1, 2, 3]));
      // JSON string is also parsed as HTML text content by Document.html
      expect(pageData.document, isNotNull);
    });

    test('parses XML content', () {
      final xml =
          '<?xml version="1.0"?><root><item id="1">Item 1</item></root>';
      final pageData = PageData.auto('http://example.com', xml);

      expect(pageData.jsonData, isNotNull);
      // xml2json ParkerWithAttrs convention
      expect(pageData.jsonData['root']['item']['_id'], equals('1'));
      expect(pageData.jsonData['root']['item']['value'], equals('Item 1'));

      expect(pageData.document, isNotNull);
    });

    test('accepts Map object', () {
      final data = {'key': 'value'};
      final pageData = PageData.auto('http://example.com', data);

      expect(pageData.jsonData, equals(data));
      expect(pageData.document, isNotNull);
      expect(pageData.document!.documentElement!.innerHtml,
          contains('<head></head><body></body>'));
    });

    test('accepts List object', () {
      final data = [1, 2, 3];
      final pageData = PageData.auto('http://example.com', data);

      expect(pageData.jsonData, equals(data));
      expect(pageData.document, isNotNull);
    });

    test('handles invalid JSON gracefully', () {
      final invalidJson = '{key: value}'; // Invalid JSON
      final pageData = PageData.auto('http://example.com', invalidJson);

      expect(pageData.jsonData, isNull);
      expect(pageData.document, isNotNull);
      // Should be parsed as text in HTML body
      expect(pageData.document!.body!.text, contains('{key: value}'));
    });
  });
}
