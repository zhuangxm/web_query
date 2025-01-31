import 'dart:convert';

import 'package:html/dom.dart';

/// class represent the data from web request returns.
class PageData {
  /// the html page.
  late String html;

  /// the document that parse the html using html package.
  late Document? document;

  /// the jsonData than in the html page that has the id [defaultJsonId]
  ///  or the web request returns application/json data.
  ///  or user parse that html page and get some jsondata.
  late dynamic jsonData;

  /// the url that web data comes from
  String url;

  /// parse the html into object's [document].
  /// object's [jsonData] first come from the parameter's [jsonData] and decode it into json object.
  /// if [defaultJsonId] is not null then get data from document that has id named [defaultJsonId],
  /// otherwise set to null
  PageData(this.url, this.html,
      {String? this.jsonData, String? defaultJsonId}) {
    document = Document.html(html);
    jsonData = jsonData != null
        ? jsonDecode(jsonData)
        : (defaultJsonId != null)
            ? getJsonDataById(defaultJsonId)
            : null;
    //debugPrint("page data ${document?.documentElement}");
  }

  ///get jsonData from [document] that has id named [id]
  ///if not throw Exception.
  getJsonDataById(String? id) {
    if (id?.isEmpty ?? true) return jsonData;
    final data = document?.getElementById(id!)?.innerHtml;
    if (data == null) {
      throw Exception("invalid json id: $id");
    }
    return jsonDecode(data);
  }

  /// get the pageNode that represent the document's  documentElement
  /// and jsonData.
  PageNode getRootElement() {
    return PageNode(this,
        element: document?.documentElement, jsonData: jsonData);
  }

  /// equal to [getRootElement].
  PageNode root() => getRootElement();
}

/// return a [Element] of [document] or part of [jsonData] or both.
class PageNode {
  /// where pageNode come from.
  final PageData pageData;

  /// the root element of this
  Element? element;

  /// the root data of this
  dynamic jsonData;
  PageNode(this.pageData, {this.element, this.jsonData});
}
