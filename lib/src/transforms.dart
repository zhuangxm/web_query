import 'dart:convert' as json;

import 'package:logging/logging.dart';

import 'page_data.dart';
import 'query_result.dart';

final _log = Logger('QueryString.Transforms');

/// Extension for transform, filter, and regexp operations on QueryString
dynamic applyAllTransforms(
    PageNode node, dynamic value, Map<String, List<String>> transforms) {
  if (value == null) return null;

  return transforms.entries.fold(value, (result, entry) {
    switch (entry.key) {
      case 'transform':
        return entry.value.fold(
            result, (v, transform) => applyTransformValues(node, v, transform));
      case 'update':
        return entry.value.fold(result, (v, update) => applyUpdate(v, update));
      case 'filter':
        return entry.value.fold(result, (v, filter) => applyFilter(v, filter));
      default:
        return result;
    }
  });
}

dynamic applyTransformValues(PageNode node, dynamic value, String transform) {
  return (value is List)
      ? value.map((v) => applyTransform(node, v, transform))
      : applyTransform(node, value, transform);
}

dynamic applyTransform(PageNode node, dynamic value, String transform) {
  if (value == null) return null;

  if (transform.startsWith('regexp:')) {
    return applyRegexpTransform(node, value, transform.substring(7));
  }

  if (transform.startsWith('json:')) {
    return applyJsonTransform(value, transform.substring(5));
  }

  switch (transform) {
    case 'upper':
      return value.toString().toUpperCase();
    case 'lower':
      return value.toString().toLowerCase();
    case 'json':
      return applyJsonTransform(value, null);
    default:
      return value;
  }
}

dynamic applyJsonTransform(dynamic value, String? varName) {
  if (value == null) return null;

  var text = value.toString().trim();

  // If varName is provided, extract the JSON from JavaScript variable assignment
  if (varName != null && varName.isNotEmpty) {
    // Match patterns like: var config = {...}; or window.__DATA__ = {...};
    final patterns = [
      RegExp('$varName\\s*=\\s*({[\\s\\S]*?});', multiLine: true),
      RegExp('$varName\\s*=\\s*(\\[[\\s\\S]*?\\]);', multiLine: true),
    ];

    bool found = false;

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        text = match.group(1)!;
        found = true;
        break;
      }
    }

    if (!found) {
      return null;
    }
  }

  // Try to parse as JSON
  try {
    return json.jsonDecode(text);
  } catch (e) {
    _log.warning('Failed to parse JSON: $e');
    return null;
  }
}

dynamic applyUpdate(dynamic value, String updates) {
  if (value is! Map) return value;

  try {
    final updateMap = json.jsonDecode(updates);
    return {...value, ...updateMap};
  } catch (e) {
    _log.warning('Failed to apply update: $e');
    return value;
  }
}

dynamic applyFilter(dynamic value, String filter) {
  if (value == null) return null;

  // Split filter string by space, respecting escaped spaces
  final parts = filter
      .splitKeep(RegExp(r'(?<!\\) '))
      .map((e) => e
          .trim()
          .replaceAll(r'\ ', ' ')
          .replaceAll(r'\;', ';')
          .replaceAll(r'\&', '&'))
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.isEmpty) return value;

  bool check(dynamic v) {
    final str = v.toString();
    for (var part in parts) {
      var isExclude = false;
      if (part.startsWith('!')) {
        isExclude = true;
        part = part.substring(1);
      }

      if (isExclude) {
        if (str.contains(part)) return false;
      } else {
        if (!str.contains(part)) return false;
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

dynamic applyRegexpTransform(PageNode node, dynamic value, String pattern) {
  if (value == null) return null;

  // Decode pattern after splitting to preserve escaped slashes
  final parts =
      pattern.split(RegExp(r'(?<!\\)/')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) {
    _log.warning(
        'Invalid regexp format. Use: /pattern/ or /pattern/replacement/');
    return value;
  } else if (parts.length == 1) {
    parts.add("");
  }

  // Decode special characters in pattern
  var regexPattern = parts[0];

  // Handle \ALL keyword
  if (regexPattern.contains(r'\ALL')) {
    regexPattern = regexPattern.replaceAll(r'\ALL', r'^[\s\S]*$');
  }

  try {
    final regexp = RegExp(regexPattern, multiLine: true);
    final valueStr = value.toString();

    // Pattern-only mode (empty replacement part)
    if (parts[1].isEmpty) {
      final match = regexp.firstMatch(valueStr);
      return match?.group(0);
    }

    // Replace mode
    final replacement = prepareReplacement(
        node, parts[1].replaceAll(r'\/', '/').replaceAll(r'\;', ';'));
    return valueStr.replaceAllMapped(regexp, (Match match) {
      var result = replacement;
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
