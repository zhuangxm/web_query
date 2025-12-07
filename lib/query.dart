import 'dart:convert';

import 'package:html/dom.dart';
import 'package:logging/logging.dart';
import 'package:web_query/src/query_part.dart';
import 'package:web_query/src/transforms.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/javascript.dart';

import 'src/html_query.dart';
import 'src/json_query.dart';
import 'src/page_data.dart';
import 'src/query_result.dart';
import 'src/url_query.dart';

export 'src/page_data.dart';
export 'src/transforms.dart';

abstract class DataPicker {
  Iterable<PageNode> getCollection(PageNode node,
      {Map<String, dynamic>? initialVariables});
  Iterable getCollectionValue(PageNode node,
      {Map<String, dynamic>? initialVariables});
  String getValue(PageNode node,
      {String separator = "\n", Map<String, dynamic>? initialVariables});
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
/// - `?save=varName` - Save result to variable (auto-discards from output)
/// - `?save=varName&keep` - Save result to variable and keep in output
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
/// Variables and Templates:
/// - `?save=varName` - Save result to variable (automatically omitted from output)
/// - `?save=varName&keep` - Save result and keep in output
/// - `template:${varName}` - Use saved variables in template
/// - Variables can be used in paths: `json:items/${id}`
/// - Variables can be used in regex: `regexp:/${pattern}/replacement/`
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
/// // Variables and templates (save auto-discards)
/// 'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
/// // Result: "Alice Smith" (intermediate values omitted)
///
/// // Keep intermediate values
/// 'json:firstName?save=fn&keep ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
/// // Result: ["Alice", "Smith", "Alice Smith"]
///
/// // Force all matches
/// '*p/@text'               // All paragraphs
/// '.content/*div/p/@text'  // All paragraphs in all divs
///
/// // Force single match
/// 'p/@text'              // First paragraph only
/// '.content/p/@text'     // First paragraph in content
/// ```

// ignore: unused_element
final _log = Logger('QueryString');

class QueryString extends DataPicker {
  final List<QueryPart> _queries;
  final String? query;

  /// Public getter to access the parsed query parts
  List<QueryPart> get queries => _queries;

