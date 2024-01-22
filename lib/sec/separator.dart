class Separator {
  final RegExp regExp;
  final bool firstCanIgnore;

  /// the class
  Separator(this.regExp, this.firstCanIgnore);

  (String, String) split(String exp) {
    exp = exp.trim();
    final match = regExp.firstMatch(exp);
    return match != null
        ? (match.group(1)!, match.group(2)!)
        : firstCanIgnore
            ? ("", exp)
            : (exp, "");
  }
}

/// combination is data structure that combine [isEvery] and [children]
/// isEvery: true means that every result that name in names be handled should be combined.
/// other choose the first meaningful result
/// the result is meaningful should be decided by the program that interpret data.
class Combination {
  late bool isEvery;
  late String expression;
  late List<String> children;

  ///separate exp like [any#]expression separate into [isEvery] and [expression]
  /// and using [pattern] to separate [expression] into [children]
  /// [parentEvery] means if not [anyTag] or [everyTag] found in [exp]
  /// that default [isEvery] value should be.
  /// if [pattern] is null [children] only has one element that is [expression]
  /// otherwise using string.split split [expression] using [pattern] into names.
  Combination(bool parentEvery, String exp, {String? pattern}) {
    exp = exp.trim();
    final (tag, after) = anySeparator.split(exp);
    isEvery = tag.isEmpty ? parentEvery : tag != anyTag;
    expression = after;
    children = pattern != null ? after.split(pattern) : [after];
  }

  @override
  String toString() {
    return "Combination: {isEvery: $isEvery, names: $children}";
  }
}

List<String> parseExpressionTags(String exp, List<Separator> separators) {
  List<String> tags = [];
  final expression = separators.fold(exp, (prev, separator) {
    final (before, after) = separator.split(prev);
    tags.add(before);
    return after;
  });
  tags.add(expression);
  return tags;
}

const anyTag = 'any';
const everyTag = 'every';
const jsonTag = "json";
const htmlTag = "html";
final anySeparator = Separator(RegExp("^($anyTag|$everyTag)#(.*)"), true);
final jsonSeparator = Separator(RegExp("^($jsonTag|$htmlTag):(.*)"), true);
final attributeSeparator = Separator(RegExp("^(.*?)@(.*)"), false);
final regExpSeparator = Separator(RegExp("^(.*?)::(.*)"), false);
const selectorExpPattern = "||";

/// selectors expressions like: [anyOrEverytag#]selector [|| selector || selector]
/// content in [] mean is optional
/// separate selectors expression into different parts that is bool [isEvery]
/// and List<SelectorExpression> [selectors]
/// anyOrEveryTag could be string "any" or "every", (no quotation), default is every
/// example: selector1 || selector1
/// means combine selector1 and selector2 result;
/// example: every##selector1 || selector2
/// means same thing above
/// example: any#selector1 || selector2
/// means if selector1 has result then choose selector1 otherwise selector2
/// example: every#selector||selector||selector
/// are all legal.
/// [parentEvery] means default selectorsExpression [isEvery] value
/// please see [Combination]
Combination selectorsExpression(bool parentEvery, String selectorsExpression) {
  return Combination(parentEvery, selectorsExpression,
      pattern: selectorExpPattern);
}

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

class RegExpWithReplace {
  late String regExp;
  late String replacement;
  RegExpWithReplace(String reg) {
    if (reg.isEmpty) {
      regExp = "";
      replacement = "";
    } else {
      final (reg_, replacement_) =
          Separator(RegExp(r"(.*[^\\])/(.*?)"), false).split(reg);
      regExp = reg_;
      replacement = replacement_;
    }
  }

  String getValue(String value) {
    if (regExp.isEmpty) return value;
    final match = RegExp(regExp).firstMatch(value);
    String result = match == null
        ? ""
        : (match.groupCount > 1)
            ? match.group(1) ?? ""
            : match.group(0) ?? "";

    if (replacement.isNotEmpty) {
      result = replacement.replaceAll(r"$$", result);
    }
    //debugPrint("reg $regExp from $value to $result");
    return result;
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
