import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_parser/sec/page_data.dart';
import 'package:web_parser/web_query.dart';

const html = """
<html>
  <div class="videos">
    <a href="a1">a1 text</a>
    <a href="a2">a2 text</a>
  </div>
</html>
""";

const jsonData = {
  "props": {
    "videos": [
      {"id": "id1", "url": "http://s1"},
      {"id": "id2", "url": "http://s12"}
    ]
  }
};

final pageData =
    PageData("https://test.com", html, jsonData: jsonEncode(jsonData));

void main() {
  test("test web value", () {
    expect(webValue(pageData.getRootElement(), "div a"), "a1 text a2 text");
    expect(webValue(pageData.getRootElement(), "any#div a"), "a1 text");
    expect(webCollection(pageData.getRootElement(), "div a").length, 2);
    expect(webCollection(pageData.getRootElement(), "any#div a").length, 1);
    expect(
        webValue(pageData.getRootElement(), "json:props/videos/1/id"), "id2");
    expect(webValue(pageData.getRootElement(), "json:props/videos/0|1/id"),
        "id1 id2");
    expect(webValue(pageData.getRootElement(), "json:props/videos/any#0|1/id"),
        "id1");
    expect(webCollection(pageData.getRootElement(), "json:props/videos").length,
        2);
    expect(
        webCollection(pageData.getRootElement(), "any#json:props/videos")
            .length,
        1);
  });
}
