import 'dart:convert';

import 'package:logging/logging.dart';

final _log = Logger("utils");

dynamic tryParseJson(String text, {bool throwException = false}) {
  if (text.isEmpty) return null;
  // Try to parse as JSON
  try {
    return jsonDecode(text);
  } catch (e) {
    try {
      //auto decode json that is embedded in a string.
      return jsonDecode(jsonDecode('"$text"'));
    } catch (e) {
      if (throwException) rethrow;
      _log.warning('Failed to parse JSON text $text error: $e');
      return null;
    }
  }
}
