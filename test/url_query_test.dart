// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

void main() {
  late PageNode testNode;
  const testUrl =
      'https://example.com:8080/path/to/resource?page=1&sort=desc#section1';

  setUp(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    testNode = PageData(testUrl, '<html></html>').getRootElement();
  });

  group('URL Query Resolution', () {
    test('basic url', () {
      expect(QueryString('url:').execute(testNode), testUrl);
    });

    test('url components', () {
      expect(QueryString('url:scheme').execute(testNode), 'https');
      expect(QueryString('url:host').execute(testNode), 'example.com');
      expect(QueryString('url:port').execute(testNode), '8080');
      expect(QueryString('url:path').execute(testNode), '/path/to/resource');
      expect(QueryString('url:query').execute(testNode), 'page=1&sort=desc');
      expect(QueryString('url:fragment').execute(testNode), 'section1');
      expect(QueryString('url:origin').execute(testNode),
          'https://example.com:8080');
    });

    test('query parameters', () {
      // Return map
      final params = QueryString('url:queryParameters').execute(testNode);
      expect(params, isA<Map>());
      expect(params['page'], '1');
      expect(params['sort'], 'desc');

      // Specific parameter
      expect(QueryString('url:queryParameters/page').execute(testNode), '1');
      expect(QueryString('url:queryParameters/sort').execute(testNode), 'desc');
      expect(
          QueryString('url:queryParameters/missing').execute(testNode), isNull);
    });
  });

  group('URL Modification', () {
    test('update query parameters', () {
      // Add new param
      expect(QueryString('url:?newParam=value').execute(testNode),
          contains('newParam=value'));
      // Update existing param
      expect(QueryString('url:?page=2').execute(testNode), contains('page=2'));
      // Multiple updates
      final result = QueryString('url:?page=2&status=active').execute(testNode);
      expect(result, contains('page=2'));
      expect(result, contains('status=active'));
      expect(result, contains('sort=desc')); // Preserves existing
    });

    test('remove query parameters', () {
      // Assuming we implement _remove logic
      // expect(
      //   QueryString('url:?_remove=sort').execute(testNode),
      //   isNot(contains('sort=desc'))
      // );
    });

    test('replace components', () {
      expect(QueryString('url:?_scheme=http').execute(testNode),
          startsWith('http://'));
      expect(QueryString('url:?_host=new.com').execute(testNode),
          contains('//new.com'));
      expect(QueryString('url:?_path=/new/path').execute(testNode),
          contains('/new/path'));
    });

    test('extract from modified url', () {
      // Modify host then extract it
      expect(QueryString('url:host?_host=changed.com').execute(testNode),
          'changed.com');
      // Modify param then extract it
      expect(QueryString('url:queryParameters/page?page=99').execute(testNode),
          '99');
    });
  });
}
