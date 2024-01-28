import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;
import 'package:web_parser/src/expression.dart';
import 'package:web_parser/src/page_data.dart';
import 'package:web_parser/src/separator.dart';

const maxCount = 10000;

/// if data is collection then judge data is not empty.
/// other type then judge data is not null.
bool judgeDataIsNotEmpty(data) {
  try {
    return data.isNotEmpty;
  } catch (e) {
    return data != null;
  }
}

abstract class DataPicker {
  Iterable<PageNode> getCollection(PageNode node);

  /// get iterable of [Element] or jsonData.
  Iterable getCollectionValue(PageNode node);

  ///convert each value in [getCollectionValue] to String,
  ///and join them by \n
  String getValue(PageNode node);
}

class Selectors implements DataPicker {
  late bool isEvery;
  late List<Selector> children;

  Selectors(String? exp) {
    if (exp != null) {
      Combination combination = selectorsExpression(true, exp);

      isEvery = combination.isEvery;
      children =
          combination.children.map((e) => Selector.from(isEvery, e)).toList();
    } else {
      isEvery = true;
      children = [];
    }
    //debugPrint("selectors: $this");
  }

  @override
  List<PageNode> getCollection(PageNode node) {
    return children.fold([], (previousValue, selector) {
      if (!isEvery && previousValue.isNotEmpty) {
        return previousValue;
      } else {
        previousValue.addAll(selector.getCollection(node));
        return previousValue;
      }
    });
  }

  @override
  String getValue(PageNode node) {
    return children
        .map((selector) => selector.getValue(node))
        .where((e) => e.isNotEmpty)
        .take(isEvery ? maxCount : 1)
        .join("\n");
  }

  @override
  List getCollectionValue(PageNode node) {
    return children.fold([], (previousValue, selector) {
      if (!isEvery && previousValue.isNotEmpty) {
        return previousValue;
      } else {
        previousValue.addAll(selector.getCollectionValue(node));
        return previousValue;
      }
    });
  }

  @override
  String toString() {
    return "Selectors isEvery: $isEvery, children: $children";
  }
}

abstract class Selector implements DataPicker {
  Selector();

  factory Selector.from(parentEvery, String exp) {
    SelectorExpression expression = SelectorExpression.from(parentEvery, exp);
    return expression.isJson
        ? JsonSelector(expression as JsonSelectorExpression)
        : HtmlSelector(expression as HtmlSelectorExpression);
  }

  /// replace $rootUrl$ , $pageUrl$ String with actually value.
  String replaceValue(String str, PageData pageData) {
    final pageUrl = pageData.url;
    final rootUrl = Uri.parse(pageUrl).origin;

    return str
        .replaceAll(r"$rootUrl$", rootUrl)
        .replaceAll(r"$pageUrl$", pageUrl);
  }
}

class HtmlSelector extends Selector {
  final HtmlSelectorExpression expression;
  HtmlSelector(this.expression);

  @override
  toString() {
    return expression.toString();
  }

  dom.Element? searchForElementHasClassName(String? className,
      dom.Element? element, dom.Element? Function(dom.Element?) next) {
    dom.Element? result = next(element);
    if (className?.isEmpty ?? true) return result;
    while (result != null) {
      //debugPrint("next level className ${result.className} $className");
      if (result.className.contains(className!)) return result;
      result = next(result);
    }
    return result;
  }

  dom.Element? getElementAtPath(dom.Element element, paths) {
    return paths.fold(element, (previousValue, String path) {
      final index = path.indexOf(".");
      String? className;
      if (index != -1) {
        className = path.substring(index + 1);
        path = path.substring(0, index);
        //debugPrint("className: $className");
      }
      switch (path) {
        case "prev":
          return searchForElementHasClassName(
              className, previousValue, (e) => e?.previousElementSibling);
        case "next":
          return searchForElementHasClassName(
              className, previousValue, (e) => e?.nextElementSibling);
        case "parent":
          return searchForElementHasClassName(
              className, previousValue, (e) => e?.parent);
        case "root":
          {
            dom.Element? parent = previousValue;
            while (parent?.parent != null) {
              parent = parent?.parent;
            }
            return parent;
          }
        default:
          return previousValue;
      }
    });
  }

