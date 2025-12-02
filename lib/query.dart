import 'dart:convert';

import 'package:function_tree/function_tree.dart';
import 'package:html/dom.dart';
import 'package:web_query/src/query_part.dart';
import 'package:web_query/src/transforms.dart';

import 'src/html_query.dart';
import 'src/js_executor.dart';
import 'src/json_query.dart';
import 'src/page_data.dart';
import 'src/query_result.dart';
import 'src/query_validator.dart';
import 'src/url_query.dart';

export 'src/page_data.dart';
export 'src/query_validator.dart';
export 'src/transforms.dart' show DiscardMarker;

abstract class DataPicker {
  Iterable<PageNode> getCollection(PageNode node);
  Iterable getCollectionValue(PageNode node);
  String getValue(PageNode node, {String separator = "\n"});
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
class QueryString extends DataPicker {
  final List<QueryPart> _queries;
  final String? query;

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

  /// Validates the query string syntax and returns detailed results
  /// This method does not affect query execution
  ValidationResult validate() {
    if (query == null || query!.isEmpty) {
      return ValidationResult(query ?? '', [], []);
    }
    return QueryValidator.validate(query!);
  }

  dynamic execute(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    // Check if query contains >>> operator
    if (query?.contains('>>>') ?? false) {
      // Split at >>> and handle specially
      final parts = query!.split('>>>');
      if (parts.length == 2) {
        // Execute first part and capture variables
        final firstExecution = QueryString(parts[0].trim())
            ._executeQueriesWithVariables(node,
                simplify: false, initialVariables: initialVariables);

        // Convert result to list if it isn't already
        final resultList = (firstExecution.result is Iterable)
            ? firstExecution.result.toList()
            : [firstExecution.result];

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
        final arrayNode = arrayPageData.getRootElement();

        // Execute second part on the JSON array with captured variables
        return QueryString(parts[1].trim()).execute(arrayNode,
            simplify: simplify, initialVariables: firstExecution.variables);
      }
    }

    // Normal execution
    // Reset JavaScript runtime only if query uses jseval
    if (_usesJseval()) {
      _resetJsRuntime();
    }
    return _executeQueries(node,
        simplify: simplify, initialVariables: initialVariables);
  }

