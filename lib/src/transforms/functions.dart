import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

final _log = Logger("functions");

/// Generate MD5 hash of a value
/// ## Returns
/// MD5 hash as lowercase hex string (32 characters), or null if input is null
/// ## Examples
/// ```dart
/// md5Hash('password');  // '5f4dcc3b5aa765d61d8327deb882cf99'
/// md5Hash('test');  // '098f6bcd4621d373cade4e832627b4f6'
/// md5Hash('');  // 'd41d8cd98f00b204e9800998ecf8427e'
/// md5Hash(null);  // null
/// ```
String? md5Hash(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  final bytes = utf8.encode(str);
  final digest = md5.convert(bytes);
  return digest.toString();
}

/// Generate sha1 hash of a value
String? sha1Hash(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  final bytes = utf8.encode(str);
  final digest = sha1.convert(bytes);
  return digest.toString();
}

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

/// Encode a value to Base64
/// Converts any value to a string and encodes it to Base64 format.
/// Uses UTF-8 encoding for the input string.
/// ## Returns
/// Base64-encoded string, or null if input is null
/// ## Examples
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
/// Decodes a Base64 string back to its original text using UTF-8 decoding.
/// Decoded string, or null if input is null or invalid Base64
/// ## Examples
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

/// Convert a value to uppercase
/// ## Returns
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
