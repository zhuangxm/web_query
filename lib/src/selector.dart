import 'package:collection/collection.dart';
import 'package:html/dom.dart' as dom;

import '../src/expression.dart';
import '../src/page_data.dart';
import '../src/separator.dart';

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
  ///and join them by separator default is \n
  String getValue(PageNode node, {String separator = "\n"});
}

/// selectors syntax, inside [] means optional
/// String begin with lowercase mean string itself.
/// String begin with Uppercase mean another expression type.
///  [or] not keyword in the middle of expression mean can only one of them to appears in the expression .
///  [|] keyword in the middle of expression means | is the legal character.
///  AnyOrEveryTag = any or every followed by #, examples any# every# default every#
///  JsonOrHtmlTag = json or html followed by :,  examples json: html: default html:
/// Selectors = [AnyOrEveryTag]Selector[|| Selector || Selector ...]
/// Selector = [AnyOrEveryTag][JsonOrHtmlTag]SubSelector.
/// SubSelector could be HtmlSelector or JsonSelector;
/// HtmlSelector = [HtmlTag?][Path/]CssSelector[@Attribute]
/// HtmlTag = means normal normal html tag like div, a ...
/// Path = PathElement[/PathElement/PathElement]
/// PathElement = PathKeyWord[.className]
/// if has className means follow the path to find a element that has class named className
/// PathKeyWord = "prev" or "next" or "parent" or "root"
/// examples: parent/prev.videos means find element's parent's previousSiblings
/// that has class named videos.
/// CssSelector are normal cssSelector, using in document.querySelectorAll.
/// if CssSelector is empty means current element
/// Attribute could be Attribute::RegExpWithReplacement.
/// Attribute = html element attribute name like src, href
/// Special Attribute:
/// empty means get element's text
/// innerHtml means get element's innerHtml
/// outerHtml means get element's outerHtml
/// rootUrl means pageData's url.
/// RegExpWithReplacement = RegExp[/Replacement]
/// Cautions: if not attribute defined in the expression the @ cannot be omitted;
/// RegExp = regular Regular expression. if only one group defined. return it.
/// otherwise return the second group.   group(1)
/// Replacement = replace "$$" in the replacement expression with
/// the regular expression value
/// JsonSelector = [Id?]Path[::RegExp[/Replacement]]
/// Id = not empty mean's get the document element id named id's innerHtml as jsonData.
/// Path = PathElement[/PathElement/PathElement]
/// PathElement = [AnyOrEveryTag]Key1[|Key2|Key3...]
/// Key could be String or int. String means get map[key], int means get List[index]

/// return string in [node]  that [selectors] represents.
///  if each selector in [selectors] has value that is not emtpy
///  then join them with \n.
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
  String getValue(PageNode node, {String separator = "\n"}) {
    return children
        .map((selector) => selector.getValue(node, separator: separator))
        .where((e) => e.isNotEmpty)
        .take(isEvery ? maxCount : 1)
        .join(separator);
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
            .where((v) => v.isNotEmpty)
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
  String getValue(PageNode node, {String separator = " "}) {
    return getCollection(node)
        .map((e) => getAttributesValue(e))
        .where((e) => judgeDataIsNotEmpty(e))
        .take(expression.isEvery ? maxCount : 1)
        .join(separator);
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
  String getValue(PageNode node, {String separator = "\n"}) {
    return getCollection(node)
        .map((e) => e.jsonData == null ? "" : e.jsonData.toString())
        .where((element) => element.isNotEmpty)
        .join(separator);
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
