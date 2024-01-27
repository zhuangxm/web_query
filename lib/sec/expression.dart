import 'package:web_parser/sec/separator.dart';

///represent like [anyOrEverytag#]expression
///expression like [jsonOrHtmlTag:]subExpression
///jsonOrHtmlTag could be "json" or "html" default is html
class SelectorExpression {
  late bool isJson;
  final bool isEvery;
  final String path;
  late List<String> pathParts;
  late RegExpWithReplace regExp;
  SelectorExpression(
      {required this.isEvery,
      required isJson,
      required this.path,
      String reg = ""}) {
    pathParts = path.split("/");
    regExp = RegExpWithReplace(reg);
  }

  factory SelectorExpression.from(bool parentEvery, String selectorExpression) {
    final combination = Combination(
      parentEvery,
      selectorExpression,
    );
    final (tag, expression) = jsonSeparator.split(combination.expression);
    final isJson = tag == jsonTag;
    return isJson
        ? JsonSelectorExpression.from(combination.isEvery, expression)
        : HtmlSelectorExpression.from(combination.isEvery, expression);
  }

  @override
  String toString() {
    return "isEvery: $isEvery, path: $path reg: $regExp";
  }
}

class HtmlSelectorExpression extends SelectorExpression {
  final String attribute;
  late List<String> attributeParts;
  final String cssSelector;
  final String htmlTag;
  HtmlSelectorExpression(
      {required this.attribute,
      required super.isEvery,
      required super.path,
      required this.htmlTag,
      required this.cssSelector,
      required super.reg,
      required super.isJson}) {
    attributeParts = attribute.split("|");
  }
  factory HtmlSelectorExpression.from(
      bool parentEvery, String selectorExpression) {
    final (pathBodyWithTag, attributeBody) =
        attributeSeparator.split(selectorExpression);
    final (htmlTag, pathBody) =
        Separator(RegExp(r"^([\w]+?)\?(.*)"), true).split(pathBodyWithTag);
    final (path, cssSelector) =
        Separator(RegExp(r"^(.*)/(.*?)$"), true).split(pathBody);
    final (attribute, regExp) = regExpSeparator.split(attributeBody);
    return HtmlSelectorExpression(
        isJson: false,
        htmlTag: htmlTag,
        attribute: attribute,
        isEvery: parentEvery,
        cssSelector: cssSelector,
        path: path,
        reg: regExp);
  }

  @override
  toString() {
    return "HtmlSelectorExpression htmlTag: $htmlTag, cssSelector: $cssSelector attributes: $attribute ${super.toString()}";
  }
}

class JsonSelectorExpression extends SelectorExpression {
  final String jsonId;
  JsonSelectorExpression(
      {required super.isJson,
      required this.jsonId,
      required super.isEvery,
      required super.path,
      required super.reg});

  factory JsonSelectorExpression.from(
      bool parentEvery, String selectorExpression) {
    final (pathBody, regExp) = regExpSeparator.split(selectorExpression);
    final (jsonId, path) =
        Separator(RegExp(r"^(\w+?)?(.*)"), true).split(pathBody);
    return JsonSelectorExpression(
        jsonId: jsonId,
        isJson: true,
        isEvery: parentEvery,
        path: path,
        reg: regExp);
  }

  @override
  String toString() {
    return "JsonSelectorExpression jsonId: $jsonId ${super.toString()}";
  }
}
