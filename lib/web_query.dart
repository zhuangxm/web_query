library web_parser;

import 'package:web_parser/src/page_data.dart';
import 'package:web_parser/src/selector.dart';

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
String webValue(PageNode node, String selectors) {
  return Selectors(selectors).getValue(node);
}

/// return collection of PageNodes in [node]  that [selectors] represents.
Iterable<PageNode> webCollection(PageNode node, String selectors) {
  return Selectors(selectors).getCollection(node);
}

/// return iterable of json data or htmlElement, depend on selector.
/// the every doesn't mean to be same type. could be one is htmlElement
/// and the other is jsonData.
Iterable webCollectionValue(PageNode node, String selectors) {
  return Selectors(selectors).getCollectionValue(node);
}