  QueryString(this.query)
      : _queries = (query ?? "")
            .splitKeep(RegExp(r'(\|\||\+\+|>>>|>>(?!=))'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .fold((true, false, <QueryPart>[]), (result, v) {
              final (required, isPipe, l) = result;
              if (v == '||') {
                return (false, false, l);
              } else if (v == '++') {
                return (true, false, l);
              } else if (v == '>>') {
                return (true, true, l);
              } else {
                l.add(QueryPart.parse(v, required: required, isPipe: isPipe));
                return (required, false, l);
              }
            })
            .$3
            .toList();

  dynamic _execute(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    final queries = (query ?? "").split('>>>');

    // if (queries.length == 1) {
    //   return _executeQueries(currentNode,
    //           simplify: simplify, initialVariables: variables)
    //       .result;
    // }

    PageNode currentNode = node;

    var variables = {...initialVariables ?? {}};
    while (queries.isNotEmpty) {
      final firstQuery = queries.removeAt(0);

      if (queries.isEmpty) {
        return QueryString(firstQuery.trim())._executeQueries(currentNode,
            simplify: simplify, initialVariables: variables);
      } else {
        final firstExecution = QueryString(firstQuery.trim())
            ._executeQueriesWithVariables(currentNode,
                simplify: false, initialVariables: variables);

        // Convert result to list if it isn't already
        final resultList = (firstExecution.result is Iterable)
            ? firstExecution.result.toList()
            : [firstExecution.result];

        variables.addAll(firstExecution.variables);
        // Convert to JSON array - extract text from PageNodes
        final arrayData = resultList.map((item) {
          if (item is PageNode) {
            return item.element?.text ?? item.jsonData;
          }
          return item;
        }).toList();

        final jsonData = jsonEncode(arrayData);

        // Create a new PageData with the JSON array
        final arrayPageData =
            PageData(node.pageData.url, '', jsonData: jsonData);
        currentNode = arrayPageData.getRootElement();
      }
    }
  }

  dynamic execute(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    final pageUrl = node.pageData.url;
    initialVariables = {
      ...initialVariables ?? {},
      "time": DateTime.now().millisecondsSinceEpoch,
      "pageUrl": pageUrl,
      "rootUrl": Uri.parse(pageUrl).origin
    };
    // Normal execution
    // Reset JavaScript runtime only if query uses jseval
    if (_usesJseval()) {
      _resetJsRuntime();
    }
    return _execute(node,
        simplify: simplify, initialVariables: initialVariables);
  }

  bool _usesJseval() {
    // Check if any query part uses jseval transform
    for (var query in _queries) {
      if (query.transforms.containsKey('transform')) {
        final transforms = query.transforms['transform']!;
        if (transforms.transformers.any((t) => t is JavascriptTransformer)) {
          return true;
        }
      }
    }
    return false;
  }

  void _resetJsRuntime() {
    // Reset the JavaScript executor if configured
    if (JsExecutorRegistry.isConfigured) {
      JsExecutorRegistry.instance?.reset();
    }
  }

  ResultWithVariables _executeQueriesWithVariables(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    final variables = <String, dynamic>{...?initialVariables};
    QueryResult result = QueryResult([]);

    for (var i = 0; i < _queries.length; i++) {
      var query = _queries[i];
      // Skip if previous query succeeded and this isn't required (and not a pipe)
      if (result.data.isNotEmpty && !query.isRequired() && !query.isPipe) {
        continue;
      }

      QueryResult result_;
      if (query.isPipe && i > 0) {
        // Regular pipe: execute query on each item from previous result
        if (result.data.isEmpty) {
          result_ = QueryResult([]);
        } else {
          // Execute query on each item from previous result
          final pipedData = <dynamic>[];
          for (var item in result.data) {
            final itemNode = item is PageNode
                ? item
                : item is Element
                    ? PageNode(node.pageData, element: item)
                    : (item is String && query.scheme == 'html')
                        ? PageData(node.pageData.url, item).getRootElement()
                        : (item is String && query.scheme == 'json')
                            ? _tryParseJson(node, item)
                            : PageNode(node.pageData, jsonData: item);
            final subResultWithVariables =
                _executeSingleQuery(query, itemNode, variables);
            final subResult = subResultWithVariables.result;
            variables.addAll(subResultWithVariables.variables);
            pipedData.addAll(subResult.data);
          }
          result_ = QueryResult(pipedData);
        }
        // Replace result with piped result
        result = result_;
      } else {
        final resultWithVariables = _executeSingleQuery(query, node, variables);
        result_ = resultWithVariables.result;
        variables.addAll(resultWithVariables.variables);
        result = result.combine(result_);
      }
    }

    //_log.fine("execute queries result: $result, simplify: $simplify");
    final finalResult = !simplify
        ? result.data.map((e) => e is Element
            ? PageNode(node.pageData, element: e)
            : PageNode(node.pageData, jsonData: e))
        : result.data.isEmpty
            ? null
            : result.data.length == 1
                ? result.data.first
                : result.data;

    return ResultWithVariables(result: finalResult, variables: variables);
  }

  dynamic _executeQueries(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    return _executeQueriesWithVariables(node,
            simplify: simplify, initialVariables: initialVariables)
        .result;
  }

  QueryResultWithVariables _executeSingleQuery(
      QueryPart query, PageNode node, Map<String, dynamic> variables) {
    //_log.fine("execute query part: $query, variables: $variables");
    // Resolve variables in path
    final resolver = VariableResolver(variables);

    query.resolve(resolver);

    //_log.fine("execute query: $query");
    if (query.scheme == 'template') {
      return QueryResultWithVariables(
          result: QueryResult([query.path]), variables: {...variables});
    }

    if (!['json', 'html', 'url'].contains(query.scheme)) {
      throw FormatException('Unsupported scheme: ${query.scheme}');
    }

    QueryResult result = QueryResult([]);
    if (query.scheme == 'url') {
      result = applyUrlPathFor(node, query);
    } else if (query.path.isNotEmpty) {
      //final decodedPath = _decodePath(Uri.parse(query.path));
      result = query.scheme == 'json'
          ? applyJsonPathFor(node.jsonData, query.path)
          : applyHtmlPathFor(
              node.element,
              // Create a temporary query part with resolved path for HTML query
              query);
    } else {
      result = QueryResult(node);
    }

    final transformResult =
        _applyAllTransforms(node, result.data, query.transforms, variables);

    variables.addAll(transformResult.variables);
    result = QueryResult(transformResult.result);

    //_log.finer("execute result $transformResult", variables);
    return QueryResultWithVariables(result: result, variables: {...variables});
  }

  @override
  Iterable<PageNode> getCollection(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    final result =
        execute(node, simplify: false, initialVariables: initialVariables);
    // _log.fine(
    //     "getCollection result: $result ${result.runtimeType} ${result.length}");
    return List<PageNode>.from(result);
  }

  @override
  Iterable getCollectionValue(PageNode node,
      {Map<String, dynamic>? initialVariables}) {
    return getCollection(node, initialVariables: initialVariables)
        .map((e) => e.element ?? e.jsonData);
  }

  @override
  String getValue(PageNode node,
      {String separator = '\n', Map<String, dynamic>? initialVariables}) {
    final result = execute(node, initialVariables: initialVariables);
    return result is List ? result.join(separator) : (result ?? "").toString();
  }

  PageNode _tryParseJson(PageNode node, String item) {
    try {
      final json = jsonDecode(item);
      return PageNode(node.pageData, jsonData: json);
    } catch (e) {
      return PageNode(node.pageData, jsonData: item);
    }
  }

  @override
  String toString() {
    if (_queries.isEmpty) return 'QueryString(empty)';

    final buffer = StringBuffer();
    buffer.writeln('QueryString, part count: ${_queries.length}');
    for (var i = 0; i < _queries.length; i++) {
      buffer.writeln('==[Part ${i + 1}]==');
      final partLines = _queries[i].toString().split('\n');
      for (var line in partLines) {
        buffer.writeln(line);
      }
      buffer.writeln();
    }
    return buffer.toString().trim();
  }
}

ResultWithVariables _applyAllTransforms(
    PageNode node,
    dynamic value,
    Map<String, GroupTransformer> transformMaps,
    Map<String, dynamic> variables) {
  if (value == null) return ResultWithVariables(result: null);

  // Apply transforms in the defined order, not map iteration order
  var transformResult = ResultWithVariables(result: value);

  final List<Transformer> transformers = [];
  for (final transformType in transformOrder) {
    if (!transformMaps.containsKey(transformType)) continue;

    transformers.add(transformMaps[transformType]!);
  }
  return Transformer.transformMultiple(transformers, transformResult.result)
      .filterOutInvalid();
}
