import 'dart:convert';
import 'dart:math';

import 'package:html/dom.dart';
import 'package:logging/logging.dart';
import 'package:web_query/web_query.dart';

/// Query string syntax for extracting data from HTML and JSON.
///
/// Basic usage:
/// ```dart
/// final query = QueryString(queryString);
/// final result = query.execute(pageNode);
/// ```
///
/// Query string format: `scheme://path?parameters`
///
/// Schemes:
/// - `json://` - Query JSON data
/// - `html://` - Query HTML elements
///
/// HTML path syntax: `html://selector/navigation/selector/@attribute`
///
/// Navigation operators:
/// - `^` - Parent element
/// - `^^` - Root element
/// - `>` - First child
/// - `+` - Next sibling
/// - `-` - Previous sibling
///
/// Attribute accessors:
/// - `@text` - Text content (default)
/// - `@html` - Inner HTML
/// - `@outerHtml` - Outer HTML
/// - `@attr` - Custom attribute (e.g., @href, @src)
///
/// JSON path syntax: `json://path/to/key/*` or `json://path/to/key/0`
/// Required paths: Add `!` suffix to path to make it required even if previous path succeeded
/// Example: `json://primary/path,required/path!,optional/path`
///
/// Array selectors:
/// - `/0` - First item (or any numeric index)
/// - `/*` - All items
/// - Multiple paths use comma: `path1,path2`
///
/// Query parameters:
/// - `?transform=op1;op2;op3` - Multiple transforms separated by semicolons
/// - `?op=mode` - Operation mode (one/all)
/// - `?required=true` - Makes query required in chain
/// - `?update=jsonString` - Merge JSON data (JSON only)
///
/// Available transforms:
/// - `upper` - Uppercase
/// - `lower` - Lowercase
/// - `regexp:/pattern/` - Return matched text or null
/// - `regexp:/pattern/replacement/` - Replace matches with replacement
///
/// RegExp variables:
/// - `${pageUrl}` - Current page URL
/// - `${rootUrl}` - Page origin (scheme + authority)
/// - `$1, $2, etc` - Capture groups
///
/// Multiple queries can be combined with `||`:
/// ```dart
/// 'json://meta/title||html://.fallback-title'
/// ```
///
/// Examples:
/// ```dart
/// // HTML navigation and attribute
/// 'html://.article/>/h1/@text'
///
/// // JSON with array and multiple paths
/// 'json://users/0/name,email?transform=lower'
///
/// // URL transformation
/// 'html://img/@src?transform=regexp:/^\/(.+)/${rootUrl}$1/'
///
/// // Required chain with fallback
/// 'json://content/body?required=true|html://.content/@html'
///
/// // Multiple transforms
/// 'html://.date?transform=regexp:/(\d{2})\/(\d{2})/$2-$1/;transform=upper'
/// ```

final _log = Logger('QueryString');

//result of query, if the result is list, it will not be confused with the list of result
class QueryResult<T> {
  final T data;

  QueryResult(this.data);

  combine(QueryResult other) {
    if (other.data == null) return this;
    if (data == null) return other;
    final otherList = (other.data is List) ? other.data : [other.data];
    if (data is List) {
      return QueryResult([...(data as List), ...otherList]);
    }
    return QueryResult([data, ...otherList]);
  }

  @override
  String toString() => "QueryResult($data)";
}

class QueryString {
  final List<_QueryPart> _queries;
  late final PageNode _node;

  QueryString(String query)
      : _queries = query.split('||').map((q) => _QueryPart.parse(q)).toList();

  bool get isJson => _queries.first.scheme == 'json';
  bool get isHtml => _queries.first.scheme == 'html';
  String get path => _queries.first.path;
  Map<String, List<String>> get transforms => _queries.first.transforms;

  bool _isRequired(_QueryPart query) {
    // If required parameter exists, use its value, otherwise default to true
    if (query.parameters.containsKey('required')) {
      return query.parameters['required']?.first.toLowerCase() == 'true';
    }
    return true;
  }

  String _getOperation(_QueryPart query) =>
      query.parameters['op']?.first ??
      query.parameters['operation']?.first ??
      'one';

  dynamic execute(PageNode node) {
    _node = node;
    return _executeQueries(node);
  }

  dynamic _executeQueries(PageNode node) {
    var results = <QueryResult<List>>[];

    for (var query in _queries) {
      if (results.isNotEmpty && !_isRequired(query)) {
        continue;
      }
      var result = _executeSingleQuery(query, node);
      // _log.fine("query: $query, result: $result");
      if (result.data.isNotEmpty) {
        results.add(result);
      }
    }

    final result = results.isEmpty
        ? QueryResult([])
        : results.reduce((combined, result) => combined.combine(result));
    return result.data.isEmpty
        ? null
        : result.data.length == 1
            ? result.data.first
            : result.data;
  }

  String _decodePath(Uri uri) {
    // Decode full path to handle escaped characters
    return Uri.decodeFull(uri.path);
  }

