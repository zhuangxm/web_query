import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';
import 'package:web_query/web_query.dart';

void main() {
  late PageNode testNode;

  setUp(() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });

    final jsonData = {
      'meta': {
        'title': 'JSON Title',
        'tags': ['one', 'two', 'three']
      },
      'content': {
        'title': 'Content Title',
        'body': 'Main content',
        'comments': [
          {'text': 'Comment 1'},
          {'text': 'Comment 2'}
        ]
      }
    };

    const html = '''
      <html>
        <body>
          <div class="container">
            <h1>Title</h1>
            <div class="content">
              <p>First paragraph</p>
              <p>Second paragraph</p>
            </div>
            <img src="/image.jpg" alt="test">
          </div>
        </body>
      </html>
    ''';

    testNode = PageData('https://example.com/page', html,
            jsonData: jsonEncode(jsonData))
        .getRootElement();
  });

  group('JSON Path Resolution', () {
    test('basic json paths', () {
      expect(QueryString('json://meta/title').execute(testNode), 'JSON Title');
      expect(QueryString('json://content/title').execute(testNode),
          'Content Title');
      expect(QueryString('json://invalid/path').execute(testNode), isNull);
    });

    test('array access', () {
      expect(QueryString('json://meta/tags/0').execute(testNode), 'one');
      expect(QueryString('json://meta/tags/*').execute(testNode),
          ['one', 'two', 'three']);
      expect(QueryString('json://meta/tags/1-2').execute(testNode),
          ['two', 'three']);
      expect(QueryString('json://meta/tags/5').execute(testNode), isNull);
    });

    test('multiple paths', () {
      expect(QueryString('json://meta,content!/title').execute(testNode),
          ['JSON Title', 'Content Title']);
      expect(QueryString('json://meta/title,tags!/*').execute(testNode), [
        'JSON Title',
        ['one', 'two', 'three']
      ]);
    });

    test('required paths', () {
      expect(QueryString('json://invalid,meta/title!').execute(testNode),
          'JSON Title');
      expect(QueryString('json://meta/title,invalid!').execute(testNode),
          'JSON Title');
      expect(QueryString('json://meta/title!,tags/*!').execute(testNode),
          'JSON Title');
    });
  });

  group('HTML Query Resolution', () {
    test('basic selectors', () {
      expect(QueryString('html://h1/@text').execute(testNode), 'Title');
      expect(QueryString('html://img/@src').execute(testNode), '/image.jpg');
      expect(QueryString('html://.nonexistent').execute(testNode), isNull);
    });

    test('navigation', () {
      expect(QueryString('html://.content/p/@text').execute(testNode),
          'First paragraph');
      expect(QueryString('html://.container/div/^/h1/@text').execute(testNode),
          'Title');
    });

    test('multiple elements', () {
      expect(
          QueryString('html://.content/p/@text?operation=all')
              .execute(testNode),
          ['First paragraph', 'Second paragraph']);
    });
  });

  group('Query Chaining', () {
    test('required is default', () {
      final query = QueryString('json://meta/title||json://content/title');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Content Title']));
    });

    test('explicit not required', () {
      final query =
          QueryString('json://meta/title?required=false||json://content/title');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Content Title']));
    });

    test('mixed required flags', () {
      final query = QueryString(
          'json://meta/title?required=false||json://content/title||json://invalid/path?required=false');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Content Title']));
    });

    test('basic chaining', () {
      expect(QueryString('json://invalid||html://h1/@text').execute(testNode),
          'Title');
      expect(
          QueryString('json://meta/title||html://h1/@text?required=false')
              .execute(testNode),
          'JSON Title');
    });

    test('required chains', () {
      expect(
          QueryString('json://invalid?required=true||html://h1/@text')
              .execute(testNode),
          'Title');
    });
  });

  group('Transformations', () {
    test('basic transforms', () {
      expect(QueryString('html://h1/@text?transform=upper').execute(testNode),
          'TITLE');
      expect(
          QueryString('html://h1/@text?transform=upper;lower')
              .execute(testNode),
          'title');
    });

    test('regexp transforms', () {
      expect(
          QueryString(r'html://h1/@text?transform=regexp:/Title/Modified/')
              .execute(testNode),
          'Modified');

      expect(
          QueryString(r'html://h1/@text?transform=regexp:/title/Modified/')
              .execute(testNode),
          'Title');

      expect(
          QueryString(
                  r'html://img/@src?transform=regexp:/(^\/.+)/${rootUrl}$1/')
              .execute(testNode),
          'https://example.com/image.jpg');
    });

    test('regexp pattern-only mode', () {
      expect(
          QueryString('html://h1/@text?transform=regexp:/Title/')
              .execute(testNode),
          equals('Title'));
      expect(
          QueryString('html://h1/@text?transform=regexp:/itl/')
              .execute(testNode),
          equals('itl'));
      expect(
          QueryString('html://h1/@text?transform=regexp:/NotFound/')
              .execute(testNode),
          isNull);
    });

    test('regexp pattern with capture groups', () {
      expect(
          QueryString('html://h1/@text?transform=regexp:/T(itl)e/')
              .execute(testNode),
          equals('Title'));
    });

    test('regexp pattern in transform chain', () {
      final query =
          QueryString('html://h1/@text?transform=upper;regexp:/TITLE/;lower');
      final result = query.execute(testNode);
      expect(result, equals('title'));
    });

    test('transform chains', () {
      expect(
          QueryString(
                  'html://h1/@text?transform=upper;regexp:/TITLE/HEADER/;lower')
              .execute(testNode),
          'header');
    });

    test('transform composition', () {
      final transforms = [
        'upper',
        'regexp:/TITLE/HEADER/',
        'regexp:/HEADER/FINAL/',
        'lower'
      ];

      final query =
          QueryString('html://h1/@text?transform=${transforms.join(";")}');
      final result = query.execute(testNode);
      expect(result, equals('final'));
    });

    test('transform error handling', () {
      final query =
          QueryString('html://h1/@text?transform=upper;regexp:invalid;lower');
      final result = query.execute(testNode);
      expect(result, isNull);
    });

    test('null handling in transform chain', () {
      final query = QueryString('html://.nonexistent?transform=upper;lower');
      final result = query.execute(testNode);
      expect(result, isNull);
    });

    test('map update transform', () {
      final query = QueryString('json://meta?update={"newKey":"value"}');
      final result = query.execute(testNode);
      expect(result, containsPair('newKey', 'value'));
      expect(result['title'], equals('JSON Title')); // Original data preserved
    });

    test('regexp not match', () {
      expect(
          QueryString('html://h1/@text?transform=regexp:/pattern')
              .execute(testNode),
          isNull); // Returns original value on invalid format
    });

    test('regexp with plus characters', () {
      const html = '<div>a+b+c</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      // Raw plus character in pattern
      expect(
          QueryString('html://div/@text?transform=regexp:/a\\+b/')
              .execute(node),
          equals('a+b'));

      // Plus in character class
      expect(
          QueryString('html://div/@text?transform=regexp:/[+]+/').execute(node),
          equals('+'));

      // Plus as quantifier
      expect(
          QueryString('html://div/@text?transform=regexp:/\\w+/').execute(node),
          equals('a'));
    });
  });

  group('Query-specific Transformations', () {
    test('applies transforms per query', () {
      final query = QueryString(
          'json://meta/title?transform=upper||json://content/title?transform=lower');
      final results = query.execute(testNode);
      expect(results, equals(['JSON TITLE', 'content title']));
    });

    test('transforms are independent', () {
      final query = QueryString(
          'json://meta/title?transform=upper||json://meta/title?transform=lower&required=false');
      final results = query.execute(testNode);
      expect(results, equals('JSON TITLE'));
    });

    test('chain with different transforms', () {
      final query = QueryString(
          'json://invalid?transform=upper||html://h1/@text?transform=lower');
      final result = query.execute(testNode);
      expect(result, equals('title'));
    });

    test('multiple transforms per query', () {
      final query = QueryString(
          'json://meta/title?transform=upper;regexp:/JSON/TEST/||json://content/title?transform=lower;regexp:/content/test/&required=true');
      final results = query.execute(testNode);
      expect(results, equals(['TEST TITLE', 'test title']));
    });
  });

  group('Query-specific Operations', () {
    test('different operations per query', () {
      final query = QueryString(
          'html://.content/p/@text?op=all||html://.content/p/@text?op=one&required=true');
      final results = query.execute(testNode);
      expect(
          results,
          equals([
            ['First paragraph', 'Second paragraph'],
            'First paragraph'
          ]));
    });

    test('operations are independent', () {
      final query = QueryString(
          'html://.content/p/@text?op=all||html://.content/p/@text');
      final results = query.execute(testNode);
      expect(
          results,
          equals(
            [
              ['First paragraph', 'Second paragraph'],
              'First paragraph'
            ],
          ));
    });

    test('mixed operations with transforms', () {
      final query = QueryString(
          'html://.content/p/@text?op=all&transform=upper||html://.content/p/@text?transform=lower&required=true');
      final results = query.execute(testNode);
      expect(
          results,
          equals([
            ['FIRST PARAGRAPH', 'SECOND PARAGRAPH'],
            'first paragraph'
          ]));
    });
  });
}
