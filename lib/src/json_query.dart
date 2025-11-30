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
  final paths = path.splitKeep(RegExp(r'(\||,)')).map((p) => p.trim()).toList();
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

dynamic resolveJsonPath(dynamic data, String path) {
  if (path == '*') return data;
  if (path == r'$') return data;
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