  QueryResult<List> _executeSingleQuery(_QueryPart query, PageNode node) {
    if (!['json', 'html'].contains(query.scheme)) {
      throw FormatException('Unsupported scheme: ${query.scheme}');
    }

    QueryResult<List> result;
    if (query.path.isNotEmpty) {
      final decodedPath = _decodePath(Uri.parse(query.path));
      result = query.scheme == 'json'
          ? _applyJsonPathFor(node.jsonData, decodedPath)
          : _applyHtmlPathFor(node.element, decodedPath, query);
    } else {
      result = QueryResult([node]);
    }
    result = QueryResult(result.data
        .map((e) => _applyAllTransforms(e, query.transforms))
        .map((e) => e is Element
            ? PageNode(node.pageData, element: e)
            : e is Map
                ? PageNode(node.pageData, jsonData: e)
                : e)
        .toList());
    return result;
  }

  QueryResult<List> _applyJsonPathFor(dynamic data, String path) {
    final pathParts = path.split('/').where((p) => p.isNotEmpty);

    var result = QueryResult(data);

    for (var p in pathParts) {
      result = _resolveJsonMultiPath(result.data, p);
    }
    return QueryResult(result.data == null ? [] : [result.data]);
  }

  QueryResult _resolveJsonMultiPath(dynamic data, String path) {
    final paths = path.split(',').map((p) => p.trim()).toList();
    final resultList = <QueryResult>[];
    for (var p in paths) {
      final isRequired = p.endsWith('!');
      final cleanPath = isRequired ? p.substring(0, p.length - 1) : p;
      if (resultList.isNotEmpty && !isRequired) {
        continue;
      }

      final result = _resolveJsonPath(data, cleanPath);

      if (result != null) {
        resultList.add(QueryResult(result));
      }
    }

    _log.fine("resultList: $resultList");
    return resultList.isEmpty
        ? QueryResult(null)
        : resultList.reduce((combined, result) => combined.combine(result));
  }

