import 'dart:convert';
import 'dart:math';

import 'package:html/dom.dart';
import 'package:logging/logging.dart';

import 'src/page_data.dart';
import 'src/selector.dart';

export 'src/page_data.dart';

final _log = Logger('QueryString');

extension SplitKeepSeparator on String {
  List<String> splitKeep(Pattern pattern) {
    if (isEmpty) return [];

    final result = <String>[];
    var start = 0;

    for (var match in pattern.allMatches(this)) {
      if (start != match.start) {
        result.add(substring(start, match.start));
      }
      result.add(substring(match.start, match.end));
      start = match.end;
    }

    if (start < length) {
      result.add(substring(start));
    }

    return result;
  }
}

//result of query, the result is list, it will not be confused with the list of result
class QueryResult {
  final List data;

  QueryResult(input)
      : data = input is List
            ? input
            : input == null
                ? []
                : [input];

  QueryResult combine(QueryResult other) {
    return QueryResult([...data, ...other.data]);
  }

  @override
  String toString() => "QueryResult($data)";
}

/// Query string syntax for extracting data from HTML and JSON.
///
/// Basic usage:
/// ```dart
/// final query = QueryString(queryString);
/// final result = query.execute(pageNode);
/// ```
/// Querys can be combined with `||` and `++`: `query1||query2` or `query1++query2`
///
/// Query string format: `scheme:path?parameters`
///
/// Schemes:
/// - `json:` - Query JSON data (e.g., 'json:meta/title')
/// - `html:` - Query HTML elements (e.g., 'html:div/p')
/// - No scheme defaults to HTML (e.g., 'div/p' = 'html:div/p')
///
/// HTML path syntax: `selector/navigation/selector/@attribute`
/// Selector prefixes:
/// - `*selector` - Force querySelectorAll (e.g., '*p' gets all paragraphs)
/// - `selector` - Force querySelector (e.g., 'p' gets first paragraph)
/// - No prefix uses operation parameter or defaults to querySelector
///
/// Navigation operators:
/// - `^` - Parent element
/// - `^^` - Root element
/// - `>` - First child
/// - `+` - Next sibling
/// - `*+` - Next siblings
/// - `-` - Previous sibling
/// - `*-` - Previous siblings
///
/// Attribute accessors: (only support | connection)
/// - `@` - Text content (default)
/// - `@text` - Text content
/// - `@html` - Inner HTML
/// - `@innerHtml` - Inner HTML
/// - `@outerHtml` - Outer HTML
/// - `@attr` - Custom attribute (e.g., @href, @src)
/// - `@.class` - Check class existence (returns 'true'/null)
/// - `@.prefix*` - Match class with prefix
/// - `@.*suffix` - Match class with suffix
/// - `@.*part*` - Match class containing part
/// - `@.class1|.class2` - Check if class1 or class2 exists
/// - `@src|data-src` - src or data-src
///
/// JSON path syntax:
/// - Simple path: `json:meta/title`
/// - Array index: `json:array/0`
/// - All items: `json:array/*`
/// - Range: `json:array/1-3`
/// - Multiple paths: `json:meta/title,tags/*`
///
/// Query parameters:
/// - `?transform=op1;op2;op3` - Multiple transforms separated by semicolons
///
/// Available transforms:
/// - `upper` - Uppercase
/// - `lower` - Lowercase
/// - `regexp:/pattern/` - Return matched text or null
/// - `regexp:/pattern/replacement/` - Replace matches with replacement
///
/// Available filters:
/// - `filter=word` - Must contain "word"
/// - `filter=!word` - Must NOT contain "word"
/// - `filter=a b` - Must contain "a" AND "b"
/// - `filter=a\ b` - Must contain "a b" (escaped space)
///
/// RegExp variables:
/// - `${pageUrl}` - Current page URL
/// - `${rootUrl}` - Page origin (scheme + authority)
/// - `$1, $2, etc` - Capture groups
///
/// Multiple queries can be combined with `||`:
/// ```dart
/// // Chain with fallback
/// 'json:meta/title||.fallback-title'
///
/// // Chain with required parts
/// 'json:meta/title++content/body'
///
/// // Mixed schemes with transforms
/// 'json:meta/title?transform=upper||div/p?transform=lower'
/// ```
///
/// Examples:
/// ```dart
/// // HTML query with class check
/// '.article/@.featured'  // Check if class exists
/// '.item/@.prefix*'      // Check class prefix
///
/// // JSON with multiple paths
/// 'json:meta/title,tags/*'
///
/// // HTML with transform
/// 'img/@src?transform=regexp:/^\/(.+)/${rootUrl}$1/'
///
/// // Multiple transform
/// '*p/@text?&transform=upper;lowercase'
///
/// // Force all matches
/// '*p/@text'               // All paragraphs
/// '.content/*div/p/@text'  // All paragraphs in all divs
///
/// // Force single match
/// 'p/@text'              // First paragraph only
/// '.content/p/@text'     // First paragraph in content
/// ```
class QueryString extends DataPicker {
  final List<_QueryPart> _queries;
  final bool newProtocol;
  final String? query;

