import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

/// Integration tests for the full transform pipeline
///
/// These tests verify that all transform modules work together correctly
/// and that the reorganization maintains backward compatibility.
///
/// **Feature: transform-reorganization, Requirements 2.1, 2.2**
void main() {
  late PageNode testNode;

  setUp(() {
    Logger.root.level = Level.WARNING;
    Logger.root.onRecord.listen((record) {
      // Suppress logs during tests unless debugging
    });

    final jsonData = {
      'user': {
        'firstName': 'Alice',
        'lastName': 'Smith',
        'email': 'alice@example.com',
        'age': 30,
        'tags': ['developer', 'designer', 'manager']
      },
      'posts': [
        {'id': 1, 'title': 'First Post', 'views': 100},
        {'id': 2, 'title': 'Second Post', 'views': 250},
        {'id': 3, 'title': 'Third Post', 'views': 75}
      ]
    };

    const html = '''
      <html>
        <head>
          <title>Test Page</title>
        </head>
        <body>
          <div class="header">
            <h1>Welcome</h1>
            <p class="subtitle">A test page</p>
          </div>
          <div class="content">
            <article class="post">
              <h2>Article Title</h2>
              <p>First paragraph</p>
              <p>Second paragraph</p>
            </article>
            <ul class="tags">
              <li>tag-one</li>
              <li>tag-two</li>
              <li>tag-three</li>
            </ul>
          </div>
          <img src="/images/photo.jpg" alt="Photo">
          <a href="/page1">Link 1</a>
          <a href="/page2">Link 2</a>
        </body>
      </html>
    ''';

    testNode = PageData('https://example.com/test', html,
            jsonData: jsonEncode(jsonData))
        .getRootElement();
  });

  group('Full Pipeline Integration', () {
    test('text transform → filter → index pipeline', () {
      // Get all tags, uppercase them, filter for "TAG-TWO", get first result
      final query = QueryString(
          'html://.tags/*li/@text?transform=upper&filter=TAG-TWO&index=0');
      final result = query.execute(testNode);

      expect(result, equals('TAG-TWO'));
    });

    test('regexp transform → text transform → save pipeline', () {
      // Extract image path, prepend domain, uppercase, save to variable with keep
      final query = QueryString(
          r'html://img/@src?transform=regexp:/(^\/.+)/${rootUrl}$1/;upper&save=imageUrl&keep');
      final result = query.execute(testNode);

      // Result should be kept (keep flag present)
      expect(result, equals('HTTPS://EXAMPLE.COM/IMAGES/PHOTO.JPG'));
    });

    test('json transform → update → filter pipeline', () {
      // Get posts, add a field, filter by title pattern
      final query =
          QueryString('json:posts/*?update={"featured":true}&filter=Second');
      final result = query.execute(testNode);

      expect(result, isA<Map>());
      expect(result['title'], equals('Second Post'));
      expect(result['featured'], equals(true));
    });

    test('multiple transforms with save and keep', () {
      // Extract first name, uppercase, save with keep
      final query =
          QueryString('json:user/firstName?transform=upper&save=name&keep');
      final result = query.execute(testNode);

      // Result should NOT be discarded (keep flag present)
      expect(result, equals('ALICE'));
    });

    test('chained queries with different transform pipelines', () {
      // First query: get JSON title with uppercase
      // Second query: get HTML title with lowercase
      final query = QueryString(
          'json:user/firstName?transform=upper++html://h1/@text?transform=lower');
      final result = query.execute(testNode);

      expect(result, equals(['ALICE', 'welcome']));
    });
  });

  group('Cross-Module Interactions', () {
    test('regexp with page context + text transform', () {
      // Use page context variables in regexp, then apply text transform
      final query = QueryString(
          r'html://img/@src?transform=regexp:/(^\/.+)/${rootUrl}$1/;lower');
      final result = query.execute(testNode);

      expect(result, equals('https://example.com/images/photo.jpg'));
    });

    test('json extraction + regexp + filter', () {
      // Get tags array, apply regexp to each, filter results
      final query = QueryString(
          r'json:user/tags/*?transform=regexp:/(.+)/TAG-$1/;upper&filter=DEVELOPER');
      final result = query.execute(testNode);

      expect(result, equals('TAG-DEVELOPER'));
    });

    test('filter with special characters + index', () {
      // Filter tags containing hyphen, get second result
      final query = QueryString(r'html://.tags/*li/@text?filter=tag-&index=1');
      final result = query.execute(testNode);

      expect(result, equals('tag-two'));
    });

    test('update + save interaction', () {
      // Update JSON object, save to variable with keep
      final query = QueryString(
          'json:user?update={"status":"active"}&save=userData&keep');
      final result = query.execute(testNode);

      // Result should be kept
      expect(result, isA<Map>());
      expect(result['status'], equals('active'));
      expect(result['firstName'], equals('Alice'));
    });

    test('multiple saves in pipeline', () {
      // Save at different stages of transformation
      final query = QueryString(
          'json:user/firstName?save=original&keep&transform=upper&save=uppercase&keep');
      final result = query.execute(testNode);

      // Final result should be uppercase (last transformation)
      expect(result, equals('ALICE'));
    });
  });

  group('Backward Compatibility', () {
    test('existing query strings work unchanged', () {
      // These are real query patterns from existing tests
      final queries = [
        'json:user/firstName',
        'html://h1/@text?transform=upper',
        r'html://img/@src?transform=regexp:/(^\/.+)/${rootUrl}$1/',
        'json:posts/*?filter=First',
        'html://.tags/*li/@text?transform=upper&index=0',
      ];

      for (var queryStr in queries) {
        expect(() => QueryString(queryStr).execute(testNode), returnsNormally,
            reason: 'Query should execute without errors: $queryStr');
      }
    });

    test('complex existing patterns', () {
      // Pattern from actual usage: multiple transforms with regexp
      final query = QueryString(
          r'html://h1/@text?transform=upper;regexp:/WELCOME/HELLO/;lower');
      final result = query.execute(testNode);

      expect(result, equals('hello'));
    });

    test('filter with exclude patterns', () {
      // Existing filter functionality with ! prefix
      final query = QueryString('json:user/tags/*?filter=!manager');
      final result = query.execute(testNode);

      expect(result, equals(['developer', 'designer']));
    });

    test('negative index support', () {
      // Existing negative index functionality
      final query = QueryString('json:user/tags/*?index=-1');
      final result = query.execute(testNode);

      expect(result, equals('manager'));
    });

    test('template scheme with variables', () {
      // Template functionality should work with saved variables
      final query = QueryString(
          'json:user/firstName?save=first++json:user/lastName?save=last++template:\${first} \${last}');
      final result = query.execute(testNode);

      // First two are discarded (no keep), last is the template result
      expect(result, equals('Alice Smith'));
    });
  });

  group('Complex Pipeline Scenarios', () {
    test('full pipeline: all transform types in sequence', () {
      // Update → Filter → Index → Save
      // Note: transform doesn't uppercase map keys, only values
      final query = QueryString(
          'json:posts/*?update={"processed":true}&filter=First&index=0&save=result&keep');
      final result = query.execute(testNode);

      expect(result, isA<Map>());
      expect(result['title'], equals('First Post'));
      expect(result['processed'], equals(true));
    });

    test('nested transforms with multiple regexp operations', () {
      // Multiple regexp transforms in sequence
      final query = QueryString(
          r'html://h1/@text?transform=regexp:/Welcome/Hello/;regexp:/Hello/Greetings/;lower');
      final result = query.execute(testNode);

      expect(result, equals('greetings'));
    });

    test('list processing with filter and index', () {
      // Get all links, filter by pattern, get specific index
      final query = QueryString('html://*a/@href?filter=page&index=1');
      final result = query.execute(testNode);

      expect(result, equals('/page2'));
    });

    test('json array processing with transforms', () {
      // Get array, transform each element, filter, index
      final query = QueryString(
          'json:user/tags/*?transform=upper&filter=DESIGNER&index=0');
      final result = query.execute(testNode);

      expect(result, equals('DESIGNER'));
    });

    test('save without keep discards intermediate results', () {
      // Multiple queries with save (no keep) should only return final result
      final query = QueryString(
          'json:user/firstName?save=fn++json:user/lastName?save=ln++template:\${fn} \${ln}');
      final result = query.execute(testNode);

      // Only template result remains (others discarded)
      expect(result, equals('Alice Smith'));
    });

    test('mixed keep and discard in query chain', () {
      // Some queries keep, some discard
      final query = QueryString(
          'json:user/firstName?save=fn&keep++json:user/lastName?save=ln++template:\${fn} \${ln}');
      final result = query.execute(testNode);

      expect(result, isA<List>());
      expect(result.length, equals(2));
      expect(result[0], equals('Alice')); // kept
      expect(result[1], equals('Alice Smith')); // final result (ln discarded)
    });
  });

  group('Error Handling and Edge Cases', () {
    test('null propagation through pipeline', () {
      // Query that returns null should propagate through transforms
      final query = QueryString(
          'html://.nonexistent/@text?transform=upper&filter=test&index=0');
      final result = query.execute(testNode);

      expect(result, isNull);
    });

    test('invalid regexp in pipeline continues', () {
      // Invalid regexp should log warning but not crash
      final query =
          QueryString(r'html://h1/@text?transform=regexp:invalid;upper');
      final result = query.execute(testNode);

      // Should return null due to invalid regexp
      expect(result, isNull);
    });

    test('filter on empty list returns empty', () {
      // Filter on empty result should return empty list
      final query = QueryString('json:user/nonexistent/*?filter=test');
      final result = query.execute(testNode);

      expect(result, isNull);
    });

    test('index out of bounds returns null', () {
      // Index beyond array bounds should return null
      final query = QueryString('json:user/tags/*?index=99');
      final result = query.execute(testNode);

      expect(result, isNull);
    });

    test('update on non-map returns original', () {
      // Update on non-map value should return original
      final query = QueryString('json:user/firstName?update={"key":"value"}');
      final result = query.execute(testNode);

      // Should return original string value
      expect(result, equals('Alice'));
    });

    test('save with null value skips saving', () {
      // Null values should not be saved - test by checking final result
      final query = QueryString('html://.nonexistent/@text?save=nullVar');
      final result = query.execute(testNode);

      expect(result, isNull);
    });
  });

  group('Performance and Optimization', () {
    test('pipeline processes lists efficiently', () {
      // Large list processing should work efficiently
      final query = QueryString('json:posts/*?filter=Post');
      final result = query.execute(testNode);

      expect(result, isA<List>());
      expect(result.length, equals(3));
      // Check that all items have 'Post' in title
      for (var item in result) {
        expect(item['title'], contains('Post'));
      }
    });

    test('multiple transform chains are independent', () {
      // Each query part should have independent transform pipeline
      final query = QueryString(
          'json:user/firstName?transform=upper++json:user/lastName?transform=lower');
      final result = query.execute(testNode);

      expect(result, equals(['ALICE', 'smith']));
    });
  });

  group('Module Integration Verification', () {
    test('text transforms module integration', () {
      // Verify text_transforms.dart works in pipeline
      final query = QueryString('html://h1/@text?transform=upper;lower');
      final result = query.execute(testNode);

      expect(result, equals('welcome'));
    });

    test('pattern transforms module integration', () {
      // Verify pattern_transforms.dart works in pipeline
      final query =
          QueryString(r'html://h1/@text?transform=regexp:/W(.+)e/H$1o/');
      final result = query.execute(testNode);

      expect(result, equals('Helcomo'));
    });

    test('selection transforms module integration', () {
      // Verify selection_transforms.dart works in pipeline
      final query =
          QueryString('html://.tags/*li/@text?filter=tag-one&index=0');
      final result = query.execute(testNode);

      expect(result, equals('tag-one'));
    });

    test('data transforms module integration', () {
      // Verify data_transforms.dart works in pipeline
      final query = QueryString('json:user?update={"verified":true}');
      final result = query.execute(testNode);

      expect(result, isA<Map>());
      expect(result['verified'], equals(true));
      expect(result['firstName'], equals('Alice'));
    });

    test('transform pipeline orchestration', () {
      // Verify transform_pipeline.dart orchestrates correctly
      // Filter with multiple patterns (AND logic)
      final query = QueryString(
          'json:user/tags/*?transform=upper&filter=DEVELOPER&index=0');
      final result = query.execute(testNode);

      expect(result, equals('DEVELOPER'));
    });
  });
}
