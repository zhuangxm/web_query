// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

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
        'tags': ['one', 'two', 'three'],
        'secondTags': ['four', 'five', 'six']
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
              <a href="https://example1.com">Link1</a>
              <a href="https://example2.com">Link2</a>
            </div>
            <p class="chinese">全部中文;</p>
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
      expect(QueryString('json:meta/title').execute(testNode), 'JSON Title');
      expect(
          QueryString('json:content/body').execute(testNode), 'Main content');
      expect(QueryString('json:invalid/path').execute(testNode), isNull);
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
      expect(QueryString('json://meta,content/title').execute(testNode),
          ['JSON Title', 'Content Title']);
      expect(QueryString('json://meta/title,tags/*').execute(testNode),
          ['JSON Title', 'one', 'two', 'three']);
    });

    test('multiple collection', () {
      expect(QueryString('json://meta/tags|secondTags').execute(testNode),
          ['one', 'two', 'three']);
      expect(QueryString('json://meta/tags,secondTags').execute(testNode),
          ['one', 'two', 'three', 'four', 'five', 'six']);
      final result =
          QueryString('json://meta/tags,secondTags').getCollection(testNode);
      expect(result.map((e) => e.jsonData).toList(),
          ['one', 'two', 'three', 'four', 'five', 'six'],
          reason: 'collection');
    });

    test('required paths', () {
      expect(QueryString('json://invalid|meta/title!').execute(testNode),
          'JSON Title');
      expect(QueryString('json://meta/title,invalid!').execute(testNode),
          'JSON Title');
      expect(QueryString('json://meta/title!|tags/*!').execute(testNode),
          'JSON Title');
    });
  });

  group('HTML Query Resolution', () {
    test('basic selectors', () {
      expect(QueryString('h1/@text').execute(testNode), 'Title');
      expect(QueryString('img/@src').execute(testNode), '/image.jpg');
      expect(QueryString('.nonexistent').execute(testNode), isNull);
    });

    test('navigation', () {
      expect(QueryString('html://.content/p/@text').execute(testNode),
          'First paragraph');
      expect(QueryString('html://.container/div/^/h1/@text').execute(testNode),
          'Title');
    });

    test('multiple elements', () {
      expect(QueryString('html://.content/*p/@text').execute(testNode),
          ['First paragraph', 'Second paragraph']);
    });

    test('multiple elements with invalid attributes', () {
      expect(
          QueryString(
                  r'html://.content/*a/@href?transform=regexp:/^\/.*||html://.content/*p/@text')
              .execute(testNode),
          ['First paragraph', 'Second paragraph']);
    });
  });

  group('Query Chaining', () {
    test('++ is requried', () {
      final query = QueryString('json://meta/title++json://content/title');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Content Title']));
    });

    test('|| is optional', () {
      final query = QueryString('json://meta/title?||json://content/title');
      final results = query.execute(testNode);
      expect(results, equals('JSON Title'));
    });

    test('mixed ++ and ||', () {
      final query = QueryString(
          'json://meta/title++json://content/title||json://invalid/path');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Content Title']));
    });

    test('basic chaining', () {
      expect(QueryString('json://invalid||html://h1/@text').execute(testNode),
          'Title');
      expect(
          QueryString('json://meta/title||html://h1/@text').execute(testNode),
          'JSON Title');
    });

    test('required chains', () {
      expect(QueryString('json://invalid||html://h1/@text').execute(testNode),
          'Title');
    });

    test('first query is always required', () {
      final query = QueryString('json:invalid/path||h1/@text');
      final results = query.execute(testNode);
      expect(
          results, equals('Title')); // Second query executes after first fails
    });

    test('other queries are required by default', () {
      final query = QueryString('json:meta/title||json:invalid/path||h1/@text');
      final results = query.execute(testNode);
      expect(
          results, equals('JSON Title')); // Skip optional queries after success
    });

    test('explicit required query', () {
      final query = QueryString('json:meta/title++json:invalid/path');
      final results = query.execute(testNode);
      expect(results, equals('JSON Title')); // Execute required query
    });

    test('mixed required flags', () {
      final query = QueryString(
          'json:meta/title++json:invalid/path++h1/@text++json:bad/path');
      final results = query.execute(testNode);
      expect(results, equals(['JSON Title', 'Title']));
    });

    test('first query ignores required parameter', () {
      expect(QueryString('json:invalid/path||h1/@text').execute(testNode),
          equals('Title') // Still executes second query
          );
      expect(QueryString('json:invalid/path||h1/@text').execute(testNode),
          equals('Title') // Parameter has no effect
          );
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
      //final jsonData = (result as PageNode).jsonData;
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
          'json://meta/title?transform=upper++json://content/title?transform=lower');
      final results = query.execute(testNode);
      expect(results, equals(['JSON TITLE', 'content title']));
    });

    test('transforms are independent', () {
      final query = QueryString(
          'json://meta/title?transform=upper||json://meta/title?transform=lower');
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
          'json://meta/title?transform=upper;regexp:/JSON/TEST/++json://content/title?transform=lower;regexp:/content/test/');
      final results = query.execute(testNode);
      expect(results, equals(['TEST TITLE', 'test title']));
    });
  });

  group('Query Parsing', () {
    test('simplified schemes', () {
      expect(QueryString('json:meta/title').execute(testNode), 'JSON Title');
      expect(QueryString('html:h1/@text').execute(testNode), 'Title');
      expect(QueryString('h1/@text').execute(testNode), 'Title');
    });

    test('mixed schemes and paths', () {
      expect(QueryString('json:meta/title++.content/p/@text').execute(testNode),
          ['JSON Title', 'First paragraph']);
      expect(QueryString('meta/title++json:content/body').execute(testNode),
          'Main content');
    });
  });

  // Update test cases to use simplified syntax
  test('basic json paths', () {
    expect(QueryString('json:meta/title').execute(testNode), 'JSON Title');
    expect(QueryString('json:content/body').execute(testNode), 'Main content');
  });

  test('basic html paths', () {
    expect(QueryString('h1/@text').execute(testNode), 'Title');
    expect(
        QueryString('.content/p/@text').execute(testNode), 'First paragraph');
  });

  group('HTML Class Resolution', () {
    test('checks class existence', () {
      expect(QueryString('.container/@.container').execute(testNode), 'true');
      expect(QueryString('.content/@.missing').execute(testNode), null);
    });

    test('wildcard class match', () {
      const html =
          '<div class="container prefix-class class-suffix middle">Content</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(QueryString('div/@.prefix*').execute(node), 'true',
          reason: 'prefix');
      expect(QueryString('div/@.*suffix').execute(node), 'true',
          reason: 'suffix');
      expect(QueryString('div/@.*middle*').execute(node), 'true',
          reason: 'middle');
      expect(QueryString('div/@.pre*fix').execute(node), null,
          reason: 'pre*fix');
      expect(QueryString('div/@.*xyz*|.prefix*').execute(node), 'true');
      expect(QueryString('div/@.prefix*|.*xyz*').execute(node), 'true');
    });

    test('multiple class checks', () {
      const html = '<div class="one two three", id="classes">Content</div>';
      final pageData = PageData('https://example.com', html);
      final node = pageData.getRootElement();

      expect(QueryString('div/@.one').execute(node), 'true', reason: 'one');
      expect(QueryString('div#classes@.one').execute(node), 'true',
          reason: 'one (/ before @ is optional)');
      expect(QueryString('div/@.two').execute(node), 'true', reason: 'two');
      expect(QueryString('div/@.tw').execute(node), null, reason: 'tw');
      expect(QueryString('div/@.four').execute(node), null, reason: 'four');
    });

    test('class check with transforms', () {
      expect(
          QueryString('.container/@.container?transform=regexp:/true/yes/')
              .execute(testNode),
          'yes');
    });
  });

  group('HTML Selector Prefixes', () {
    test('querySelectorAll with * prefix', () {
      expect(QueryString('.content/*p/@text').execute(testNode),
          equals(['First paragraph', 'Second paragraph']));
    });

    test('querySelector by default', () {
      expect(QueryString('.content/p/@text').execute(testNode),
          equals('First paragraph'));
    });

    test('mixed prefixes in chain', () {
      expect(
          QueryString('.content/*p/@text++.content/p/@text').execute(testNode),
          equals(['First paragraph', 'Second paragraph', 'First paragraph']));
    });
  });

  group('API Compatibility', () {
    test('getValue returns concatenated results', () {
      expect(QueryString('.content/*p/@').getValue(testNode),
          equals('First paragraph\nSecond paragraph'));
      expect(QueryString('.content/*p/@').getValue(testNode, separator: ' '),
          equals('First paragraph Second paragraph'));
    });

    test('getCollection returns PageNode list', () {
      final nodes = QueryString('.content/*p').getCollection(testNode).toList();
      expect(nodes.length, equals(2));
      //expect(nodes.every((n) => n is PageNode), isTrue);
      expect(nodes.map((n) => n.element?.text).toList(),
          equals(['First paragraph', 'Second paragraph']));
    });

    test('getCollectionValue returns raw elements', () {
      final elements =
          QueryString('.content/*p').getCollectionValue(testNode).toList();
      expect(elements.length, equals(2));
      expect(elements.every((e) => e is Element), isTrue);
      expect(elements.map((e) => (e as Element).text).toList(),
          equals(['First paragraph', 'Second paragraph']));
    });

    test('json query collection', () {
      final values =
          QueryString('json:content/comments/*').getCollectionValue(testNode);
      print("values: $values");
      expect(values.length, equals(2));
      expect(values.map((e) => e['text']), equals(['Comment 1', 'Comment 2']));
    });

    test('mixed query types', () {
      final query = QueryString('json:meta/title++.content/*p/@');
      expect(query.getValue(testNode),
          equals('JSON Title\nFirst paragraph\nSecond paragraph'));
      expect(query.getCollection(testNode).map((n) => n.jsonData).toList(),
          equals(['JSON Title', 'First paragraph', 'Second paragraph']));
    });

    test("query String qurey paramter has chinese", () {
      final query =
          QueryString(r'p.chinese/@?transform=regexp:/(?:全部|)(.*\;)/$1/');
      expect(query.execute(testNode), equals("中文;"));
    });
  });

  group('Reserved Parameter Encoding', () {
    test('parameters are properly parsed without errors', () {
      // Test that all reserved parameters can be parsed without throwing errors
      expect(() => QueryString('h1/@text?save=myVar'), returnsNormally);
      expect(() => QueryString('h1/@text?keep=true'), returnsNormally);
      expect(() => QueryString('h1/@text?keep=false'), returnsNormally);
      expect(() => QueryString('h1/@text?filter=test'), returnsNormally);
      expect(() => QueryString('json://meta?update={"key":"value"}'),
          returnsNormally);
      expect(() => QueryString('h1/@text?regexp=/a/b/'), returnsNormally);
    });

    test('reserved parameters work with transforms', () {
      // Test transform still works when combined with other reserved parameters
      final query1 = QueryString('h1/@text?transform=upper');
      expect(query1.execute(testNode), equals('TITLE'));

      // Adding keep parameter shouldn't break transform
      final query2 = QueryString('h1/@text?keep=true&transform=upper');
      expect(query2.execute(testNode), equals('TITLE'));
    });

    test('filter parameter works correctly', () {
      // Test filter parameter functionality - basic case
      final query1 = QueryString('.content/*p/@text?filter=First');
      final result1 = query1.execute(testNode);
      expect(result1, equals('First paragraph'));
    });

    test('regexp parameter works correctly', () {
      // Test regexp parameter - it's converted to transform internally
      final query1 = QueryString('h1/@text?regexp=/Title/Header/');
      final result1 = query1.execute(testNode);
      expect(result1, equals('Header'));

      // Regexp with transform - apply transform first, then regexp
      final query2 =
          QueryString('h1/@text?transform=upper&regexp=/TITLE/HEADER/');
      final result2 = query2.execute(testNode);
      expect(result2, equals('HEADER'));
    });

    test('update parameter works correctly', () {
      // Test update parameter
      final query1 = QueryString('json://meta?update={"newKey":"value"}');
      final result1 = query1.execute(testNode);
      expect(result1, isNotNull);
      if (result1 is Map) {
        expect(result1, containsPair('newKey', 'value'));
        expect(result1, containsPair('title', 'JSON Title'));
      }
    });

    test('transforms work correctly with reserved parameters', () {
      // Verify that basic transforms still work
      final query1 = QueryString('h1/@text?transform=upper');
      expect(query1.execute(testNode), equals('TITLE'));

      // Verify regexp transform works
      final query2 = QueryString('h1/@text?transform=regexp:/Title/Header/');
      expect(query2.execute(testNode), equals('Header'));
    });

    test('multiple parameters can coexist', () {
      // Test that multiple reserved parameters can be used together
      expect(() => QueryString('h1/@text?transform=upper&save=var1&keep=true'),
          returnsNormally);

      // And they should still produce correct results
      final query = QueryString('h1/@text?transform=upper&keep=true');
      expect(query.execute(testNode), equals('TITLE'));
    });
  });
}
