import 'package:function_tree/function_tree.dart';
import 'package:web_query/src/resolver/common.dart';

class VariableResolver implements Resolver {
  final Map<String, dynamic> variables;

  VariableResolver(this.variables);

  static Map<String, dynamic> defaultVariable = {};

  @override
  String toString() {
    return variables.toString();
  }

  String _resolveString(String input, Map<String, dynamic> variables) {
    // if (variables.isEmpty) return input; // Removed for debugging
    // Match ${expression}
    return input.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (match) {
      var expression = match.group(1)!;
      try {
        // Replace variables in expression with their values
        // We sort keys by length descending to avoid partial replacements (e.g. replacing 'id' in 'idx')
        final sortedKeys = variables.keys.toList()
          ..sort((a, b) => b.length.compareTo(a.length));

        for (final key in sortedKeys) {
          if (expression.contains(key)) {
            final value = variables[key];
            // Only replace if it looks like a variable (simple check)
            // function_tree supports variables but we need to pass them or substitute them.
            // Substituting is safer for now as function_tree interprets strings.
            // But we need to be careful about string values vs numbers.
            // If value is number, just put it in. If string, quote it?
            // function_tree is mainly for math.

            // Better approach: Check if expression is JUST a variable name first
            if (expression == key) {
              return value.toString();
            }

            if (value is num) {
              expression = expression.replaceAll(key, value.toString());
            } else if (value is String) {
              final numValue = num.tryParse(value);
              if (numValue != null) {
                expression = expression.replaceAll(key, numValue.toString());
              }
            }
          }
        }

        // If we replaced variables, or if the expression is just numbers, try to interpret
        // If it's a string concatenation like "prefix" + id, function_tree might not handle it if it expects math.
        // function_tree 0.9.0 supports some functions but mainly math.

        // Let's try to interpret.
        final result = expression.interpret();

        // If result is integer (ends with .0), convert to int string
        if (result is double && result == result.truncateToDouble()) {
          return result.toInt().toString();
        }
        return result.toString();
      } catch (e) {
        // Fallback: if interpretation fails (e.g. string operations not supported by function_tree),
        // check if it's a simple variable lookup
        if (variables.containsKey(expression)) {
          return variables[expression].toString();
        }

        // Handle string concatenation manually if function_tree failed
        if (expression.contains('+')) {
          // Simple string concatenation support
          // Split by + and concatenate parts
          // We need to be careful about quoted strings vs variables
          // For now, let's just support simple variable + string or variable + variable
          // This is a very basic implementation to support the user's request
          try {
            final parts = expression.split('+');
            final sb = StringBuffer();
            for (var part in parts) {
              part = part.trim();
              // Check if it's a quoted string
              if ((part.startsWith("'") && part.endsWith("'")) ||
                  (part.startsWith('"') && part.endsWith('"'))) {
                sb.write(part.substring(1, part.length - 1));
              } else if (variables.containsKey(part)) {
                sb.write(variables[part]);
              } else if (double.tryParse(part) != null) {
                // It's a number
                sb.write(part);
              } else {
                // Assume it's a string literal without quotes if it's not a variable?
                // No, that's dangerous. But for "prefix + 1", "prefix" was replaced by "test".
                // So expression is "test + 1".
                // "test" is not in variables (it IS the value).
                // So we just append it.
                sb.write(part);
              }
            }
            return sb.toString();
          } catch (e) {
            // Ignore and return original
          }
        }

        // But function_tree throws on strings.

        return match.group(0)!;
      }
    });
  }

  @override
  dynamic resolve(dynamic value, {Map<String, dynamic>? params}) {
    return _resolveString(value, {...defaultVariable, ...params ?? variables});
  }
}
