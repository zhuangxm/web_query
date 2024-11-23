import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/src/selector.dart';

void main() {
  test("selector test", () {
    final selectors = Selectors(
        r"any#a?prev/parent/div.video-list@value|tag::\w+/\/b$$c||json:/props/items::\d+/https:\/\/www.google.com\/a$$");
    expect(selectors.isEvery, false);
    final selector1 = selectors.children[0] as HtmlSelector;
    final selector1Expression = selector1.expression;
    expect(selector1Expression.originalReg, r"\w+/\/b$$c");
    expect(selector1Expression.isEvery, false);
    expect(selector1Expression.attribute, 'value|tag');
    expect(selector1Expression.cssSelector, 'div.video-list');
    expect(selector1Expression.path, 'prev/parent');
    expect(selector1Expression.regExp.regExp, r'\w+');
    expect(selector1Expression.regExp.replacement, r'/b$$c');

    final selector2 = selectors.children[1] as JsonSelector;
    final selector2Expression = selector2.expression;
    expect(
        selector2Expression.originalReg, r"\d+/https:\/\/www.google.com\/a$$");
    expect(selector2Expression.isEvery, false);
    expect(selector2Expression.path, '/props/items');
    expect(selector2Expression.regExp.regExp, r'\d+', reason: "select2 regexp");
    expect(
        selector2Expression.regExp.replacement, r'https://www.google.com/a$$');
  });
}