  dynamic _resolveJsonPath(dynamic data, String path) {
    // _log.fine("data: $data");
    // _log.fine(
    //     "_resolveJsonPath data isMap: ${data is Map} isList ${data is List}, path: $path");
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
          return data.map((e) => e[path]).toList();
        }
      }
    } else if (data is Map) {
      return data[path];
    }
    return null;
  }

  QueryResult<List> _applyHtmlPathFor(
      Element? element, String path, _QueryPart query) {
    if (element == null) return QueryResult([]);

    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return QueryResult([element]);

    final lastPart = parts.last;
    final operation = _getOperation(query);

    // Handle attribute or HTML content query in last part
    if (lastPart.startsWith('@') || lastPart.startsWith('.')) {
      parts.removeLast();
      var elements = _navigateElement(element, parts, query);

      // _log.fine(
      //     'elements: $elements, lastPart: $lastPart, operation: $operation');
      return QueryResult(_extractHtmlValue(elements, lastPart, operation));
    }

    if (parts.length > 1) {
      var elements =
          _navigateElement(element, parts.sublist(0, parts.length - 1), query);
      if (elements.isEmpty) return QueryResult([]);

      // For last part, apply operation mode
      if (operation == 'all') {
        return QueryResult(
            elements.expand((e) => e.querySelectorAll(lastPart)).toList());
      } else {
        var result = elements
            .map((e) => e.querySelector(lastPart))
            .where((e) => e != null)
            .toList();
        return QueryResult(result);
      }
    }

    // Single part path
    if (operation == 'all') {
      return QueryResult(element.querySelectorAll(lastPart));
    } else {
      return QueryResult([element.querySelector(lastPart)]);
    }
  }

  List<Element> _navigateElement(
      Element element, List<String> parts, _QueryPart query) {
    var currentElements = [element];

    for (var part in parts) {
      if (currentElements.isEmpty) return [];

      currentElements = currentElements.expand((elem) {
        return _applySingleNavigation(elem, part, query);
      }).toList();
    }

    return currentElements;
  }

  List<Element> _applySingleNavigation(
      Element element, String part, _QueryPart query) {
    final operation = _getOperation(query);
    // _log.fine(
    //     'Navigating from ${element.localName} to: $part (op: $operation)');

    if (part.isEmpty) return [element];

    switch (part) {
      case '^^':
        var root = element;
        while (root.parent != null) {
          root = root.parent!;
        }
        return [root];
      case '^':
        return element.parent != null ? [element.parent!] : [];
      case '>':
        return operation == 'all'
            ? element.children.toList()
            : element.children.isEmpty
                ? []
                : [element.children.first];
      case '+':
        return element.nextElementSibling != null
            ? [element.nextElementSibling!]
            : [];
      case '-':
        return element.previousElementSibling != null
            ? [element.previousElementSibling!]
            : [];
      default:
        return operation == 'all'
            ? element.querySelectorAll(part).toList()
            : element.querySelector(part) != null
                ? [element.querySelector(part)!]
                : [];
    }
  }

  List _extractHtmlValue(
      List<Element> elements, String accessor, String operation) {
    if (elements.isEmpty) return [];

    if (operation == 'all') {
      return elements.map((e) => _extractSingleValue(e, accessor)).toList();
    }
    return [_extractSingleValue(elements.first, accessor)];
  }

  String? _extractSingleValue(Element element, String accessor) {
    switch (accessor) {
      case '@text':
        return element.text;
      case '@html':
        return element.innerHtml;
      case '@outerHtml':
        return element.outerHtml;
      default:
        // Handle normal attributes (@href, @src, etc)
        return element.attributes[accessor.substring(1)];
    }
  }

  dynamic _applyAllTransforms(
      dynamic value, Map<String, List<String>> transforms) {
    if (value == null) return null;

    return transforms.entries.fold(value, (result, entry) {
      switch (entry.key) {
        case 'transform':
          return entry.value.fold(
              result, (v, transform) => _applyTransformValues(v, transform));
        case 'update':
          return entry.value
              .fold(result, (v, update) => _applyUpdate(v, update));
        default:
          return result;
      }
    });
  }

  dynamic _applyTransformValues(dynamic value, String transform) {
    return (value is List)
        ? value.map((v) => _applyTransform(v, transform))
        : _applyTransform(value, transform);
  }

  dynamic _applyTransform(dynamic value, String transform) {
    // _log.fine("apply transform: $transform value $value");
    if (value == null) return null;

    if (transform.startsWith('regexp:')) {
      return _applyRegexpTransform(
          value, Uri.decodeFull(transform.substring(7)));
    }

    switch (transform) {
      case 'upper':
        return value.toString().toUpperCase();
      case 'lower':
        return value.toString().toLowerCase();
      default:
        return value;
    }
  }

  dynamic _applyUpdate(dynamic value, String updates) {
    // _log.fine("apply update: $updates value $value");
    if (value is! Map) return value;

    try {
      final updateMap = json.decode(updates);
      return {...value, ...updateMap};
    } catch (e) {
      _log.warning('Failed to apply update: $e');
      return value;
    }
  }

  dynamic _applyRegexpTransform(dynamic value, String pattern) {
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
    // _log.fine("apply regexp transform: $pattern $parts value $value");

    // Decode special characters in pattern
    final regexPattern = Uri.decodeFull(parts[0].replaceAll(r'\/', '/'));
    // _log.fine("decoded pattern: $regexPattern");

    try {
      final regexp = RegExp(regexPattern);
      final valueStr = value.toString();

      // Pattern-only mode (empty replacement part)
      if (parts[1].isEmpty) {
        final match = regexp.firstMatch(valueStr);
        return match?.group(0);
      }

      // Replace mode
      final replacement = _prepareReplacement(parts[1].replaceAll(r'\/', '/'));
      return valueStr.replaceAllMapped(regexp, (Match match) {
        var result = replacement;
        for (var i = 1; i <= match.groupCount; i++) {
          result = result.replaceAll('\$$i', match.group(i) ?? '');
        }
        return result.replaceAll(r'$0', match.group(0) ?? '');
      });
    } catch (e) {
      _log.warning('Failed to apply regexp: $e');
      return value;
    }
  }

  String _prepareReplacement(String replacement) {
    var result = replacement;

    try {
      final pageUri = Uri.parse(_node.pageData.url);
      // Replace pageUrl with full URL
      result = result.replaceAll(r'${pageUrl}', _node.pageData.url);
      // Replace rootUrl with origin (scheme + authority)
      result = result.replaceAll(r'${rootUrl}', pageUri.origin);
    } catch (e) {
      // If URL parsing fails, leave replacement unchanged
    }

    return result;
  }

  String get text => execute(_node)?.toString() ?? '';
}

class _QueryPart {
  final String scheme;
  final String path;
  final Map<String, List<String>> parameters;
  final Map<String, List<String>> transforms;

  _QueryPart(this.scheme, this.path, this.parameters, this.transforms);

  static String _encodeQueryComponent(String value) {
    // Preserve + by encoding it first
    return Uri.encodeQueryComponent(value).replaceAll('+', '%2B');
  }

  static _QueryPart parse(String queryString) {
    // Pre-encode transform values to preserve special characters
    final transformRegex = RegExp(r'transform=([^&]+)');
    queryString = queryString.replaceAllMapped(transformRegex, (match) {
      return 'transform=${_encodeQueryComponent(match.group(1)!)}';
    });

    // Add dummy host to make URI parsing work
    var normalizedQuery = queryString.replaceFirst('://', '://dummy/');
    final uri = Uri.parse(normalizedQuery);

    // Remove dummy host from path
    final path = uri.path.startsWith('/dummy/')
        ? uri.path.substring(6)
        : uri.path.substring(1);

    final params = Map<String, List<String>>.from(uri.queryParameters.map(
      (key, value) => MapEntry(key, value.split(';')),
    ));

    final transforms = <String, List<String>>{};
    if (params.containsKey('transform')) {
      transforms['transform'] = params['transform']!;
      params.remove('transform');
    }
    if (params.containsKey('update')) {
      transforms['update'] = params['update']!;
      params.remove('update');
    }

    return _QueryPart(uri.scheme, path, params, transforms);
  }

  @override
  String toString() {
    return 'QueryPart: {scheme: $scheme, path: $path, parameters: $parameters}';
  }
}