  String getAttributeValue(PageNode node, String attribute) {
    final pageUrl = node.pageData.url;
    final rootUrl = Uri.parse(pageUrl).origin;
    final result = (node.element == null)
        ? ""
        : attribute.isEmpty
            ? node.element!.text.trim()
            : attribute.startsWith(".")
                ? node.element!.className.contains(attribute.substring(1))
                    ? "true"
                    : ""
                : switch (attribute) {
                    "innerHtml" => node.element!.innerHtml,
                    "outerHtml" => node.element!.outerHtml,
                    "pageUrl" => pageUrl,
                    "rootUrl" => rootUrl,
                    _ => node.element!.attributes[attribute] ?? ""
                  };

    return replaceValue(expression.regExp.getValue(result), node.pageData);
  }

  String getAttributesValue(PageNode node) {
    return node.element == null
        ? ""
        : expression.attributeParts
            .map((attribute) => getAttributeValue(node, attribute))
            .take(expression.isEvery ? maxCount : 1)
            .join(" ");
  }

  List<dom.Element> querySelectAll(dom.Element element, String cssSelector) {
    return cssSelector.isEmpty
        ? [element]
        : element.querySelectorAll(cssSelector);
  }

  @override
  Iterable<PageNode> getCollection(PageNode node) {
    if (node.element != null) {
      final element = getElementAtPath(node.element!, expression.pathParts);
      final tag = expression.htmlTag;
      return (element == null ||
              (tag.isNotEmpty && tag != node.element!.localName))
          ? []
          : querySelectAll(element, expression.cssSelector)
              .map((e) =>
                  PageNode(node.pageData, element: e, jsonData: node.jsonData))
              .take(expression.isEvery ? maxCount : 1);
    } else {
      return [];
    }
  }

  @override
  String getValue(PageNode node) {
    return getCollection(node)
        .map((e) => getAttributesValue(e))
        .where((e) => judgeDataIsNotEmpty(e))
        .take(expression.isEvery ? maxCount : 1)
        .join(" ");
  }

  @override
  Iterable getCollectionValue(PageNode node) {
    return getCollection(node).map(
      (e) => e.element,
    );
  }
}

class JsonSelector extends Selector {
  JsonSelectorExpression expression;
  JsonSelector(this.expression);

  dynamic getJsonData(jsonData, key) {
    if (key.isEmpty) return jsonData;
    return (jsonData is Map)
        ? jsonData[key]
        : (jsonData is List && jsonData.isNotEmpty)
            ? jsonData[int.parse(key)]
            : jsonData;
  }

  dynamic combineData(Iterable data, bool isEvery) {
    if (data.isEmpty) return null;
    final firstElement = data.first;
    if (!isEvery) return firstElement;
    if (firstElement is Iterable) {
      List combineList = [];
      data.forEachIndexed((index, element) {
        combineList.addAll(element);
      });
      return combineList;
    } else if (firstElement is Map) {
      Map combineList = {};
      data.forEachIndexed((index, element) {
        combineList.addAll(element as Map);
      });
      return combineList;
    } else {
      return data.join(" ");
    }
  }

  dynamic getDataFromPath(
      PageNode node, Combination comb, Iterable<String> follows) {
    final Iterable results = comb.children.map(((key) {
      final data = getJsonData(node.jsonData, key);
      return follows.isNotEmpty && data != null
          ? getDataFromPath(
              PageNode(node.pageData, element: node.element, jsonData: data),
              Combination(comb.isEvery, follows.first, pattern: "|"),
              follows.skip(1))
          : (data is String)
              ? replaceValue(expression.regExp.getValue(data), node.pageData)
              : data;
    })).where((e) => e != null && judgeDataIsNotEmpty(e));
    return combineData(results, comb.isEvery);
  }

  @override
  Iterable<PageNode> getCollection(PageNode node) {
    final jsonId = expression.jsonId;
    if (jsonId.isNotEmpty) {
      node = PageNode(node.pageData,
          element: node.element,
          jsonData: node.pageData.getJsonDataById(jsonId));
    }
    final pathParts = expression.pathParts;
    //final names = pathParts.names;
    final data = getDataFromPath(
        node,
        Combination(expression.isEvery, pathParts.first, pattern: "|"),
        pathParts.skip(1));
    return data == null
        ? []
        : (data is Iterable)
            ? data
                .map((e) =>
                    PageNode(node.pageData, element: node.element, jsonData: e))
                .take(expression.isEvery ? maxCount : 1)
            : [PageNode(node.pageData, element: node.element, jsonData: data)];
  }

  @override
  String getValue(PageNode node) {
    return getCollection(node)
        .map((e) => e.jsonData == null ? "" : e.jsonData.toString())
        .where((element) => element.isNotEmpty)
        .join("\n");
  }

  @override
  toString() {
    return "$expression";
  }

  @override
  Iterable getCollectionValue(PageNode node) {
    return getCollection(node).map(
      (e) => e.jsonData,
    );
  }
}
