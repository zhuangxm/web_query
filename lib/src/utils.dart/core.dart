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
      return text;
    }
  }
}

List<T> subList<T>(List<T> data, String path) {
  final range = path.split('-').map(int.parse).toList();
  return data.skip(range[0]).take(range[1] - range[0] + 1).toList();
}
