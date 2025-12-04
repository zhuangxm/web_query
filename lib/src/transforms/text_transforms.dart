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

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

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

/// Convert a value to uppercase
///
/// Converts any value to a string and applies uppercase transformation.
/// Uses Dart's built-in `String.toUpperCase()` which handles Unicode correctly.
///
/// ## Parameters
///
/// - [value] - Any value to convert (will be stringified with `toString()`)
///
/// ## Returns
///
/// Uppercase string, or null if input is null
///
/// ## Examples
///
/// ```dart
/// toUpperCase('hello');  // 'HELLO'
/// toUpperCase('Hello World');  // 'HELLO WORLD'
/// toUpperCase(123);  // '123'
/// toUpperCase(null);  // null
/// ```
String? toUpperCase(dynamic value) {
  if (value == null) return null;
  return value.toString().toUpperCase();
}

/// Convert a value to lowercase
///
/// Converts any value to a string and applies lowercase transformation.
/// Uses Dart's built-in `String.toLowerCase()` which handles Unicode correctly.
///
/// ## Parameters
///
/// - [value] - Any value to convert (will be stringified with `toString()`)
///
/// ## Returns
///
/// Lowercase string, or null if input is null
///
/// ## Examples
///
/// ```dart
/// toLowerCase('HELLO');  // 'hello'
/// toLowerCase('Hello World');  // 'hello world'
/// toLowerCase(123);  // '123'
/// toLowerCase(null);  // null
/// ```
String? toLowerCase(dynamic value) {
  if (value == null) return null;
  return value.toString().toLowerCase();
}

/// Encode a value to Base64
///
/// Converts any value to a string and encodes it to Base64 format.
/// Uses UTF-8 encoding for the input string.
///
/// ## Parameters
///
/// - [value] - Any value to encode (will be stringified with `toString()`)
///
/// ## Returns
///
/// Base64-encoded string, or null if input is null
///
/// ## Examples
///
/// ```dart
/// base64Encode('Hello');  // 'SGVsbG8='
/// base64Encode('Hello World');  // 'SGVsbG8gV29ybGQ='
/// base64Encode('');  // ''
/// base64Encode(null);  // null
/// ```
String? base64Encode(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return '';
  return base64.encode(utf8.encode(str));
}

/// Decode a Base64-encoded string
///
/// Decodes a Base64 string back to its original text using UTF-8 decoding.
/// Returns null if the input is not valid Base64.
///
/// ## Parameters
///
/// - [value] - Base64-encoded string to decode
///
/// ## Returns
///
/// Decoded string, or null if input is null or invalid Base64
///
/// ## Examples
///
/// ```dart
/// base64Decode('SGVsbG8=');  // 'Hello'
/// base64Decode('SGVsbG8gV29ybGQ=');  // 'Hello World'
/// base64Decode('');  // ''
/// base64Decode('invalid!!!');  // null (logs warning)
/// base64Decode(null);  // null
/// ```
String? base64Decode(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  if (str.isEmpty) return '';

  try {
    return utf8.decode(base64.decode(str));
  } catch (e) {
    _log.warning('Failed to decode Base64: $e');
    return null;
  }
}

/// Reverse a string
///
/// Reverses the characters in a string. Works correctly with Unicode
/// characters including emojis.
///
/// ## Parameters
///
/// - [value] - Any value to reverse (will be stringified with `toString()`)
///
/// ## Returns
///
/// Reversed string, or null if input is null
///
/// ## Examples
///
/// ```dart
/// reverseString('Hello');  // 'olleH'
/// reverseString('12345');  // '54321'
/// reverseString('a');  // 'a'
/// reverseString('');  // ''
/// reverseString(null);  // null
/// ```
String? reverseString(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  return str.split('').reversed.join('');
}

/// Generate MD5 hash of a value
///
/// Converts any value to a string and generates its MD5 hash.
/// Returns the hash as a lowercase hexadecimal string.
///
/// ## Parameters
///
/// - [value] - Any value to hash (will be stringified with `toString()`)
///
/// ## Returns
///
/// MD5 hash as lowercase hex string (32 characters), or null if input is null
///
/// ## Examples
///
/// ```dart
/// md5Hash('password');  // '5f4dcc3b5aa765d61d8327deb882cf99'
/// md5Hash('test');  // '098f6bcd4621d373cade4e832627b4f6'
/// md5Hash('');  // 'd41d8cd98f00b204e9800998ecf8427e'
/// md5Hash(null);  // null
/// ```
///
/// ## Security Note
///
/// MD5 is not cryptographically secure and should not be used for security
/// purposes. It's suitable for checksums and non-security applications.
String? md5Hash(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  final bytes = utf8.encode(str);
  final digest = md5.convert(bytes);
  return digest.toString();
}
