/// Pattern Transforms - Regular expression matching and replacement
///
/// This module provides powerful pattern matching and text replacement using
/// regular expressions. Supports both extraction and replacement modes with
/// special features for web scraping scenarios.
///
/// ## Transform Modes
///
/// ### Pattern-Only Mode (Extraction)
/// Format: `/pattern/`
///
/// Extracts the first match of the pattern from the input value.
///
/// ```dart
/// applyRegexpTransform(node, 'Price: $19.99', r'/\$[\d.]+/');
/// // Returns: '$19.99'
/// ```
///
/// ### Replace Mode
/// Format: `/pattern/replacement/`
///
/// Replaces all matches of the pattern with the replacement string.
///
/// ```dart
/// applyRegexpTransform(node, 'hello world', r'/world/universe/');
/// // Returns: 'hello universe'
/// ```
///
/// ## Special Features
///
/// ### Capture Groups
/// Use `$0`, `$1`, `$2`, etc. in replacements to reference captured groups:
///
/// ```dart
/// applyRegexpTransform(node, 'John Doe', r'/(\w+) (\w+)/$2, $1/');
/// // Returns: 'Doe, John'
/// ```
///
/// ### \ALL Keyword
/// Matches the entire string including newlines:
///
/// ```dart
/// applyRegexpTransform(node, 'line1\nline2', r'/\ALL/replaced/');
/// // Returns: 'replaced'
/// ```
///
/// ### Page Context Variables
/// Reference page URL information in replacements:
///
/// - `${pageUrl}` - Full page URL
/// - `${rootUrl}` - Origin (scheme + authority)
///
/// ```dart
/// applyRegexpTransform(node, '/path/to/page', r'/^//${rootUrl}/');
/// // Returns: 'https://example.com/path/to/page'
/// ```
///
/// ## Usage Examples
///
/// ### Extract Price
/// ```dart
/// final text = 'Product costs $29.99 today';
/// final price = applyRegexpTransform(node, text, r'/\$[\d.]+/');
/// // Returns: '$29.99'
/// ```
///
/// ### Clean HTML Tags
/// ```dart
/// final html = '<p>Hello <b>world</b></p>';
/// final clean = applyRegexpTransform(node, html, r'/<[^>]+>//');
/// // Returns: 'Hello world'
/// ```
///
/// ### Convert Relative URLs
/// ```dart
/// final relative = '/images/photo.jpg';
/// final absolute = applyRegexpTransform(
///   node,
///   relative,
///   r'/^//${rootUrl}/'
/// );
/// // Returns: 'https://example.com/images/photo.jpg'
/// ```
///
/// ### Extract and Reformat
/// ```dart
/// final date = '2024-12-05';
/// final formatted = applyRegexpTransform(
///   node,
///   date,
///   r'/(\d{4})-(\d{2})-(\d{2})/$2/$3/$1/'
/// );
/// // Returns: '12/05/2024'
/// ```
///
/// ## Error Handling
///
/// - Invalid pattern format: logs warning, returns original value
/// - Regexp compilation errors: logs warning, returns original value
/// - URL parsing errors: leaves context variables unsubstituted
///
/// ## Pattern Format
///
/// Patterns must be enclosed in forward slashes:
/// - Extraction: `/pattern/`
/// - Replacement: `/pattern/replacement/`
///
/// Escaped slashes in patterns are supported: `\/`
library;

import 'package:logging/logging.dart';

import '../page_data.dart';

final _log = Logger('QueryString.Transforms.Pattern');

/// Apply regexp transform to a value
///
/// Performs pattern matching and optional replacement using regular expressions.
/// Supports both extraction mode (pattern only) and replacement mode.
///
/// ## Parameters
///
/// - [node] - PageNode for accessing page context (URL information)
/// - [value] - The input value to transform
/// - [pattern] - Regexp pattern in format `/pattern/` or `/pattern/replacement/`
///
/// ## Modes
///
/// ### Extraction Mode
/// When only pattern is provided (no replacement), returns the first match:
/// ```dart
/// applyRegexpTransform(node, 'abc123def', r'/\d+/');  // '123'
/// ```
///
/// ### Replacement Mode
/// When replacement is provided, replaces all matches:
/// ```dart
/// applyRegexpTransform(node, 'hello', r'/l/L/');  // 'heLLo'
/// ```
///
/// ## Special Features
///
/// - **Capture groups**: Use `$0`, `$1`, `$2` in replacements
/// - **\ALL keyword**: Matches entire string including newlines
/// - **Page context**: Use `${pageUrl}` and `${rootUrl}` in replacements
/// - **Multiline**: Patterns use multiline mode by default
///
/// ## Returns
///
/// - Extraction mode: First match or null if no match
/// - Replacement mode: String with all matches replaced
/// - null if input is null
/// - Original value if pattern is invalid
///
/// ## Examples
///
/// ```dart
/// // Extract
/// applyRegexpTransform(node, 'Price: $19.99', r'/\$[\d.]+/');  // '$19.99'
///
/// // Replace
/// applyRegexpTransform(node, 'hello', r'/l/L/');  // 'heLLo'
///
/// // Capture groups
/// applyRegexpTransform(node, 'John Doe', r'/(\w+) (\w+)/$2, $1/');  // 'Doe, John'
///
/// // Page context
/// applyRegexpTransform(node, '/path', r'/^//${rootUrl}/');  // 'https://example.com/path'
/// ```
dynamic applyRegexpTransform(PageNode node, dynamic value, String pattern) {
  if (value == null) return null;

  // Parse the pattern to extract pattern and replacement parts
  final parsed = parseRegexpPattern(pattern);
  if (parsed == null) {
    _log.warning(
        'Invalid regexp format. Use: /pattern/ or /pattern/replacement/');
    return value;
  }

  final regexPattern = parsed.pattern;
  final replacement = parsed.replacement;

  try {
    final regexp = RegExp(regexPattern, multiLine: true);
    final valueStr = value.toString();

    // Pattern-only mode (empty replacement part)
    if (replacement.isEmpty) {
      final match = regexp.firstMatch(valueStr);
      return match?.group(0);
    }

    // Replace mode
    final preparedReplacement = prepareReplacement(node, replacement);
    return valueStr.replaceAllMapped(regexp, (Match match) {
      var result = preparedReplacement;
      for (var i = 1; i <= match.groupCount; i++) {
        result = result.replaceAll('\$$i', match.group(i) ?? '');
      }
      return result.replaceAll(r'$0', match.group(0) ?? '');
    });
  } catch (e) {
    _log.warning('Failed to apply regexp: $regexPattern, error: $e');
    return value;
  }
}

