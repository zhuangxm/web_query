library web_parser;

import 'package:web_query/query.dart';

export 'src/expression.dart';
export 'src/page_data.dart';
export 'src/selector.dart';
export 'src/separator.dart';

/// old protocol referer src/selector.dart
/// new protocol referer query.dart
String webValue(PageNode node, String selectors, {bool newProtocol = false}) {
  return QueryString(selectors, newProtocol: newProtocol).getValue(node);
}

/// return collection of PageNodes in [node]  that [selectors] represents.
Iterable<PageNode> webCollection(PageNode node, String selectors,
    {bool newProtocol = false}) {
  return QueryString(selectors, newProtocol: newProtocol).getCollection(node);
}

/// return iterable of json data or htmlElement, depend on selector.
/// the every doesn't mean to be same type. could be one is htmlElement
/// and the other is jsonData.
Iterable webCollectionValue(PageNode node, String selectors,
    {bool newProtocol = false}) {
  return QueryString(selectors, newProtocol: newProtocol)
      .getCollectionValue(node);
}
