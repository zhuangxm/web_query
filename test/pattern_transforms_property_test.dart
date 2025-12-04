import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/query.dart';
import 'package:web_query/src/transforms/pattern_transforms.dart';

void main() {
  group('Pattern Transforms Property Tests', () {
    final random = Random(42); // Seed for reproducibility

    /// **Feature: transform-reorganization, Property 5: Regexp page context substitution**
    /// **Validates: Requirements 4.3**
    ///
    /// For any regexp replacement pattern containing ${pageUrl} or ${rootUrl},
    /// and any PageNode with a valid URL, the replacement should substitute
    /// these variables with the correct page URL and root URL respectively.
    test('Property 5: Regexp page context substitution', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        // Generate random URL components
        final scheme = random.nextBool() ? 'https' : 'http';
        final domain = _generateRandomDomain(random);
        final path = _generateRandomPath(random);
        final fullUrl = '$scheme://$domain$path';
        final expectedRootUrl = '$scheme://$domain';

        // Create PageNode with the generated URL
        const html = '<div>test</div>';
        final pageData = PageData(fullUrl, html);
        final node = pageData.getRootElement();

        // Test ${pageUrl} substitution
        final pageUrlReplacement = 'URL is: \${pageUrl}';
        final pageUrlResult = prepareReplacement(node, pageUrlReplacement);
        expect(
          pageUrlResult,
          equals('URL is: $fullUrl'),
          reason:
              'prepareReplacement should substitute \${pageUrl} with full URL',
        );

        // Test ${rootUrl} substitution
        final rootUrlReplacement = 'Root is: \${rootUrl}';
        final rootUrlResult = prepareReplacement(node, rootUrlReplacement);
        expect(
          rootUrlResult,
          equals('Root is: $expectedRootUrl'),
          reason:
              'prepareReplacement should substitute \${rootUrl} with origin',
        );

        // Test both substitutions together
        final bothReplacement = 'Page: \${pageUrl}, Root: \${rootUrl}';
        final bothResult = prepareReplacement(node, bothReplacement);
        expect(
          bothResult,
          equals('Page: $fullUrl, Root: $expectedRootUrl'),
          reason:
              'prepareReplacement should substitute both \${pageUrl} and \${rootUrl}',
        );

        // Test multiple occurrences
        final multipleReplacement = '\${pageUrl} and \${pageUrl} again';
        final multipleResult = prepareReplacement(node, multipleReplacement);
        expect(
          multipleResult,
          equals('$fullUrl and $fullUrl again'),
          reason:
              'prepareReplacement should substitute multiple occurrences of \${pageUrl}',
        );

        // Test in actual regexp transform
        final testValue = 'original text';
        final pattern = '/original/\${pageUrl}/';
        final result = applyRegexpTransform(node, testValue, pattern);
        expect(
          result,
          equals('$fullUrl text'),
          reason:
              'applyRegexpTransform should use prepareReplacement for context substitution',
        );
      }
    });

    /// Additional test: Verify regexp transform with no context variables
    test('Property: Regexp transform without context variables', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        // Test simple replacement without context variables
        final replacement = _generateRandomString(random, 5, 15);
        final preparedReplacement = 'replaced: $replacement';
        final result = prepareReplacement(node, preparedReplacement);

        expect(
          result,
          equals(preparedReplacement),
          reason:
              'prepareReplacement should leave text unchanged when no context variables present',
        );
      }
    });

    /// Additional test: Verify regexp pattern-only mode (extraction)
    test('Property: Regexp pattern-only mode extracts first match', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        // Generate test string with known pattern
        final prefix = _generateRandomString(random, 3, 8);
        final target = _generateRandomString(random, 5, 10);
        final suffix = _generateRandomString(random, 3, 8);
        final testValue = '$prefix$target$suffix';

        // Pattern-only mode (no replacement)
        final pattern = '/$target/';
        final result = applyRegexpTransform(node, testValue, pattern);

        expect(
          result,
          equals(target),
          reason: 'Pattern-only mode should extract the first match',
        );
      }
    });

    /// Additional test: Verify regexp replacement mode
    test('Property: Regexp replacement mode replaces all matches', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        // Generate test string with repeated pattern
        final pattern = _generateRandomString(random, 3, 6);
        final replacement = _generateRandomString(random, 3, 6);
        final occurrences = 2 + random.nextInt(4); // 2-5 occurrences
        final testValue = List.generate(occurrences, (_) => pattern).join(' ');

        // Replace mode
        final regexpPattern = '/$pattern/$replacement/';
        final result = applyRegexpTransform(node, testValue, regexpPattern);

        final expected =
            List.generate(occurrences, (_) => replacement).join(' ');
        expect(
          result,
          equals(expected),
          reason: 'Replacement mode should replace all occurrences of pattern',
        );
      }
    });

    /// Additional test: Verify null handling
    test('Property: Regexp transform handles null gracefully', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        final pattern = '/test/replaced/';

        expect(
          () => applyRegexpTransform(node, null, pattern),
          returnsNormally,
          reason: 'applyRegexpTransform should not throw on null input',
        );

        final result = applyRegexpTransform(node, null, pattern);
        expect(
          result,
          isNull,
          reason: 'applyRegexpTransform should return null for null input',
        );
      }
    });

    /// Additional test: Verify invalid pattern handling
    test('Property: Regexp transform handles invalid patterns gracefully', () {
      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        final testValue = _generateRandomString(random, 10, 20);

        // Invalid patterns (no slashes, empty, etc.)
        final invalidPatterns = [
          '',
          'no-slashes',
          '/',
          '//',
        ];

        for (var invalidPattern in invalidPatterns) {
          expect(
            () => applyRegexpTransform(node, testValue, invalidPattern),
            returnsNormally,
            reason:
                'applyRegexpTransform should not throw on invalid pattern: $invalidPattern',
          );

          final result = applyRegexpTransform(node, testValue, invalidPattern);
          // Should return original value or null, not throw
          expect(
            result,
            anyOf(equals(testValue), isNull),
            reason:
                'applyRegexpTransform should return original value or null for invalid pattern',
          );
        }
      }
    });

    /// Additional test: Verify capture group substitution
    test('Property: Regexp replacement supports capture groups', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        final url = _generateRandomUrl(random);
        const html = '<div>test</div>';
        final pageData = PageData(url, html);
        final node = pageData.getRootElement();

        // Generate test string with capturable parts
        final part1 = _generateRandomString(random, 3, 6);
        final part2 = _generateRandomString(random, 3, 6);
        final testValue = '$part1-$part2';

        // Pattern with capture groups
        final pattern = '/($part1)-($part2)/\$2-\$1/';
        final result = applyRegexpTransform(node, testValue, pattern);

        expect(
          result,
          equals('$part2-$part1'),
          reason:
              'Regexp replacement should support capture group substitution',
        );
      }
    });
  });
}