  QueryString(this.query, {this.newProtocol = true})
      : _queries = (query ?? "")
            .splitKeep(RegExp(r'(\|\||\+\+)'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .fold((true, <_QueryPart>[]), (result, v) {
              final (required, l) = result;
              if (v == '||') {
                return (false, l);
              } else if (v == '++') {
                return (true, l);
              } else {
                l.add(_QueryPart.parse(v, required: required));
                return (required, l);
              }
            })
            .$2
            .toList();

  dynamic execute(PageNode node, {bool simplify = true}) {
    if (newProtocol) {
      return _executeQueries(node, simplify);
    } else {
      final selectors = Selectors(query);
      return !simplify
          ? selectors.getCollection(node)
          : selectors.getValue(node);
    }
  }

  dynamic _executeQueries(PageNode node, bool simplify) {
    QueryResult result = QueryResult([]);

    for (var i = 0; i < _queries.length; i++) {
      var query = _queries[i];
      // Skip if previous query succeeded and this isn't required
      if (result.data.isNotEmpty && !query.isRequired()) {
        continue;
      }
      var result_ = _executeSingleQuery(query, node);
      //_log.fine("result_: $result_");
      result = result.combine(result_);
      //_log.fine("result: $result");
    }

    //_log.fine("execute queries result: $result");
    return !simplify
        ? result.data.map((e) => e is Element
            ? PageNode(node.pageData, element: e)
            : PageNode(node.pageData, jsonData: e))
        : result.data.isEmpty
            ? null
            : result.data.length == 1
                ? result.data.first
                : result.data;
  }

  // String _decodePath(Uri uri) {
  //   // Decode full path to handle escaped characters
  //   return Uri.decodeFull(uri.path);
  // }

  QueryResult _executeSingleQuery(_QueryPart query, PageNode node) {
    //_log.fine("execute query: $query");
    if (!['json', 'html'].contains(query.scheme)) {
      throw FormatException('Unsupported scheme: ${query.scheme}');
    }

    QueryResult result = QueryResult([]);
    if (query.path.isNotEmpty) {
      //final decodedPath = _decodePath(Uri.parse(query.path));
      result = query.scheme == 'json'
          ? _applyJsonPathFor(node.jsonData, query.path)
          : _applyHtmlPathFor(node.element, query);
    } else {
      result = QueryResult(node);
    }
    //_log.fine("execute query result before transform: $result");
    result = QueryResult(result.data
        .map((e) => _applyAllTransforms(node, e, query.transforms))
        .where(
            (e) => e != null && e != 'null' && e.toString().trim().isNotEmpty)
        .toList());
    return result;
  }

  QueryResult _applyJsonPathFor(dynamic data, String path) {
    final pathParts = path.split('/').where((p) => p.isNotEmpty);

    return _walkJsonPath(data, pathParts);
  }

  QueryResult _walkJsonPath(dynamic data, Iterable<String> pathParts) {
    if (pathParts.isEmpty) return QueryResult([]);
    return _resolveJsonMultiPath(data, pathParts.first, pathParts.skip(1));
  }

  QueryResult _resolveJsonMultiPath(
      dynamic data, String path, Iterable<String> rest) {
    final paths =
        path.splitKeep(RegExp(r'(\||,)')).map((p) => p.trim()).toList();
    //_log.fine("json paths: $paths");
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
      //final cleanPath = isRequired ? p.substring(0, p.length - 1) : p;
      if (result.data.isNotEmpty && !isRequired) {
        continue;
      }

      final result_ = _resolveJsonPath(data, p);

      result = result.combine(
          rest.isEmpty ? QueryResult(result_) : _walkJsonPath(result_, rest));
    }

    //_log.fine("resultList: $resultList");
    return result;
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
          return data.map((e) => e?[path]).where((t) => t != null).toList();
        }
      }
    } else if (data is Map) {
      return data[path];
    }
    return null;
  }

  QueryResult _applyHtmlPathFor(Element? element, _QueryPart query) {
    if (element == null) return QueryResult([]);

    final parts = query.path
        .split(RegExp(r'(/|(?=@))'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return QueryResult([element]);

    final lastPart = parts.last;

    // Handle attribute or HTML content query in last part
    var elements = _navigateElement(element, parts, query);
    return lastPart.startsWith('@')
        ? QueryResult(_extractHtmlValue(elements, lastPart))
        : QueryResult(elements);
  }

  List<Element> _querySelectorWithPrefix(Element element, String selector) {
    if (selector.startsWith('*')) {
      return element.querySelectorAll(selector.substring(1)).toList();
    }
    final result = element.querySelector(selector);
    return result != null ? [result] : [];
  }

  List<Element> _navigateElement(
      Element element, List<String> parts, _QueryPart query) {
    var currentElements = [element];

    for (var part in parts) {
      if (currentElements.isEmpty) return [];
      currentElements = currentElements
          .expand((elem) => _applySingleNavigation(elem, part))
          .toList();
    }

    return currentElements;
  }

  List<Element> _applySingleNavigation(Element element, String part) {
    if (part.isEmpty || part.startsWith("@")) return [element];

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
        return element.children.isEmpty ? [] : [element.children.first];
      case '+':
        return element.nextElementSibling != null
            ? [element.nextElementSibling!]
            : [];
      case '*+':
        var results = <Element>[];
        var next = element.nextElementSibling;
        while (next != null) {
          results.add(next);
          next = next.nextElementSibling;
        }
        return results;
      case '-':
        return element.previousElementSibling != null
            ? [element.previousElementSibling!]
            : [];
      case '*-':
        var results = <Element>[];
        var prev = element.previousElementSibling;
        while (prev != null) {
          results.add(prev);
          prev = prev.previousElementSibling;
        }
        return results;
      default:
        return _querySelectorWithPrefix(element, part);
    }
  }

  List _extractHtmlValue(List<Element> elements, String accessor) {
    return elements.map((e) => _extractAttributeValue(e, accessor)).toList();
  }

  String? _extractAttributeValue(Element element, String accessor) {
    accessor = accessor.substring(1);
    final attributes = accessor.split(RegExp(r'(\|)'));
    return attributes
        .map((attribute) => _extractSingleAttributeValue(element, attribute))
        .where((e) => e?.isNotEmpty ?? false)
        .firstOrNull;
  }

  String? _extractSingleAttributeValue(Element element, String attribute) {
    if (attribute.startsWith('.')) {
      final className = attribute.substring(1);
      if (className.contains('*')) {
        final pattern = '^${className.replaceAll('*', '.*')}\$';
        final hasClasses =
            element.classes.any((e) => RegExp(pattern).hasMatch(e));
        return hasClasses ? "true" : null;
      }
      return element.classes.contains(className) ? 'true' : null;
    }
    switch (attribute) {
      case '':
        return element.text.trim();
      case 'text':
        return element.text.trim();
      case 'html':
        return element.innerHtml;
      case 'innerHtml':
        return element.innerHtml;
      case 'outerHtml':
        return element.outerHtml;
      default:
        // Handle normal attributes (@href, @src, etc)
        return element.attributes[attribute];
    }
  }

  dynamic _applyAllTransforms(
      PageNode node, dynamic value, Map<String, List<String>> transforms) {
    if (value == null) return null;

    return transforms.entries.fold(value, (result, entry) {
      switch (entry.key) {
        case 'transform':
          return entry.value.fold(result,
              (v, transform) => _applyTransformValues(node, v, transform));
        case 'update':
          return entry.value
              .fold(result, (v, update) => _applyUpdate(v, update));
        case 'filter':
          return entry.value
              .fold(result, (v, filter) => _applyFilter(v, filter));
        default:
          return result;
      }
    });
  }

  dynamic _applyTransformValues(
      PageNode node, dynamic value, String transform) {
    return (value is List)
        ? value.map((v) => _applyTransform(node, v, transform))
        : _applyTransform(node, value, transform);
  }

  dynamic _applyTransform(PageNode node, dynamic value, String transform) {
    // _log.fine("apply transform: $transform value $value");
    if (value == null) return null;

    if (transform.startsWith('regexp:')) {
      return _applyRegexpTransform(node, value, transform.substring(7));
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

  dynamic _applyFilter(dynamic value, String filter) {
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

  dynamic _applyRegexpTransform(PageNode node, dynamic value, String pattern) {
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
    final regexPattern =
        parts[0]; //Uri.decodeFull(parts[0].replaceAll(r'\/', '/'));
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
      final replacement = _prepareReplacement(
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

  String _prepareReplacement(PageNode node, String replacement) {
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

  @override
  Iterable<PageNode> getCollection(PageNode node) {
    final result = execute(node, simplify: false);
    // _log.fine(
    //     "getCollection result: $result ${result.runtimeType} ${result.length}");
    return List<PageNode>.from(result);
  }

  @override
  Iterable getCollectionValue(PageNode node) {
    return getCollection(node).map((e) => e.element ?? e.jsonData);
  }

  @override
  String getValue(PageNode node, {String separator = '\n'}) {
    final result = execute(node);
    return result is List ? result.join(separator) : (result ?? "").toString();
  }
}

class _QueryPart {
  final String scheme;
  final String path;
  final bool required;
  final Map<String, List<String>> parameters;
  final Map<String, List<String>> transforms;

  _QueryPart(
      this.scheme, this.path, this.parameters, this.transforms, this.required);

  static String _encodeSelectorPart(String part) {
    // Encode # in selectors but preserve in query params
    if (part.contains('?')) {
      final index = part.indexOf('?');
      final firstPart = part.substring(0, index);
      final secondPart = part.substring(index + 1);
      return '${firstPart.replaceAll('#', '%23')}?$secondPart';
    }
    return part.replaceAll('#', '%23');
  }

  static List<String> _splitTransforms(String value) {
    final rawParts = value.split(RegExp('(?<!\\\\);'));
    final result = <String>[];
    String? pending;

    for (var part in rawParts) {
      if (pending != null) {
        pending = '$pending;$part';
      } else {
        if (part.trim().startsWith('regexp:')) {
          pending = part;
        } else {
          result.add(part);
          continue;
        }
      }

      if (_isCompleteRegexp(pending)) {
        result.add(pending);
        pending = null;
      }
    }

    if (pending != null) {
      result.add(pending);
    }

    return result;
  }

  static bool _isCompleteRegexp(String value) {
    if (!value.startsWith('regexp:')) return true;

    // Find first slash
    final firstSlash = value.indexOf('/');
    if (firstSlash == -1) return false;

    // Find second slash (end of pattern)
    final secondSlash = _findNextSlash(value, firstSlash + 1);
    if (secondSlash == -1) return false;

    // If string ends here, it's valid (pattern only)
    if (secondSlash == value.length - 1) return true;

    // Find third slash (end of replacement)
    final thirdSlash = _findNextSlash(value, secondSlash + 1);
    if (thirdSlash == -1) return false;

    // If string ends here, it's valid (replacement)
    if (thirdSlash == value.length - 1) return true;

    // If there is more content, it might be invalid or we might have split too early?
    // Actually if we have 3 slashes and more content, it's likely garbage or we split inside a replacement that has slashes?
    // But replacement slashes should be escaped if they are delimiters.
    // Wait, if user writes `regexp:/a/b/c`, `b` is replacement.
    // If user writes `regexp:/a/b;c/`, we split at `;`.
    // `regexp:/a/b` -> 2 slashes. Ends with `b`. Not complete.
    // Join `c/` -> `regexp:/a/b;c/` -> 3 slashes. Ends with `/`. Complete.

    return false;
  }

  static int _findNextSlash(String value, int start) {
    for (var i = start; i < value.length; i++) {
      if (value[i] == '/' && (i == 0 || value[i - 1] != '\\')) {
        return i;
      }
    }
    return -1;
  }

  static _QueryPart parse(String queryString, {required bool required}) {
    var scheme = 'html';
    if (queryString.startsWith('json:')) {
      scheme = 'json';
      queryString = queryString.substring(5);
    } else if (queryString.startsWith('html:')) {
      queryString = queryString.substring(5);
    }

    // Pre-encode selectors
    queryString = _encodeSelectorPart(queryString);

    // Pre-encode transform values
    final transformRegex =
        RegExp(r'transform=((?:(?!&(?:filter|update|transform)=).)*)');
    queryString = queryString.replaceAllMapped(transformRegex, (match) {
      return 'transform=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode filter values
    final filterRegex =
        RegExp(r'filter=((?:(?!&(?:filter|update|transform)=).)*)');
    queryString = queryString.replaceAllMapped(filterRegex, (match) {
      return 'filter=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode update values
    final updateRegex =
        RegExp(r'update=((?:(?!&(?:filter|update|transform)=).)*)');
    queryString = queryString.replaceAllMapped(updateRegex, (match) {
      return 'update=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Add dummy host if needed
    if (!queryString.contains('://')) {
      queryString = '$scheme://dummy/$queryString';
    }

    final uri = Uri.parse(queryString);
    final path = Uri.decodeFull(uri.path.replaceFirst('/dummy/', ''));

    final params = <String, List<String>>{};
    uri.queryParameters.forEach((key, value) {
      if (key == 'transform') {
        params[key] = _splitTransforms(value);
      } else {
        params[key] = value.split(RegExp('(?<!\\\\);'));
      }
    });

    final transforms = <String, List<String>>{};
    if (params.containsKey('transform')) {
      transforms['transform'] = params['transform']!;
      params.remove('transform');
    }
    if (params.containsKey('update')) {
      transforms['update'] = params['update']!;
      params.remove('update');
    }
    if (params.containsKey('filter')) {
      transforms['filter'] = params['filter']!;
      params.remove('filter');
    }

    //_log.fine("transform: $transforms");
    return _QueryPart(scheme, path, params, transforms, required);
  }

  bool isRequired() {
    return required;
  }

  @override
  String toString() {
    return "_QueryPart(scheme: $scheme, path: $path, parameters: $parameters, transforms: $transforms, required: $required)";
  }
}
