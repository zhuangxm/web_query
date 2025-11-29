import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;

String filterHtmlOnly(String html) {
  try {
    final document = html_parser.parse(html);

    // Remove unwanted elements
    final unwantedSelectors = [
      'script',
      'style',
      'iframe',
      'noscript',
      'link',
      'meta'
    ];
    for (final selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((element) {
        element.remove();
      });
    }

    return document.outerHtml;
  } catch (e) {
    return html;
  }
}

String filterHtml(String html) {
  return formatHtml(filterHtmlOnly(html));
}

String formatHtml(String html) {
  try {
    final document = html_parser.parse(html);
    final root = document.documentElement ?? document.body;
    if (root == null) return html;
    return formatElement(root, 0);
  } catch (e) {
    return html;
  }
}

String formatElement(html.Element element, int indent) {
  final buffer = StringBuffer();
  final indentStr = '  ' * indent;
  final tagName = element.localName;

  // Opening tag
  buffer.write('$indentStr<$tagName');

  // Attributes
  if (element.attributes.isNotEmpty) {
    element.attributes.forEach((key, value) {
      buffer.write(' $key="${escapeHtml(value)}"');
    });
  }

  // Self-closing tags
  if (element.nodes.isEmpty) {
    buffer.writeln(' />');
    return buffer.toString();
  }

  buffer.write('>');

  // Check if element has only text content (inline)
  final hasOnlyText = element.nodes.length == 1 &&
      element.nodes.first.nodeType == html.Node.TEXT_NODE;

  if (hasOnlyText) {
    final text = element.text.trim();
    if (text.isNotEmpty && text.length < 80) {
      buffer.write(escapeHtml(text));
      buffer.writeln('</$tagName>');
      return buffer.toString();
    }
  }

  buffer.writeln();

  // Children
  for (final node in element.nodes) {
    if (node.nodeType == html.Node.ELEMENT_NODE) {
      buffer.write(formatElement(node as html.Element, indent + 1));
    } else if (node.nodeType == html.Node.TEXT_NODE) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty) {
        buffer.writeln('$indentStr  ${escapeHtml(text)}');
      }
    }
  }

  // Closing tag
  buffer.writeln('$indentStr</$tagName>');

  return buffer.toString();
}

String escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