/// Generate a random URL for testing
String _generateRandomUrl(Random random) {
  final scheme = random.nextBool() ? 'https' : 'http';
  final domain = _generateRandomDomain(random);
  final path = _generateRandomPath(random);
  return '$scheme://$domain$path';
}

/// Generate a random domain name
String _generateRandomDomain(Random random) {
  final subdomain = random.nextBool()
      ? '${_generateRandomString(random, 3, 8, lowercase: true)}.'
      : '';
  final domain = _generateRandomString(random, 5, 12, lowercase: true);
  final tlds = ['com', 'org', 'net', 'io', 'dev', 'app'];
  final tld = tlds[random.nextInt(tlds.length)];
  return '$subdomain$domain.$tld';
}

/// Generate a random URL path
String _generateRandomPath(Random random) {
  if (random.nextInt(3) == 0) return ''; // Sometimes no path

  final segments = 1 + random.nextInt(4); // 1-4 path segments
  final pathParts = List.generate(
    segments,
    (_) => _generateRandomString(random, 3, 10, lowercase: true),
  );
  return '/${pathParts.join('/')}';
}

/// Generate a random string
String _generateRandomString(Random random, int minLength, int maxLength,
    {bool lowercase = false}) {
  final chars = lowercase
      ? 'abcdefghijklmnopqrstuvwxyz0123456789'
      : 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final length = minLength + random.nextInt(maxLength - minLength + 1);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}
