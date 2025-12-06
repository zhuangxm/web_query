/// Selection Transforms - Filtering and indexing operations
///
/// This module provides data selection operations for filtering lists based on
/// patterns and extracting specific elements by index. These transforms help
/// narrow down query results to exactly what you need.
///
/// ## Supported Operations
///
/// ### Filter Transform
/// Filter values based on include/exclude patterns:
/// - **Include patterns**: Keep values containing the pattern
/// - **Exclude patterns**: Remove values containing the pattern (prefix with `!`)
/// - **Multiple patterns**: Combine patterns with spaces (all must match)
/// - **Escaped characters**: Use `\ `, `\;`, `\&` for literal characters
///
/// ### Index Transform
/// Extract a single element from a list:
/// - **Positive indices**: 0-based indexing from start
/// - **Negative indices**: Count from end (-1 = last element)
/// - **Bounds checking**: Out-of-bounds returns null
///
/// ## Usage Examples
///
/// ### Basic Filtering
/// ```dart
/// final fruits = ['Apple', 'Banana', 'Cherry'];
///
/// applyFilter(fruits, 'a');
/// // Returns: ['Apple', 'Banana', 'Cherry'] (all contain 'a')
///
/// applyFilter(fruits, 'Apple');
/// // Returns: ['Apple']
///
/// applyFilter(fruits, '!Banana');
/// // Returns: ['Apple', 'Cherry']
/// ```
///
/// ### Multiple Patterns
/// ```dart
/// final items = ['Red Apple', 'Green Apple', 'Red Banana'];
///
/// applyFilter(items, 'Apple Red');
/// // Returns: ['Red Apple'] (must contain both)
///
/// applyFilter(items, 'Apple !Red');
/// // Returns: ['Green Apple'] (has Apple, not Red)
/// ```
///
/// ### Escaped Characters
/// ```dart
/// final items = ['Date Fruit', 'Date Time', 'DateTime'];
///
/// applyFilter(items, r'Date\ Fruit');
/// // Returns: ['Date Fruit'] (literal space)
///
/// applyFilter(items, r'Date\;Time');
/// // Returns: ['Date;Time'] (literal semicolon)
/// ```
///
/// ### Indexing
/// ```dart
/// final list = ['first', 'second', 'third'];
///
/// applyIndex(list, '0');   // 'first'
/// applyIndex(list, '1');   // 'second'
/// applyIndex(list, '-1');  // 'third' (last)
/// applyIndex(list, '-2');  // 'second' (second to last)
/// applyIndex(list, '10');  // null (out of bounds)
/// ```
///
/// ### Single Value Indexing
/// ```dart
/// applyIndex('value', '0');  // 'value'
/// applyIndex('value', '1');  // null
/// ```
///
/// ## Filter Pattern Syntax
///
/// Patterns are space-separated and can be:
/// - **Include**: `pattern` - value must contain this
/// - **Exclude**: `!pattern` - value must NOT contain this
/// - **Escaped space**: `\ ` - literal space in pattern
/// - **Escaped semicolon**: `\;` - literal semicolon
/// - **Escaped ampersand**: `\&` - literal ampersand
///
/// All patterns in a filter must match for a value to pass.
///
/// ## Index Format
///
/// - **Positive**: `0`, `1`, `2`, ... (0-based from start)
/// - **Negative**: `-1`, `-2`, `-3`, ... (from end, -1 = last)
/// - **Invalid**: Non-numeric strings log warning and return null
///
/// ## Error Handling
///
/// - Invalid index format: logs warning, returns null
/// - Out-of-bounds index: returns null (no warning, expected behavior)
/// - Empty filter pattern: returns original value
/// - Null input: returns null
library;

import 'package:logging/logging.dart';

import '../query_result.dart';

final _log = Logger('QueryString.Transforms.Selection');

/// Applies a filter to a value or list of values
///
/// Filters values based on include and exclude patterns. All patterns must
/// match for a value to pass the filter.
///
/// ## Parameters
///
/// - [value] - Value or list to filter
/// - [filter] - Filter pattern string (space-separated patterns)
///
/// ## Pattern Syntax
///
/// - **Include**: `pattern` - Keep values containing this pattern
/// - **Exclude**: `!pattern` - Remove values containing this pattern
/// - **Multiple**: `pattern1 pattern2` - All patterns must match
/// - **Escaped**: `\ `, `\;`, `\&` - Literal special characters
///
/// ## Returns
///
/// - For lists: Filtered list containing only matching values
/// - For single values: The value if it matches, null otherwise
/// - For null input: null
///
/// ## Examples
///
/// ```dart
/// // Include pattern
/// applyFilter(['Apple', 'Banana'], 'Apple');  // ['Apple']
///
/// // Exclude pattern
/// applyFilter(['Apple', 'Banana'], '!Apple');  // ['Banana']
///
/// // Multiple patterns (AND logic)
/// applyFilter(['Red Apple', 'Green Apple'], 'Apple Red');  // ['Red Apple']
///
/// // Escaped space
/// applyFilter(['Date Fruit', 'DateTime'], r'Date\ Fruit');  // ['Date Fruit']
///
/// // Single value
/// applyFilter('Apple', 'App');  // 'Apple'
/// applyFilter('Apple', 'Ban');  // null
/// ```
dynamic applyFilter(dynamic value, String filter) {
  final parts = parseFilterPattern(filter);

  return applyFilterByList(value, parts);
}

