import 'dart:convert';
import 'dart:typed_data';

import 'package:gbk_codec/gbk_codec.dart';
import 'package:html/dom.dart';
import 'package:logging/logging.dart';
import 'package:web_query/src/utils.dart/core.dart';
import 'package:xml2json/xml2json.dart';

final _log = Logger("PageData");

/// class represent the data from web request returns.
class PageData {
  /// the html page.
  final String html;

  /// the document that parse the html using html package.
  late Document? document;

  /// the jsonData than in the html page that has the id [defaultJsonId]
  ///  or the web request returns application/json data.
  ///  or user parse that html page and get some jsondata.
  late dynamic jsonData;

  /// the url that web data comes from
  final String url;

  /// parse the html into object's [document].
  /// object's [jsonData] first come from the parameter's [jsonData] and decode it into json object.
  /// if [defaultJsonId] is not null then get data from document that has id named [defaultJsonId],
  /// otherwise set to null
  PageData(this.url, this.html,
      {String? this.jsonData, String? defaultJsonId}) {
    try {
      document = Document.html(html);
    } catch (e) {
      _log.warning("html data is Invalid, using <html></html> instead, $e");
      document = Document.html("<html></html>");
    }

    document = Document.html(html);
    jsonData = jsonData != null
        ? jsonDecode(jsonData)
        : (defaultJsonId != null)
            ? getJsonDataById(defaultJsonId)
            : null;
    //debugPrint("page data ${document?.documentElement}");
  }

  // Internal constructor used by factory for pre-parsed inputs
  PageData.html(this.url, this.html)
      : document = Document.html(html),
        jsonData = null;

  PageData.json(this.url, this.jsonData)
      : html = '<html></html>',
        document = Document.html('<html></html>');

  // Auto-detect input type and construct PageData
  factory PageData.auto(String url, dynamic content) {
    // Normalize input: support raw bytes by decoding as UTF-8
    // Only treat Uint8List as bytes; generic List<int> may be real JSON arrays
    dynamic normalized = content;
    if (content is Uint8List) {
      try {
        normalized = utf8.decode(content);
      } catch (_) {
        try {
          normalized = gbk.decode(content);
        } catch (_) {
          normalized = content.toString();
        }
      }
    }

    if (normalized is! String) {
      return PageData.json(url, normalized);
    } else {
      var text = normalized.trim();

      // XML → JSON conversion
      if (text.startsWith("<?xml")) {
        try {
          final transfomer = Xml2Json();
          transfomer.parse(text);
          text = transfomer.toParkerWithAttrs();
        } catch (_) {}
      }

      // Decode JSON from possibly converted text
      try {
        return PageData.json(url, tryParseJson(text, throwException: true));
      } catch (_) {}
    }

    return PageData.html(url, normalized.toString());
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
