import 'package:html/dom.dart';

import 'src/html_query.dart';
import 'src/json_query.dart';
import 'src/page_data.dart';
import 'src/query_part.dart';
import 'src/query_result.dart';
import 'src/selector.dart';
import 'src/transforms.dart';
import 'src/url_query.dart';

export 'src/page_data.dart';
export 'src/query_part.dart';
export 'src/query_result.dart';

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
  final List<QueryPart> _queries;
  final String? query;

  QueryString(this.query)
      : _queries = (query ?? "")
            .splitKeep(RegExp(r'(\|\||\+\+)'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .fold((true, <QueryPart>[]), (result, v) {
              final (required, l) = result;
              if (v == '||') {
                return (false, l);
              } else if (v == '++') {
                return (true, l);
              } else {
                l.add(QueryPart.parse(v, required: required));
                return (required, l);
              }
            })
            .$2
            .toList();

  dynamic execute(PageNode node, {bool simplify = true}) {
    return _executeQueries(node, simplify);
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

  QueryResult _executeSingleQuery(QueryPart query, PageNode node) {
    //_log.fine("execute query: $query");
    if (!['json', 'html', 'url'].contains(query.scheme)) {
      throw FormatException('Unsupported scheme: ${query.scheme}');
    }

    QueryResult result = QueryResult([]);
    if (query.path.isNotEmpty) {
      //final decodedPath = _decodePath(Uri.parse(query.path));
      result = query.scheme == 'json'
          ? applyJsonPathFor(node.jsonData, query.path)
          : query.scheme == 'url'
              ? applyUrlPathFor(node, query)
              : applyHtmlPathFor(node.element, query);
    } else {
      result = query.scheme == 'url'
          ? applyUrlPathFor(node, query)
          : QueryResult(node);
    }
    //_log.fine("execute query result before transform: $result");
    result = QueryResult(result.data
        .map((e) => applyAllTransforms(node, e, query.transforms))
        .where(
            (e) => e != null && e != 'null' && e.toString().trim().isNotEmpty)
        .toList());
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
