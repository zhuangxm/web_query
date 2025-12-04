import 'dart:math';

import 'query_result.dart';

QueryResult applyJsonPathFor(dynamic data, String path) {
  final pathParts = path.split('/').where((p) => p.isNotEmpty);

  return walkJsonPath(data, pathParts);
}

QueryResult walkJsonPath(dynamic data, Iterable<String> pathParts) {
  if (pathParts.isEmpty) return QueryResult([]);
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
  if (data is List) {
    if (path.contains('-')) {
      final parts = path.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0]) ?? 0;
        final end = int.tryParse(parts[1]) ?? data.length;
        return data.sublist(start, min(end + 1, data.length));
      }
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
