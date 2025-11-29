import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

enum DataViewMode { html, json }

enum FilterResultType { text, html, error }

// ignore: unused_element
final _log = Logger("DataQueryWidget");

class DataQueryWidget extends HookWidget {
  const DataQueryWidget({
    super.key,
    required this.pageData,
    this.onToggleExpand,
    this.title = "Data Reader",
  });

  final PageData? pageData;
  final VoidCallback? onToggleExpand;
  final String title;

  @override
  Widget build(BuildContext context) {
    final viewMode = useState(DataViewMode.html);
    final queryController = useTextEditingController();
    final filterResults = useState<List<Map<String, dynamic>>>([]);
    final scrollController = useScrollController();

    // Memoize filtered HTML to avoid re-parsing on every rebuild
    final filteredHtml = useMemoized(
      () => pageData != null ? _filterHtmlOnly(pageData!.html) : '',
      [pageData],
    );

    // Memoize parsed document for tree view
    final parsedDocument = useMemoized(() {
      if (filteredHtml.isEmpty) return null;
      try {
        return html_parser.parse(filteredHtml);
      } catch (e) {
        return null;
      }
    }, [filteredHtml]);

    // Debounced query execution
    useEffect(() {
      Timer? debounceTimer;

      void executeQuery() {
        debounceTimer?.cancel();
        debounceTimer = Timer(const Duration(milliseconds: 300), () {
          final query = queryController.text.trim();
          if (query.isEmpty || pageData == null) {
            filterResults.value = [];
            return;
          }

          try {
            final queryString = QueryString(query);
            final root = pageData!.getRootElement();

            // Try to get collection first
            final collection = queryString.getCollectionValue(root);
            if (collection.isNotEmpty) {
              filterResults.value = collection.map((e) {
                if (e is html.Element) {
                  return {
                    'type': FilterResultType.html,
                    'value': e.outerHtml,
                    'node': e
                  };
                } else {
                  return {'type': FilterResultType.text, 'value': e.toString()};
                }
              }).toList();
            } else {
              filterResults.value = [];
            }
          } catch (e) {
            filterResults.value = [
              {'type': FilterResultType.error, 'value': 'Error: $e'}
            ];
          }
        });
      }

      queryController.addListener(executeQuery);
      return () {
        debounceTimer?.cancel();
        queryController.removeListener(executeQuery);
      };
    }, [pageData]);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // View mode toggle
                SegmentedButton<DataViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: DataViewMode.html,
                      label: Text('HTML', style: TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: DataViewMode.json,
                      label: Text('JSON', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {viewMode.value},
                  onSelectionChanged: (Set<DataViewMode> newSelection) {
                    viewMode.value = newSelection.first;
                  },
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return Colors.blue.shade500;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blue.shade700;
                      }
                      return Colors.white;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                if (onToggleExpand != null)
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 20, color: Colors.white),
                    onPressed: onToggleExpand,
                    tooltip: 'Close Data Reader',
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Row(
              children: [
                // Data display
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Colors.grey.shade800,
                    child: pageData == null
                        ? const Center(
                            child: Text(
                              'No data loaded',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : viewMode.value == DataViewMode.html
                            ? _HtmlTreeView(
                                document: parsedDocument,
                              )
                            : SizedBox.expand(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(12),
                                  child: SelectableText(
                                    _getDisplayContent(
                                        pageData!, viewMode.value),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                ),
                              ),
                  ),
                ),
                // Query filter panel
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Query input
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          border: Border(
                              left: BorderSide(
                                  color: Colors.grey.shade700, width: 1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'QueryString Filter',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: queryController,
                              decoration: InputDecoration(
                                hintText: 'e.g., div.class@, h1@text',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.grey.shade700,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Results
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade900,
                          child: filterResults.value.isEmpty
                              ? Center(
                                  child: Text(
                                    'Enter a QueryString to filter data',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              : Column(
                                  children: [
                                    Text(
                                      '匹配数: ${filterResults.value.length} 最多显示50条',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount:
                                            min(50, filterResults.value.length),
                                        itemBuilder: (context, index) {
                                          final result =
                                              filterResults.value[index];
                                          final type = result['type']
                                              as FilterResultType;
                                          final value =
                                              result['value'] as String;
                                          final isError =
                                              type == FilterResultType.error;
                                          final isHtml =
                                              type == FilterResultType.html;

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isError
                                                  ? Colors.red.shade900
                                                  : isHtml
                                                      ? Colors.green.shade900
                                                      : Colors.blue.shade900,
                                              border: Border.all(
                                                color: isError
                                                    ? Colors.red.shade700
                                                    : isHtml
                                                        ? Colors.green.shade700
                                                        : Colors.blue.shade700,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: SelectableText(
                                                    value,
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 14,
                                                      color: isError
                                                          ? Colors.red.shade200
                                                          : isHtml
                                                              ? Colors
                                                                  .greenAccent
                                                              : Colors
                                                                  .lightBlueAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayContent(PageData pageData, DataViewMode mode) {
    if (mode == DataViewMode.html) {
      return _filterHtml(pageData.html);
    } else {
      // JSON mode
      if (pageData.jsonData != null) {
        try {
          final jsonObj = jsonDecode(pageData.jsonData!);
          const encoder = JsonEncoder.withIndent('  ');
          return encoder.convert(jsonObj);
        } catch (e) {
          return 'Error parsing JSON: $e\n\n${pageData.jsonData}';
        }
      } else {
        return '// No JSON data available\n// This page contains HTML content only';
      }
    }
  }

  String _filterHtmlOnly(String html) {
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

  String _filterHtml(String html) {
    return _formatHtml(_filterHtmlOnly(html));
  }

  String _formatHtml(String html) {
    try {
      final document = html_parser.parse(html);
      final root = document.documentElement ?? document.body;
      if (root == null) return html;
      return _formatElement(root, 0);
    } catch (e) {
      return html;
    }
  }

  String _formatElement(html.Element element, int indent) {
    final buffer = StringBuffer();
    final indentStr = '  ' * indent;
    final tagName = element.localName;

    // Opening tag
    buffer.write('$indentStr<$tagName');

    // Attributes
    if (element.attributes.isNotEmpty) {
      element.attributes.forEach((key, value) {
        buffer.write(' $key="${_escapeHtml(value)}"');
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
        buffer.write(_escapeHtml(text));
        buffer.writeln('</$tagName>');
        return buffer.toString();
      }
    }

    buffer.writeln();

    // Children
    for (final node in element.nodes) {
      if (node.nodeType == html.Node.ELEMENT_NODE) {
        buffer.write(_formatElement(node as html.Element, indent + 1));
      } else if (node.nodeType == html.Node.TEXT_NODE) {
        final text = node.text?.trim() ?? '';
        if (text.isNotEmpty) {
          buffer.writeln('$indentStr  ${_escapeHtml(text)}');
        }
      }
    }

    // Closing tag
    buffer.writeln('$indentStr</$tagName>');

    return buffer.toString();
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

// Collapsible HTML Tree View Widget
class _HtmlTreeView extends StatelessWidget {
  const _HtmlTreeView({required this.document});

  final html.Document? document;

  @override
  Widget build(BuildContext context) {
    if (document == null) {
      return const Center(
        child: Text('No HTML content', style: TextStyle(color: Colors.grey)),
      );
    }

    final root = document!.documentElement ?? document!.body;
    if (root == null) {
      return const Center(
        child: Text('No HTML content', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: _HtmlElementWidget(element: root, depth: 0),
      ),
    );
  }
}

class _HtmlElementWidget extends HookWidget {
  const _HtmlElementWidget({
    required this.element,
    required this.depth,
  });

  final html.Element element;
  final int depth;

  @override
  Widget build(BuildContext context) {
    // Start collapsed for deep nesting to improve initial render performance
    final isExpanded = useState(depth < 3);
    final tagName = element.localName ?? 'unknown';
    final hasChildren = element.children.isNotEmpty;
    final textContent = element.text.trim();
    final hasOnlyText = element.children.isEmpty && textContent.isNotEmpty;
    final childCount = element.children.length;

    // Check if this element has only one child element (for combining)
    final hasSingleChild = childCount == 1;
    final singleChild = hasSingleChild ? element.children.first : null;

    // Always combine single child elements to show structure
    final shouldCombineSingleChild = hasSingleChild && singleChild != null;

    // Get grandchildren count for display
    final grandChildCount = singleChild?.children.length ?? 0;

    // Get single child's text if it has no children
    final singleChildText = singleChild != null && grandChildCount == 0
        ? singleChild.text.trim()
        : '';

    // Calculate combined HTML length to determine if we can show it inline
    String getCombinedHtml() {
      if (!shouldCombineSingleChild) return '';
      final parentTag = tagName;
      final childTag = singleChild.localName ?? '';
      final attrs = element.attributes.entries
          .map((e) => '${e.key}="${e.value}"')
          .join(' ');
      final childAttrs = singleChild.attributes.entries
          .map((e) => '${e.key}="${e.value}"')
          .join(' ');
      final attrsStr = attrs.isNotEmpty ? ' $attrs' : '';
      final childAttrsStr = childAttrs.isNotEmpty ? ' $childAttrs' : '';

      if (grandChildCount == 0 && singleChildText.isNotEmpty) {
        return '<$parentTag$attrsStr><$childTag$childAttrsStr>$singleChildText</$childTag></$parentTag>';
      }
      return '';
    }

    final combinedHtml = getCombinedHtml();
    final canShowInline = combinedHtml.isNotEmpty && combinedHtml.length < 100;

    // Memoize attribute spans to avoid rebuilding on every render
    final attributeSpans = useMemoized(() {
      return element.attributes.entries.map((attr) {
        final truncatedValue = attr.value.length > 50
            ? '${attr.value.substring(0, 50)}...'
            : attr.value;
        return TextSpan(
          children: [
            TextSpan(
              text: ' ${attr.key}',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
            TextSpan(
              text: '="',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            TextSpan(
              text: truncatedValue,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            TextSpan(
              text: '"',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        );
      }).toList();
    }, [element]);

    // Memoize single child attribute spans
    final singleChildAttributeSpans = useMemoized(() {
      if (singleChild == null) return <TextSpan>[];
      return singleChild.attributes.entries.map((attr) {
        final truncatedValue = attr.value.length > 50
            ? '${attr.value.substring(0, 50)}...'
            : attr.value;
        return TextSpan(
          children: [
            TextSpan(
              text: ' ${attr.key}',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
            TextSpan(
              text: '="',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            TextSpan(
              text: truncatedValue,
              style: const TextStyle(color: Colors.greenAccent),
            ),
            TextSpan(
              text: '"',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        );
      }).toList();
    }, [singleChild]);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: depth * 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expand/collapse icon - only clickable (skip for inline combined)
                if (hasChildren && !canShowInline)
                  InkWell(
                    onTap: () => isExpanded.value = !isExpanded.value,
                    child: Icon(
                      isExpanded.value
                          ? Icons.arrow_drop_down
                          : Icons.arrow_right,
                      size: 20,
                      color: Colors.grey.shade400,
                    ),
                  )
                else
                  const SizedBox(width: 20),

                // Opening tag - selectable
                Flexible(
                  child: SelectableText.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      children: [
                        TextSpan(
                          text: '<',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        TextSpan(
                          text: tagName,
                          style: const TextStyle(color: Colors.lightBlueAccent),
                        ),
                        // Attributes
                        ...attributeSpans,
                        TextSpan(
                          text: '>',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                        // Inline text content for simple elements
                        if (hasOnlyText && textContent.length < 60)
                          TextSpan(
                            children: [
                              TextSpan(
                                text: textContent,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              TextSpan(
                                text: '</',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: tagName,
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ),
                              TextSpan(
                                text: '>',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        // Show complete inline HTML if short enough
                        if (canShowInline)
                          TextSpan(
                            children: [
                              TextSpan(
                                text: ' <',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: singleChild?.localName ?? 'unknown',
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ),
                              // Single child attributes
                              ...singleChildAttributeSpans,
                              TextSpan(
                                text: '>',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: singleChildText,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              TextSpan(
                                text: '</',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: singleChild?.localName ?? 'unknown',
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ),
                              TextSpan(
                                text: '></',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: tagName,
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ),
                              TextSpan(
                                text: '>',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        // Combined single child - show partial (for longer content)
                        if (shouldCombineSingleChild && !canShowInline)
                          TextSpan(
                            children: [
                              TextSpan(
                                text: ' <',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              TextSpan(
                                text: singleChild.localName ?? 'unknown',
                                style: const TextStyle(
                                    color: Colors.lightBlueAccent),
                              ),
                              // Single child attributes
                              ...singleChildAttributeSpans,
                              TextSpan(
                                text: '>',
                                style: TextStyle(color: Colors.grey.shade400),
                              ),
                              // Show text content if no grandchildren
                              if (grandChildCount == 0 &&
                                  singleChildText.isNotEmpty)
                                TextSpan(
                                  text: singleChildText.length > 40
                                      ? ' ${singleChildText.substring(0, 40)}...'
                                      : ' $singleChildText',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              // Show grandchildren count if any
                              if (grandChildCount > 0)
                                TextSpan(
                                  text: ' $grandChildCount',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        // Show children count if collapsed and has multiple children
                        if (!isExpanded.value &&
                            hasChildren &&
                            !shouldCombineSingleChild)
                          TextSpan(
                            text: ' [$childCount]',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Children (when expanded) - skip if inline or single child
          if (isExpanded.value &&
              hasChildren &&
              !shouldCombineSingleChild &&
              !canShowInline) ...[
            // Show first 50 children
            ...element.children.take(50).map((child) => _HtmlElementWidget(
                  element: child,
                  depth: depth + 1,
                )),
            // Show summary if there are more than 50 children
            if (element.children.length > 50)
              Padding(
                padding: EdgeInsets.only(left: (depth + 1) * 16.0 + 20),
                child: SelectableText(
                  '... ${element.children.length - 50} more children omitted (total: ${element.children.length})',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.yellow.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],

          // For single child, show grandchildren when expanded (skip if inline)
          if (isExpanded.value &&
              shouldCombineSingleChild &&
              !canShowInline &&
              grandChildCount > 0) ...[
            // Show first 50 grandchildren
            ...singleChild.children
                .take(50)
                .map((grandChild) => _HtmlElementWidget(
                      element: grandChild,
                      depth: depth + 1,
                    )),
            // Show summary if there are more than 50 grandchildren
            if (grandChildCount > 50)
              Padding(
                padding: EdgeInsets.only(left: (depth + 1) * 16.0 + 20),
                child: SelectableText(
                  '... ${grandChildCount - 50} more children omitted (total: $grandChildCount)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.yellow.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],

          // Text content (when expanded and has text)
          if (isExpanded.value && hasOnlyText && textContent.length >= 60)
            Padding(
              padding: EdgeInsets.only(left: (depth + 1) * 16.0 + 20),
              child: SelectableText(
                textContent,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ),

          // Closing tag (when expanded and has children) - skip if inline
          if (isExpanded.value && hasChildren && !canShowInline)
            Padding(
              padding: EdgeInsets.only(left: depth * 16.0 + 20),
              child: SelectableText.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: '</',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    TextSpan(
                      text: tagName,
                      style: const TextStyle(color: Colors.lightBlueAccent),
                    ),
                    TextSpan(
                      text: '>',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    // Show children count at the end for multiple children
                    if (!shouldCombineSingleChild)
                      TextSpan(
                        text: ' [$childCount]',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
