<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

using simple syntax to query web html or json data.

## Features

## Getting started

adding library to pubspec.yaml

```
web_query:
  git:
    url: https://github.com/zhuangxm/web_query.git
```

## Usage

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_query/sec/page_data.dart';
import 'package:web_query/web_query.dart';

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

```

## Additional information

Please see lib/web_query.dart for more information about expression syntax.