  bool _usesJseval() {
    // Check if any query part uses jseval transform
    for (var query in _queries) {
      if (query.transforms.containsKey('transform')) {
        final transforms = query.transforms['transform']!;
        if (transforms.any((t) => t.startsWith('jseval'))) {
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

  ({dynamic result, Map<String, dynamic> variables})
      _executeQueriesWithVariables(PageNode node,
          {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    final variables = <String, dynamic>{...?initialVariables};
    QueryResult result = QueryResult([]);
    final hasMultipleQueries = _queries.length > 1;

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
            final subResult = _executeSingleQueryWithDiscard(
                query, itemNode, variables, hasMultipleQueries);
            pipedData.addAll(subResult.data);
          }
          result_ = QueryResult(pipedData);
        }
        // Replace result with piped result
        result = result_;
      } else {
        result_ = _executeSingleQueryWithDiscard(
            query, node, variables, hasMultipleQueries);
        result = result.combine(result_);
      }
    }

    //_log.fine("execute queries result: $result");

    // Always filter out discarded items and unwrap kept items
    result =
        QueryResult(result.data.where((e) => e is! DiscardMarker).toList());

    final finalResult = !simplify
        ? result.data.map((e) => e is Element
            ? PageNode(node.pageData, element: e)
            : PageNode(node.pageData, jsonData: e))
        : result.data.isEmpty
            ? null
            : result.data.length == 1
                ? result.data.first
                : result.data;

    return (result: finalResult, variables: variables);
  }

  dynamic _executeQueries(PageNode node,
      {bool simplify = true, Map<String, dynamic>? initialVariables}) {
    return _executeQueriesWithVariables(node,
            simplify: simplify, initialVariables: initialVariables)
        .result;
  }

  String _resolveString(String input, Map<String, dynamic> variables) {
    // if (variables.isEmpty) return input; // Removed for debugging
    // Match ${expression}
    return input.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (match) {
      var expression = match.group(1)!;
      try {
        // Replace variables in expression with their values
        // We sort keys by length descending to avoid partial replacements (e.g. replacing 'id' in 'idx')
        final sortedKeys = variables.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length));

        for (final key in sortedKeys) {
          if (expression.contains(key)) {
            final value = variables[key];
            // Only replace if it looks like a variable (simple check)
            // function_tree supports variables but we need to pass them or substitute them.
            // Substituting is safer for now as function_tree interprets strings.
            // But we need to be careful about string values vs numbers.
            // If value is number, just put it in. If string, quote it?
            // function_tree is mainly for math.

            // Better approach: Check if expression is JUST a variable name first
            if (expression == key) {
              return value.toString();
            }

            if (value is num) {
              expression = expression.replaceAll(key, value.toString());
            } else if (value is String) {
              final numValue = num.tryParse(value);
              if (numValue != null) {
                expression = expression.replaceAll(key, numValue.toString());
              }
            }
          }
        }

        // If we replaced variables, or if the expression is just numbers, try to interpret
        // If it's a string concatenation like "prefix" + id, function_tree might not handle it if it expects math.
        // function_tree 0.9.0 supports some functions but mainly math.

        // Let's try to interpret.
        final result = expression.interpret();

        // If result is integer (ends with .0), convert to int string
        if (result is double && result == result.truncateToDouble()) {
          return result.toInt().toString();
        }
        return result.toString();
      } catch (e) {
        // Fallback: if interpretation fails (e.g. string operations not supported by function_tree),
        // check if it's a simple variable lookup
        if (variables.containsKey(expression)) {
          return variables[expression].toString();
        }

        // Handle string concatenation manually if function_tree failed
        if (expression.contains('+')) {
          // Simple string concatenation support
          // Split by + and concatenate parts
          // We need to be careful about quoted strings vs variables
          // For now, let's just support simple variable + string or variable + variable
          // This is a very basic implementation to support the user's request
          try {
            final parts = expression.split('+');
            final sb = StringBuffer();
            for (var part in parts) {
              part = part.trim();
              // Check if it's a quoted string
              if ((part.startsWith("'") && part.endsWith("'")) ||
                  (part.startsWith('"') && part.endsWith('"'))) {
                sb.write(part.substring(1, part.length - 1));
              } else if (variables.containsKey(part)) {
                sb.write(variables[part]);
              } else if (double.tryParse(part) != null) {
                // It's a number
                sb.write(part);
              } else {
                // Assume it's a string literal without quotes if it's not a variable?
                // No, that's dangerous. But for "prefix + 1", "prefix" was replaced by "test".
                // So expression is "test + 1".
                // "test" is not in variables (it IS the value).
                // So we just append it.
                sb.write(part);
              }
            }
            return sb.toString();
          } catch (e) {
            // Ignore and return original
          }
        }

        // But function_tree throws on strings.

        return match.group(0)!;
      }
    });
  }

  QueryResult _executeSingleQuery(
      QueryPart query, PageNode node, Map<String, dynamic> variables) {
    // Resolve variables in path
    final resolvedPath = _resolveString(query.path, variables);

    //_log.fine("execute query: $query");
    if (query.scheme == 'template') {
      return QueryResult([resolvedPath]);
    }

    if (!['json', 'html', 'url'].contains(query.scheme)) {
      throw FormatException('Unsupported scheme: ${query.scheme}');
    }

    // Resolve variables in parameters
    final resolvedParameters = <String, List<String>>{};
    query.parameters.forEach((key, values) {
      resolvedParameters[key] =
          values.map((v) => _resolveString(v, variables)).toList();
    });

    // Resolve variables in transforms
    final resolvedTransforms = <String, List<String>>{};
    query.transforms.forEach((key, values) {
      resolvedTransforms[key] =
          values.map((v) => _resolveString(v, variables)).toList();
    });

    // Create a new query part with resolved path and parameters
    final resolvedQuery = QueryPart(query.scheme, resolvedPath,
        resolvedParameters, resolvedTransforms, query.required,
        isPipe: query.isPipe);

    QueryResult result = QueryResult([]);
    if (resolvedPath.isNotEmpty) {
      //final decodedPath = _decodePath(Uri.parse(query.path));
      result = query.scheme == 'json'
          ? applyJsonPathFor(node.jsonData, resolvedPath)
          : query.scheme == 'url'
              ? applyUrlPathFor(node,
                  resolvedQuery) // url query might need resolved path too but it uses query object
              : applyHtmlPathFor(
                  node.element,
                  // Create a temporary query part with resolved path for HTML query
                  resolvedQuery);
    } else {
      result = query.scheme == 'url'
          ? applyUrlPathFor(node, resolvedQuery)
          : QueryResult(node);
    }

    // Extract index transform (it applies to the list, not individual elements)
    final indexTransform = resolvedTransforms.remove('index');

    //_log.fine("execute query result before transform: $result");
    result = QueryResult(result.data
        .map((e) => applyAllTransforms(node, e, resolvedTransforms, variables))
        .where(
            (e) => e != null && e != 'null' && e.toString().trim().isNotEmpty)
        .toList());

    // Apply index transform to the result list
    if (indexTransform != null && indexTransform.isNotEmpty) {
      final indexStr = indexTransform.first;
      result = QueryResult(applyIndex(result.data, indexStr));
    }

    return result;
  }

  QueryResult _executeSingleQueryWithDiscard(QueryPart query, PageNode node,
      Map<String, dynamic> variables, bool shouldDiscardByDefault) {
    var result = _executeSingleQuery(query, node, variables);

    // Auto-discard when 'save' is present unless 'keep' is also present
    final hasSave = query.transforms.containsKey('save');
    final hasKeep = query.transforms.containsKey('keep');

    if (hasSave && !hasKeep) {
      result = QueryResult(result.data.map((e) => DiscardMarker(e)).toList());
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

  PageNode _tryParseJson(PageNode node, String item) {
    try {
      final json = jsonDecode(item);
      return PageNode(node.pageData, jsonData: json);
    } catch (e) {
      return PageNode(node.pageData, jsonData: item);
    }
  }
}
