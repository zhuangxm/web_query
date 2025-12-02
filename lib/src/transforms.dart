import 'dart:convert' as json;

import 'package:logging/logging.dart';

import 'page_data.dart';
import 'query_result.dart';

final _log = Logger('QueryString.Transforms');

/// Marker class to indicate a value should be discarded when simplify=true
class DiscardMarker {
  final dynamic value;
  DiscardMarker(this.value);
}

/// Extension for transform, filter, and regexp operations on QueryString
dynamic applyAllTransforms(PageNode node, dynamic value,
    Map<String, List<String>> transforms, Map<String, dynamic> variables) {
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
      case 'index':
        return entry.value
            .fold(result, (v, indexStr) => applyIndex(v, indexStr));
      case 'save':
        // Save BEFORE discard so we save the unwrapped value
        entry.value.fold(result, (v, varName) {
          if (v != null) {
            variables[varName] = v;
          }
          return v;
        });
        return result;
      case 'discard':
        // Mark value for discard by wrapping in a special marker
        return entry.value.isEmpty ? result : DiscardMarker(result);
      default:
        return result;
    }
  });
}

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

  if (transform.startsWith('jseval:')) {
    return applyJsEvalTransform(value, transform.substring(7));
  }

  switch (transform) {
    case 'upper':
      return value.toString().toUpperCase();
    case 'lower':
      return value.toString().toLowerCase();
    case 'json':
      return applyJsonTransform(value, null);
    case 'jseval':
      return applyJsEvalTransform(value, null);
    default:
      return value;
  }
}

dynamic applyJsonTransform(dynamic value, String? varName) {
  if (value == null) return null;

  var text = value.toString().trim();

  // If varName is provided, extract the JSON from JavaScript variable assignment
  if (varName != null && varName.isNotEmpty) {
    // Convert wildcard pattern to regex
    // Escape special regex chars except * which becomes .*
    final escapedName = RegExp.escape(varName).replaceAll(r'\*', '.*');

    // Match patterns like: var config = {...}; or window.__DATA__ = {...};
    final patterns = [
      // Objects
      RegExp('$escapedName\\s*=\\s*({[\\s\\S]*?});', multiLine: true),
      // Arrays
      RegExp('$escapedName\\s*=\\s*(\\[[\\s\\S]*?\\]);', multiLine: true),
      // Numbers (including decimals, negative, scientific notation)
      RegExp('$escapedName\\s*=\\s*(-?\\d+\\.?\\d*(?:[eE][+-]?\\d+)?);',
          multiLine: true),
      // Strings (single or double quotes)
      RegExp('$escapedName\\s*=\\s*(["\'][\\s\\S]*?["\']);', multiLine: true),
      // Booleans
      RegExp('$escapedName\\s*=\\s*(true|false);', multiLine: true),
      // Null
      RegExp('$escapedName\\s*=\\s*(null);', multiLine: true),
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

dynamic applyJsEvalTransform(dynamic value, String? variableNames) {
  if (value == null) return null;

  try {
    // Import js_executor dynamically
    final jsExecutor = _getJsExecutorInstance();
    if (jsExecutor == null) {
      _log.warning(
          'JavaScript executor not configured. Use: import "package:web_query/js.dart"; JsExecutorRegistry.instance = FlutterJsExecutor();');
      return null;
    }

    final script = value.toString().trim();
    if (script.isEmpty) return null;

    // Parse variable names if provided
    List<String>? varList;
    if (variableNames != null && variableNames.isNotEmpty) {
      varList = variableNames.split(',').map((e) => e.trim()).toList();
    }

    // Execute JavaScript synchronously using flutter_js
    // flutter_js evaluate() is synchronous, so this works
    final result = jsExecutor.extractVariablesSync(script, varList);

    return result;
  } catch (e) {
    _log.warning('Failed to execute JavaScript: $e');
    return null;
  }
}

// Global reference to avoid circular dependency
dynamic _jsExecutorInstance;

void setJsExecutorInstance(dynamic instance) {
  _jsExecutorInstance = instance;
}

dynamic _getJsExecutorInstance() {
  return _jsExecutorInstance;
}
