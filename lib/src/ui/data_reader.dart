import 'dart:async';
import 'dart:math';

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
            // ignore: avoid_print
            print('Validation result: isValid=${validation.isValid}, '
                'errors=${validation.errors.length}, '
                'warnings=${validation.warnings.length}, '
                'hasInfo=${validation.info != null}');

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
              // ignore: avoid_print
              print(
                  'Error case - Validation result: isValid=${validation.isValid}, '
                  'errors=${validation.errors.length}, '
                  'warnings=${validation.warnings.length}');
            } catch (validationError) {
              // If validation itself fails, just show the original error
              // ignore: avoid_print
              print('Validation failed: $validationError');
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
                            ? HtmlTreeView(
                                document: parsedDocument,
                              )
                            : JsonTreeView(
                                json: pageData!.jsonData,
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
                      // Filter results
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade900,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // getValue result section
                              if (valueResult.value != null)
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade900
                                        .withValues(alpha: 0.3),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade700,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                            'getValue() Result',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade300,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: SelectableText(
                                            valueResult.value!,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Validation feedback section - show for errors, warnings, OR valid queries with info
                              if (validationResult.value != null &&
                                  (!validationResult.value!.isValid ||
                                      (validationResult.value!.hasWarnings &&
                                          validationResult.value!.info ==
                                              null) ||
                                      validationResult.value!.info !=
                                          null)) ...[
                                // ignore: avoid_print
                                Builder(builder: (context) {
                                  print('Showing validation panel: '
                                      'isValid=${validationResult.value!.isValid}, '
                                      'hasWarnings=${validationResult.value!.hasWarnings}, '
                                      'hasInfo=${validationResult.value!.info != null}');
                                  return const SizedBox.shrink();
                                }),
                                Container(
                                  constraints:
                                      const BoxConstraints(maxHeight: 300),
                                  decoration: BoxDecoration(
                                    color: !validationResult.value!.isValid
                                        ? Colors.red.shade900
                                            .withValues(alpha: 0.3)
                                        : validationResult.value!.hasWarnings
                                            ? Colors.orange.shade900
                                                .withValues(alpha: 0.3)
                                            : Colors.green.shade900
                                                .withValues(alpha: 0.3),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade700,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              !validationResult.value!.isValid
                                                  ? Icons.error
                                                  : validationResult
                                                          .value!.hasWarnings
                                                      ? Icons.warning
                                                      : Icons.info_outline,
                                              size: 14,
                                              color: !validationResult
                                                      .value!.isValid
                                                  ? Colors.red.shade300
                                                  : validationResult
                                                          .value!.hasWarnings
                                                      ? Colors.orange.shade300
                                                      : Colors.green.shade300,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              !validationResult.value!.isValid
                                                  ? 'Query Validation Errors'
                                                  : validationResult
                                                          .value!.hasWarnings
                                                      ? 'Query Warnings'
                                                      : 'Query Structure',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: !validationResult
                                                        .value!.isValid
                                                    ? Colors.red.shade300
                                                    : validationResult
                                                            .value!.hasWarnings
                                                        ? Colors.orange.shade300
                                                        : Colors.green.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.fromLTRB(
                                              8, 0, 8, 8),
                                          child: SelectableText(
                                            validationResult.value!.toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Collection results
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: filterResults.value.isEmpty
                                      ? Center(
                                          child: Text(
                                            validationResult.value != null &&
                                                    !validationResult
                                                        .value!.isValid
                                                ? 'Fix validation errors above to see results'
                                                : 'Enter a QueryString to filter data',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        )
                                      : Column(children: [
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
                                              itemCount: min(50,
                                                  filterResults.value.length),
                                              itemBuilder: (context, index) {
                                                final result =
                                                    filterResults.value[index];
                                                final type = result['type']
                                                    as FilterResultType;
                                                final value =
                                                    result['value'] as String;
                                                final isError = type ==
                                                    FilterResultType.error;
                                                final isHtml = type ==
                                                    FilterResultType.html;

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 8),
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isError
                                                        ? Colors.red.shade900
                                                        : isHtml
                                                            ? Colors
                                                                .green.shade900
                                                            : Colors
                                                                .blue.shade900,
                                                    border: Border.all(
                                                      color: isError
                                                          ? Colors.red.shade700
                                                          : isHtml
                                                              ? Colors.green
                                                                  .shade700
                                                              : Colors.blue
                                                                  .shade700,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: SelectableText(
                                                          value,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'monospace',
                                                            fontSize: 14,
                                                            color: isError
                                                                ? Colors.red
                                                                    .shade200
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
                                        ]),
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
}
