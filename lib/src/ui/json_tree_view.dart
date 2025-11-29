import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class JsonTreeView extends StatelessWidget {
  const JsonTreeView({super.key, required this.json});

  final dynamic json;

  @override
  Widget build(BuildContext context) {
    if (json == null) {
      return const Center(
        child: Text('No JSON data', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: JsonNodeWidget(
          keyName: 'root',
          value: json,
          depth: 0,
          isRoot: true,
        ),
      ),
    );
  }
}

class JsonNodeWidget extends HookWidget {
  const JsonNodeWidget({
    super.key,
    required this.keyName,
    required this.value,
    required this.depth,
    this.isRoot = false,
  });

  final String keyName;
  final dynamic value;
  final int depth;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    // Start collapsed for deep nesting
    final isExpanded = useState(depth < 2);
    final showMoreCount = useState(50);

    if (value is Map) {
      final map = value as Map;
      final keys = map.keys.toList();
      final count = keys.length;
      final isEmpty = count == 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            isExpanded: isExpanded,
            type: '{ }',
            count: count,
            isEmpty: isEmpty,
          ),
          if (isExpanded.value && !isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...keys.take(showMoreCount.value).map((key) {
                    return JsonNodeWidget(
                      keyName: key.toString(),
                      value: map[key],
                      depth: depth + 1,
                    );
                  }),
                  if (count > showMoreCount.value)
                    _buildShowMore(context, showMoreCount, count),
                ],
              ),
            ),
        ],
      );
    } else if (value is List) {
      final list = value as List;
      final count = list.length;
      final isEmpty = count == 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            isExpanded: isExpanded,
            type: '[ ]',
            count: count,
            isEmpty: isEmpty,
          ),
          if (isExpanded.value && !isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...list
                      .take(showMoreCount.value)
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
                    return JsonNodeWidget(
                      keyName: '[${entry.key}]',
                      value: entry.value,
                      depth: depth + 1,
                    );
                  }),
                  if (count > showMoreCount.value)
                    _buildShowMore(context, showMoreCount, count),
                ],
              ),
            ),
        ],
      );
    } else {
      // Primitive value
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SelectableText.rich(
          TextSpan(
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            children: [
              if (!isRoot)
                TextSpan(
                  text: '$keyName: ',
                  style: TextStyle(color: Colors.purple.shade200),
                ),
              _getValueSpan(value),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildHeader(
    BuildContext context, {
    required ValueNotifier<bool> isExpanded,
    required String type,
    required int count,
    required bool isEmpty,
  }) {
    return InkWell(
      onTap: isEmpty ? null : () => isExpanded.value = !isExpanded.value,
      hoverColor: Colors.white.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEmpty)
              Icon(
                isExpanded.value ? Icons.arrow_drop_down : Icons.arrow_right,
                size: 18,
                color: Colors.grey.shade400,
              )
            else
              const SizedBox(width: 18),
            SelectableText.rich(
              TextSpan(
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                children: [
                  if (!isRoot)
                    TextSpan(
                      text: '$keyName: ',
                      style: TextStyle(color: Colors.purple.shade200),
                    ),
                  TextSpan(
                    text: type,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (!isExpanded.value || isEmpty)
                    TextSpan(
                      text: ' $count items',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowMore(
      BuildContext context, ValueNotifier<int> showMoreCount, int total) {
    return InkWell(
      onTap: () {
        showMoreCount.value += 50;
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Show more (${total - showMoreCount.value} remaining)...',
          style: TextStyle(
            color: Colors.blue.shade300,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  TextSpan _getValueSpan(dynamic value) {
    if (value == null) {
      return TextSpan(
        text: 'null',
        style:
            TextStyle(color: Colors.red.shade300, fontWeight: FontWeight.bold),
      );
    } else if (value is num) {
      return TextSpan(
        text: value.toString(),
        style: TextStyle(color: Colors.orange.shade300),
      );
    } else if (value is bool) {
      return TextSpan(
        text: value.toString(),
        style:
            TextStyle(color: Colors.blue.shade300, fontWeight: FontWeight.bold),
      );
    } else {
      return TextSpan(
        text: '"$value"',
        style: TextStyle(color: Colors.green.shade300),
      );
    }
  }
}
