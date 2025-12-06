/// Text Transforms - Text manipulation and encoding operations
///
/// This module provides text transformations including case conversion,
/// encoding/decoding, hashing, and string manipulation. Transforms work
/// on both single values and lists, applying the operation to each element
/// when given a list.
///
/// ## Supported Transforms
///
/// ### Case Conversion
/// - **upper** - Convert text to uppercase
/// - **lower** - Convert text to lowercase
///
/// ### Encoding/Decoding
/// - **base64** - Encode text to Base64
/// - **base64decode** - Decode Base64 to text
///
/// ### String Manipulation
/// - **reverse** - Reverse the string
///
/// ### Hashing
/// - **md5** - Generate MD5 hash of text
///
/// ## Usage Examples
///
/// ### Case Conversion
/// ```dart
/// applyTextTransform('Hello World', 'upper');  // 'HELLO WORLD'
/// applyTextTransform('Hello World', 'lower');  // 'hello world'
/// ```
///
/// ### Base64 Encoding/Decoding
/// ```dart
/// applyTextTransform('Hello', 'base64');  // 'SGVsbG8='
/// applyTextTransform('SGVsbG8=', 'base64decode');  // 'Hello'
/// ```
///
/// ### String Manipulation
/// ```dart
/// applyTextTransform('Hello', 'reverse');  // 'olleH'
/// ```
///
/// ### Hashing
/// ```dart
/// applyTextTransform('password', 'md5');  // '5f4dcc3b5aa765d61d8327deb882cf99'
/// ```
///
/// ### List of Values
/// ```dart
/// applyTextTransform(['Hello', 'World'], 'upper');  // ['HELLO', 'WORLD']
/// applyTextTransform(['abc', 'xyz'], 'base64');  // ['YWJj', 'eHl6']
/// ```
///
/// ### Null Handling
/// ```dart
/// applyTextTransform(null, 'upper');  // null
/// ```
///
/// ## Implementation Notes
///
/// - Non-string values are converted to strings using `toString()`
/// - Empty strings are preserved
/// - Unicode characters are handled correctly
/// - Null values propagate through without error
/// - Invalid Base64 in decode returns null and logs warning
library;

import 'package:logging/logging.dart';
import 'package:web_query/src/transforms/functions.dart';

final _log = Logger('QueryString.Transforms.Text');

/// Apply text transformation to a value
///
/// Applies text manipulation, encoding, or hashing operations to values.
/// Handles both single values and lists uniformly.
///
/// ## Parameters
///
/// - [value] - The value to transform (can be any type, will be converted to string)
/// - [transform] - The transform type (see supported transforms below)
///
/// ## Returns
///
/// - For single values: transformed string or null
/// - For lists: list of transformed strings
/// - For null input: null
///
/// ## Supported Transforms
///
/// - **'upper'** - Convert to uppercase
/// - **'lower'** - Convert to lowercase
/// - **'base64'** - Encode to Base64
/// - **'base64decode'** - Decode from Base64
/// - **'reverse'** - Reverse the string
/// - **'md5'** - Generate MD5 hash
///
/// ## Examples
///
/// ```dart
/// applyTextTransform('hello', 'upper');  // 'HELLO'
/// applyTextTransform('Hello', 'base64');  // 'SGVsbG8='
/// applyTextTransform('SGVsbG8=', 'base64decode');  // 'Hello'
/// applyTextTransform('hello', 'reverse');  // 'olleh'
/// applyTextTransform('test', 'md5');  // '098f6bcd4621d373cade4e832627b4f6'
/// applyTextTransform(['a', 'b'], 'upper');  // ['A', 'B']
/// applyTextTransform(null, 'upper');  // null
/// ```
dynamic applyTextTransform(dynamic value, String transform) {
  if (value == null) return null;

  if (value is List) {
    return value.map((v) => _applyTextTransformSingle(v, transform)).toList();
  }

  return _applyTextTransformSingle(value, transform);
}

/// Apply text transformation to a single value
dynamic _applyTextTransformSingle(dynamic value, String transform) {
  if (value == null) return null;

  switch (transform) {
    case 'upper':
      return toUpperCase(value);
    case 'lower':
      return toLowerCase(value);
    case 'base64':
      return base64Encode(value);
    case 'base64decode':
      return base64Decode(value);
    case 'reverse':
      return reverseString(value);
    case 'md5':
      return md5Hash(value);
    default:
      _log.warning('Unknown text transform: $transform');
      return value;
  }
}