dynamic applyFilterByList(dynamic value, List<String> parts) {
  if (value == null) return null;
  if (parts.isEmpty) return value;

  bool check(dynamic v) {
    final str = v.toString();
    for (var part in parts) {
      var isExclude = false;
      var pattern = part;

      if (pattern.startsWith('!')) {
        isExclude = true;
        pattern = pattern.substring(1);
      }

      // Skip empty patterns (they would match everything)
      if (pattern.isEmpty) continue;

      if (isExclude) {
        if (str.contains(pattern)) return false;
      } else {
        if (!str.contains(pattern)) return false;
      }
    }
    return true;
  }

  if (value is List) {
    return value.where(check).toList();
  } else {
    return check(value) ? value : null;
  }
}

/// Parses a filter pattern string into individual filter parts
///
/// Splits the filter string by spaces while respecting escaped special characters.
/// Unescapes the special characters in the resulting parts.
///
/// ## Parameters
///
/// - [filter] - Filter pattern string with space-separated patterns
///
/// ## Returns
///
/// List of individual filter patterns with special characters unescaped
///
/// ## Escaping Rules
///
/// - `\ ` → ` ` (space)
/// - `\;` → `;` (semicolon)
/// - `\&` → `&` (ampersand)
///
/// ## Examples
///
/// ```dart
/// parseFilterPattern('Apple Banana');
/// // Returns: ['Apple', 'Banana']
///
/// parseFilterPattern('!Apple Banana');
/// // Returns: ['!Apple', 'Banana']
///
/// parseFilterPattern(r'Date\ Fruit');
/// // Returns: ['Date Fruit']
///
/// parseFilterPattern(r'key\;value param\&name');
/// // Returns: ['key;value', 'param&name']
///
/// parseFilterPattern('');
/// // Returns: []
/// ```
List<String> parseFilterPattern(String filter) {
  // Split filter string by space, respecting escaped spaces
  final parts = filter.splitKeep(RegExp(r'(?<!\\) '));
  final result = <String>[];

  for (var part in parts) {
    // Skip separator spaces
    if (part == ' ') continue;

    // Unescape special characters
    final unescaped = part
        .replaceAll(r'\ ', ' ')
        .replaceAll(r'\;', ';')
        .replaceAll(r'\&', '&');

    // Only add non-empty parts
    if (unescaped.isNotEmpty) {
      result.add(unescaped);
    }
  }

  return result;
}

/// Applies an index operation to extract a single element from a list
///
/// Extracts a single element from a list using 0-based indexing. Supports
/// both positive indices (from start) and negative indices (from end).
///
/// ## Parameters
///
/// - [value] - List or single value to index
/// - [indexStr] - Index as string (e.g., '0', '-1', '5')
///
/// ## Index Types
///
/// - **Positive**: 0-based from start (0 = first, 1 = second, ...)
/// - **Negative**: From end (-1 = last, -2 = second to last, ...)
///
/// ## Returns
///
/// - For lists: Element at the specified index, or null if out of bounds
/// - For single values: The value if index is 0, null otherwise
/// - For null input: null
/// - For invalid index format: null (logs warning)
///
/// ## Examples
///
/// ```dart
/// final list = ['a', 'b', 'c', 'd'];
///
/// // Positive indices
/// applyIndex(list, '0');   // 'a' (first)
/// applyIndex(list, '1');   // 'b' (second)
/// applyIndex(list, '3');   // 'd' (fourth)
///
/// // Negative indices
/// applyIndex(list, '-1');  // 'd' (last)
/// applyIndex(list, '-2');  // 'c' (second to last)
/// applyIndex(list, '-4');  // 'a' (fourth from end)
///
/// // Out of bounds
/// applyIndex(list, '10');  // null
/// applyIndex(list, '-10'); // null
///
/// // Single value
/// applyIndex('value', '0');  // 'value'
/// applyIndex('value', '1');  // null
///
/// // Invalid format
/// applyIndex(list, 'abc');  // null (logs warning)
/// ```
///
/// ## Bounds Checking
///
/// Indices are checked against list bounds:
/// - Positive: Must be < list.length
/// - Negative: Must be >= -list.length
/// - Out-of-bounds returns null without error
dynamic applyIndex(dynamic value, String indexStr) {
  if (value == null) return null;

  // Parse index (handle negative indices)
  final index = int.tryParse(indexStr);
  if (index == null) {
    _log.warning('Invalid index value: $indexStr (must be an integer)');
    return null;
  }

  if (value is List) {
    if (value.isEmpty) return null;

    // Handle negative indices
    final actualIndex = index < 0 ? value.length + index : index;

    // Check bounds
    if (actualIndex < 0 || actualIndex >= value.length) {
      return null;
    }

    return value[actualIndex];
  }

  // For non-list values, index=0 returns the value, others return null
  return index == 0 ? value : null;
}
