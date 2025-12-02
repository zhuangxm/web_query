import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' as html_parser;
import 'package:logging/logging.dart';
import 'package:web_query/query.dart';

import 'html_tree_view.dart';
import 'html_utils.dart';
import 'json_tree_view.dart';

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
    final valueResult = useState<String?>(null);
    final validationResult = useState<ValidationResult?>(null);
    final fontSizeScale = useState(1.0);
    final showSingleValue = useState(true);
    final showCollection = useState(true);

    // Memoize filtered HTML to avoid re-parsing on every rebuild
    final filteredHtml = useMemoized(
      () => pageData != null ? filterHtmlOnly(pageData!.html) : '',
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
            valueResult.value = null;
            return;
          }

          try {
            final queryString = QueryString(query);
            final root = pageData!.getRootElement();

            // Get simplified value result
            final value = queryString.getValue(root, separator: " ");
            valueResult.value = value;

            // Always validate to show query structure
            final validation = queryString.validate();
            validationResult.value = validation;

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
              // Empty result
              filterResults.value = [];
            }
          } catch (e) {
            // Error occurred - validate query to show helpful feedback
            try {
              final queryString = QueryString(query);
              final validation = queryString.validate();
              validationResult.value = validation;
            } catch (validationError) {
              validationResult.value = null;
            }

            filterResults.value = [
              {'type': FilterResultType.error, 'value': 'Error: $e'}
            ];
            valueResult.value = 'Error: $e';
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
          _DataReaderHeader(
            title: title,
            viewMode: viewMode,
            fontSizeScale: fontSizeScale,
            onToggleExpand: onToggleExpand,
          ),
          _QueryInput(
            controller: queryController,
            fontSizeScale: fontSizeScale.value,
          ),
          Expanded(
            child: _ResizableSplitView(
              left: Container(
                color: Colors.grey.shade800,
                child: pageData == null
                    ? const Center(
                        child: Text(
                          'No data loaded',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : viewMode.value == DataViewMode.html
                        ? HtmlTreeView(
                            document: parsedDocument,
                          )
                        : JsonTreeView(
                            json: pageData!.jsonData,
                          ),
              ),
              right: _FilterResultsView(
                valueResult: valueResult.value,
                filterResults: filterResults.value,
                validationResult: validationResult.value,
                fontSizeScale: fontSizeScale.value,
                showSingleValue: showSingleValue,
                showCollection: showCollection,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataReaderHeader extends StatelessWidget {
  const _DataReaderHeader({
    required this.title,
    required this.viewMode,
    required this.fontSizeScale,
    this.onToggleExpand,
  });

  final String title;
  final ValueNotifier<DataViewMode> viewMode;
  final ValueNotifier<double> fontSizeScale;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
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
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              side: WidgetStateProperty.all(BorderSide.none),
            ),
          ),
          const Spacer(),
          // Font size controls
          IconButton(
            icon: const Icon(Icons.remove, size: 16, color: Colors.white),
            onPressed: () {
              fontSizeScale.value = (fontSizeScale.value - 0.1).clamp(0.5, 2.0);
            },
            tooltip: 'Decrease font size',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '${(fontSizeScale.value * 100).round()}%',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: Colors.white),
            onPressed: () {
              fontSizeScale.value = (fontSizeScale.value + 0.1).clamp(0.5, 2.0);
            },
            tooltip: 'Increase font size',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 8),
          if (onToggleExpand != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: Colors.white),
              onPressed: onToggleExpand,
              tooltip: 'Close Data Reader',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _QueryInput extends StatelessWidget {
  const _QueryInput({
    required this.controller,
    required this.fontSizeScale,
  });

  final TextEditingController controller;
  final double fontSizeScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Query:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g., div.class@text, script@text?transform=json',
                hintStyle: TextStyle(
                  fontSize: 15 * fontSizeScale,
                  fontFamily: "monospace",
                  fontFamilyFallback: const [
                    'Menlo',
                    'Monaco',
                    'Courier New',
                    'Courier',
                    'monospace'
                  ],
                  color: Colors.grey.shade500,
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade700,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: const [
                  'Menlo',
                  'Monaco',
                  'Courier New',
                  'Courier',
                  'monospace'
                ],
                fontSize: 15 * fontSizeScale,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterResultsView extends StatelessWidget {
  const _FilterResultsView({
    required this.valueResult,
    required this.filterResults,
    required this.validationResult,
    required this.fontSizeScale,
    required this.showSingleValue,
    required this.showCollection,
  });

  final String? valueResult;
  final List<Map<String, dynamic>> filterResults;
  final ValidationResult? validationResult;
  final double fontSizeScale;
  final ValueNotifier<bool> showSingleValue;
  final ValueNotifier<bool> showCollection;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey.shade800,
            child: Row(
              children: [
                Text(
                  'Results',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Toggle buttons
                IconButton(
                  icon: Icon(
                    showSingleValue.value
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    showSingleValue.value = !showSingleValue.value;
                  },
                  tooltip: 'Toggle single value',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                Text(
                  'Single',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    showCollection.value
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    showCollection.value = !showCollection.value;
                  },
                  tooltip: 'Toggle collection',
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                Text(
                  'List',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. getValue result section
                  if (valueResult != null && showSingleValue.value)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade900.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.blue.shade800,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.text_fields,
                                size: 14,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Single Value',
                                style: TextStyle(
                                  fontSize: 11 * fontSizeScale,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            valueResult!,
                            style: TextStyle(
                              fontSize: 15 * fontSizeScale,
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontFamilyFallback: const [
                                'Menlo',
                                'Monaco',
                                'Courier New',
                                'Courier',
                                'monospace'
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 2. Collection results
                  if (filterResults.isNotEmpty && showCollection.value) ...[
                    Text(
                      'Matches: ${filterResults.length} (showing top 50)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11 * fontSizeScale,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...filterResults.take(50).map((result) {
                      final type = result['type'] as FilterResultType;
                      final value = result['value'] as String;
                      final isError = type == FilterResultType.error;
                      final isHtml = type == FilterResultType.html;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isError
                              ? Colors.red.shade900.withValues(alpha: 0.3)
                              : isHtml
                                  ? Colors.green.shade900.withValues(alpha: 0.3)
                                  : Colors.grey.shade800,
                          border: Border.all(
                            color: isError
                                ? Colors.red.shade700
                                : isHtml
                                    ? Colors.green.shade700
                                    : Colors.grey.shade700,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          value,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontFamilyFallback: const [
                              'Menlo',
                              'Monaco',
                              'Courier New',
                              'Courier',
                              'monospace'
                            ],
                            fontSize: 14 * fontSizeScale,
                            color: isError
                                ? Colors.red.shade200
                                : isHtml
                                    ? Colors.greenAccent
                                    : Colors.lightBlueAccent,
                          ),
                        ),
                      );
                    }),
                  ],

                  // 3. Validation feedback
                  if (validationResult != null &&
                      (!validationResult!.isValid ||
                          validationResult!.hasWarnings ||
                          validationResult!.info != null))
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: !validationResult!.isValid
                            ? Colors.red.shade900.withValues(alpha: 0.2)
                            : Colors.orange.shade900.withValues(alpha: 0.2),
                        border: Border.all(
                          color: !validationResult!.isValid
                              ? Colors.red.shade800
                              : Colors.orange.shade800,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !validationResult!.isValid
                                ? 'Validation Errors'
                                : 'Debug Info',
                            style: TextStyle(
                              fontSize: 11 * fontSizeScale,
                              fontWeight: FontWeight.bold,
                              color: !validationResult!.isValid
                                  ? Colors.red.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            validationResult!.toString(),
                            style: TextStyle(
                              fontSize: 13 * fontSizeScale,
                              color: Colors.white70,
                              fontFamily: 'monospace',
                              fontFamilyFallback: const [
                                'Menlo',
                                'Monaco',
                                'Courier New',
                                'Courier',
                                'monospace'
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Empty state
                  if (valueResult == null && filterResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(
                        child: Text(
                          'Enter a query to see results',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13 * fontSizeScale,
                          ),
                        ),
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

class _ResizableSplitView extends HookWidget {
  const _ResizableSplitView({
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final ratio = useState(0.5);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final leftWidth = width * ratio.value;

        return Row(
          children: [
            SizedBox(
              width: leftWidth,
              child: left,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                final newRatio = (leftWidth + details.delta.dx) / width;
                ratio.value = newRatio.clamp(0.2, 0.8);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 8,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Container(
                    width: 2,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: right,
            ),
          ],
        );
      },
    );
  }
}
