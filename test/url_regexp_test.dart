import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';

void main() {
  late PageNode testNode;
  const testUrl = 'https://example.com/path/to/resource?page=1';

  setUp(() {
    testNode = PageData(testUrl, '<html></html>').getRootElement();
  });

  group('URL Regexp Support', () {
    test('regexp on full url', () {
      // Extract domain using regexp
      expect(
          QueryString(r'url:?regexp=/https:\/\/([^\/]+).*/$1/')
              .execute(testNode),
          'example.com');
    });

    test('regexp on url component', () {
      // Extract part of path
      expect(
          QueryString(r'url:path?regexp=/\/path\/to\/(.*)/$1/')
              .execute(testNode),
          'resource');
    });

    test('regexp with modification', () {
      // Modify URL then extract
      // url:?page=2 -> https://example.com/path/to/resource?page=2
      // regexp -> extract page value
      expect(
          QueryString(r'url:?page=2&regexp=/.*page=(\d+).*/$1/')
              .execute(testNode),
          '2');
    });

    test('simplified regexp syntax on url', () {
      expect(QueryString(r'url:?regexp=/https/http/').execute(testNode),
          startsWith('http://'));
    });
  });
}
