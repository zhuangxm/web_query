import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:html/dom.dart' as html;

// Collapsible HTML Tree View Widget
class HtmlTreeView extends StatelessWidget {
  const HtmlTreeView({super.key, required this.document});

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
        child: HtmlElementWidget(element: root, depth: 0),
      ),
    );
  }
}

class HtmlElementWidget extends HookWidget {
  const HtmlElementWidget({
    super.key,
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
                                    fontStyle: FontStyle.italic,
                                    fontSize: 10,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Children
          if (isExpanded.value && !canShowInline && hasChildren)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: element.children
                    .map((child) => HtmlElementWidget(
                          element: child,
                          depth: depth + 1,
                        ))
                    .toList(),
              ),
            ),
          // Closing tag (only if not inline and not simple text)
          if (isExpanded.value && !canShowInline && !hasOnlyText && hasChildren)
            Padding(
              padding: EdgeInsets.only(left: depth * 16.0 + 20),
              child: SelectableText.rich(
                TextSpan(
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
                  ],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
