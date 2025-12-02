import 'package:html/dom.dart';

import 'query_part.dart';
import 'query_result.dart';

QueryResult applyHtmlPathFor(Element? element, QueryPart query) {
  if (element == null) return QueryResult([]);

  final parts = query.path
      .split(RegExp(r'(/|(?=@))'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return QueryResult([element]);

  final lastPart = parts.last;

  // Handle attribute or HTML content query in last part
  var elements = navigateElement(element, parts, query);
  return lastPart.startsWith('@')
      ? QueryResult(extractHtmlValue(elements, lastPart))
      : QueryResult(elements);
}

List<Element> querySelectorWithPrefix(Element element, String selector) {
  if (selector.startsWith('*')) {
    return element.querySelectorAll(selector.substring(1)).toList();
  }
  final result = element.querySelector(selector);
  return result != null ? [result] : [];
}

List<Element> navigateElement(
    Element element, List<String> parts, QueryPart query) {
  var currentElements = [element];

  for (var part in parts) {
    if (currentElements.isEmpty) return [];
    currentElements = currentElements
        .expand((elem) => applySingleNavigation(elem, part))
        .toList();
  }

  return currentElements;
}

List<Element> applySingleNavigation(Element element, String part) {
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
      return querySelectorWithPrefix(element, part);
  }
}

List extractHtmlValue(List<Element> elements, String accessor) {
  return elements.map((e) => extractAttributeValue(e, accessor)).toList();
}

String? extractAttributeValue(Element element, String accessor) {
  accessor = accessor.substring(1);
  final attributes = accessor.split(RegExp(r'(\|)'));
  final result = attributes
      .map((attribute) => extractSingleAttributeValue(element, attribute))
      .where((e) => e?.isNotEmpty ?? false)
      .firstOrNull;
  return result;
}

String? extractSingleAttributeValue(Element element, String attribute) {
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
