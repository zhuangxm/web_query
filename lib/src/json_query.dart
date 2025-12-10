import 'package:web_query/src/utils.dart/core.dart';

import 'query_result.dart';

QueryResult applyJsonPathFor(dynamic data, String path) {
  final pathParts = path.split('/').where((p) => p.isNotEmpty);

  return walkJsonPath(data, pathParts);
}

QueryResult walkJsonPath(dynamic data, Iterable<String> pathParts) {
  if (pathParts.isEmpty) return QueryResult(data);
  return resolveJsonMultiPath(data, pathParts.first, pathParts.skip(1));
}

QueryResult resolveJsonMultiPath(
    dynamic data, String path, Iterable<String> rest) {
  // Expand wildcards first
  final expandedPath = _expandWildcards(data, path);

  final paths =
      expandedPath.splitKeep(RegExp(r'(\||,)')).map((p) => p.trim()).toList();
  var result = QueryResult([]);
  var isRequired = true;
  for (var p in paths) {
    if (p == '|' || p == '&' || p == ',') {
      isRequired = p != '|';
      continue;
    }

    //for compatible with old protocol
    if (p.endsWith("!")) {
      p = p.substring(0, p.length - 1);
      isRequired = true;
    }
    if (result.data.isNotEmpty && !isRequired) {
      continue;
    }

    final result_ = resolveJsonPath(data, p);

    result = result.combine(
        rest.isEmpty ? QueryResult(result_) : walkJsonPath(result_, rest));
  }

  return result;
}

/// Expands wildcards in a path to comma-separated actual keys
/// e.g., "list*" becomes "list1,list2" if those keys exist
String _expandWildcards(dynamic data, String path) {
  if (data is! Map) return path;

  // Split by operators but keep them
  final parts =
      path.splitKeep(RegExp(r'(\||,|&)')).map((p) => p.trim()).toList();
  final expanded = <String>[];

  for (var part in parts) {
    // Keep operators as-is
    if (part == '|' || part == '&' || part == ',') {
      expanded.add(part);
      continue;
    }

    // Check if this part contains wildcards
    if (part.contains('*') || part.contains('?')) {
      final regexPattern = part
          .replaceAll('*', '.*')
          .replaceAll(r"\?", "?")
          .replaceAll(r'?', '.')
          .replaceAll(r"\$", r"$");
      final regex = RegExp('^$regexPattern\$');

      final matchedKeys = <String>[];
      for (var key in data.keys) {
        if (regex.hasMatch(key.toString())) {
          matchedKeys.add(key.toString());
        }
      }

      if (matchedKeys.isNotEmpty) {
        // Sort for consistent ordering
        matchedKeys.sort();
        expanded.add(matchedKeys.join(','));
      } else {
        // No matches, keep original pattern
        expanded.add(part);
      }
    } else {
      // Not a wildcard, keep as-is
      expanded.add(part);
    }
  }

  return expanded.join('');
}

dynamic resolveJsonPath(dynamic data, String path) {
  if (path == '*') return data;

  // Check for deep search
  if (path.startsWith('..')) {
    final keyPattern = path.substring(2);
    return _deepSearch(data, keyPattern);
  }

  if (data is List) {
    if (path.contains('-')) {
      return subList(data, path);
    } else {
      final index = int.tryParse(path);
      if (index != null) {
        if (index < 0 || index >= data.length) return null;
        return data[index];
      } else {
        return data.map((e) => e?[path]).where((t) => t != null).toList();
      }
    }
  } else if (data is Map) {
    if (path == '@keys') {
      return data.keys.toList();
    }

    return data[path];
  }
  return null;
}

List<dynamic> _deepSearch(dynamic data, String keyPattern) {
  final results = [];

  // Prepare regex for key matching (handling wildcards)
  final regexPattern = keyPattern
      .replaceAll('*', '.*')
      .replaceAll(r"\?", "?")
      .replaceAll(r'?', '.')
      .replaceAll(r"\$", r"$");
  final regex = RegExp('^$regexPattern\$');

  void search(dynamic current) {
    if (current is Map) {
      for (var key in current.keys) {
        // Check if key matches
        if (regex.hasMatch(key.toString())) {
          final value = current[key];
          if (value is List) {
            results.addAll(value);
          } else {
            results.add(value);
          }
        }

        // Recursively search values
        search(current[key]);
      }
    } else if (current is List) {
      for (var item in current) {
        search(item);
      }
    }
  }

  search(data);
  return results;
}