/// Parse regexp pattern string into pattern and replacement parts
///
/// Extracts the pattern and optional replacement from a regexp transform string.
/// Handles escaped slashes and special characters.
///
/// ## Parameters
///
/// - [pattern] - Regexp string in format `/pattern/` or `/pattern/replacement/`
///
/// ## Returns
///
/// A record with:
/// - `pattern` - The regular expression pattern
/// - `replacement` - The replacement string (empty for extraction mode)
///
/// Returns null if the format is invalid (no slashes found).
///
/// ## Format
///
/// - Extraction: `/pattern/` → `(pattern: 'pattern', replacement: '')`
/// - Replacement: `/pattern/replacement/` → `(pattern: 'pattern', replacement: 'replacement')`
///
/// ## Special Handling
///
/// - **Escaped slashes**: `\/` in patterns are preserved
/// - **\ALL keyword**: Converted to `^[\s\S]*$` for full string matching
/// - **Escaped characters**: `\/`, `\;` are unescaped in replacement
///
/// ## Examples
///
/// ```dart
/// parseRegexpPattern(r'/\d+/');
/// // Returns: (pattern: r'\d+', replacement: '')
///
/// parseRegexpPattern(r'/hello/world/');
/// // Returns: (pattern: 'hello', replacement: 'world')
///
/// parseRegexpPattern(r'/\ALL/replaced/');
/// // Returns: (pattern: r'^[\s\S]*$', replacement: 'replaced')
///
/// parseRegexpPattern('invalid');
/// // Returns: null
/// ```
({String pattern, String replacement})? parseRegexpPattern(String pattern) {
  // Decode pattern after splitting to preserve escaped slashes
  final parts =
      pattern.split(RegExp(r'(?<!\\)/')).where((e) => e.isNotEmpty).toList();

  if (parts.isEmpty) {
    return null;
  }

  // If only pattern provided, replacement is empty
  if (parts.length == 1) {
    parts.add("");
  }

  // Decode special characters in pattern
  var regexPattern = parts[0];

  // Handle \ALL keyword - matches entire string including newlines
  if (regexPattern.contains(r'\ALL')) {
    regexPattern = regexPattern.replaceAll(r'\ALL', r'^[\s\S]*$');
  }

  // Decode escaped characters in replacement
  final replacementStr = parts[1].replaceAll(r'\/', '/').replaceAll(r'\;', ';');

  return (pattern: regexPattern, replacement: replacementStr);
}

/// Prepare replacement string by substituting page context variables
///
/// Replaces page context variables in the replacement string with actual values
/// from the page URL. Useful for converting relative URLs to absolute URLs.
///
/// ## Parameters
///
/// - [node] - PageNode containing page data and URL
/// - [replacement] - Replacement string potentially containing context variables
///
/// ## Supported Variables
///
/// - **${pageUrl}** - Full page URL (e.g., `https://example.com/page?q=1`)
/// - **${rootUrl}** - Origin only (e.g., `https://example.com`)
///
/// ## Returns
///
/// Replacement string with context variables substituted. If URL parsing fails,
/// variables are left unchanged.
///
/// ## Examples
///
/// ```dart
/// // Assuming page URL is 'https://example.com/page'
///
/// prepareReplacement(node, 'Visit ${pageUrl}');
/// // Returns: 'Visit https://example.com/page'
///
/// prepareReplacement(node, '${rootUrl}/api/data');
/// // Returns: 'https://example.com/api/data'
///
/// prepareReplacement(node, 'No variables here');
/// // Returns: 'No variables here'
/// ```
///
/// ## Use Cases
///
/// ### Convert Relative to Absolute URLs
/// ```dart
/// applyRegexpTransform(node, '/images/photo.jpg', r'/^//${rootUrl}/');
/// // Returns: 'https://example.com/images/photo.jpg'
/// ```
///
/// ### Add Page Reference
/// ```dart
/// applyRegexpTransform(node, 'Link', r'/Link/Link (from ${pageUrl})/');
/// // Returns: 'Link (from https://example.com/page)'
/// ```
String prepareReplacement(PageNode node, String replacement) {
  var result = replacement;

  try {
    final pageUri = Uri.parse(node.pageData.url);
    // Replace pageUrl with full URL
    result = result.replaceAll(r'${pageUrl}', node.pageData.url);
    // Replace rootUrl with origin (scheme + authority)
    result = result.replaceAll(r'${rootUrl}', pageUri.origin);
  } catch (e) {
    // If URL parsing fails, leave replacement unchanged
  }

  return result;
}
