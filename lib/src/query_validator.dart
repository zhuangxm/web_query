import 'dart:convert';

/// Validation rules and constants for query string validation
class ValidationRules {
  static const validSchemes = ['html', 'json', 'url', 'template'];
  static const validOperators = ['++', '||', '>>', '>>>'];
  static const parameterSeparators = ['?', '&'];

  // Levenshtein distance threshold for suggestions
  static const suggestionThreshold = 2;
}

/// Represents a validation error with position and suggestions
class ValidationError {
  final String message;
  final int position;
  final String suggestion;
  final String example;
  final int? queryPartIndex; // Track which query part contains the error

  ValidationError({
    required this.message,
    required this.position,
    this.suggestion = '',
    this.example = '',
    this.queryPartIndex,
  });

  /// Converts error to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'position': position,
      if (suggestion.isNotEmpty) 'suggestion': suggestion,
      if (example.isNotEmpty) 'example': example,
      if (queryPartIndex != null) 'queryPartIndex': queryPartIndex,
    };
  }

  /// Formats the error with query context
  String format(String query) {
    final buffer = StringBuffer();

    // Include query part information if available
    if (queryPartIndex != null) {
      buffer.writeln(
          'Error at position $position (in query part ${queryPartIndex! + 1}): $message');
    } else {
      buffer.writeln('Error at position $position: $message');
    }
    buffer.writeln();

    // Show query snippet with position pointer
    _addQuerySnippet(buffer, query, position);
    buffer.writeln();

    if (suggestion.isNotEmpty) {
      buffer.writeln(suggestion);
    }
    if (example.isNotEmpty) {
      buffer.writeln(example);
    }

    return buffer.toString();
  }

  /// Adds a query snippet with a pointer to the error position
  void _addQuerySnippet(StringBuffer buffer, String query, int pos) {
    // For long queries, show a snippet around the error position
    const snippetRadius = 40; // Characters to show on each side

    int start = 0;
    int end = query.length;
    String prefix = '';
    String suffix = '';

    if (query.length > snippetRadius * 2) {
      start = (pos - snippetRadius).clamp(0, query.length);
      end = (pos + snippetRadius).clamp(0, query.length);

      if (start > 0) prefix = '...';
      if (end < query.length) suffix = '...';
    }

    final snippet = query.substring(start, end);
    final adjustedPos = pos - start;

    buffer.writeln('Query: $prefix$snippet$suffix');

    // Create pointer with proper spacing
    final pointerPrefix = ' ' * 7; // Length of "Query: "
    final pointerSpacing = ' ' * (prefix.length + adjustedPos);
    final pointer = '$pointerPrefix$pointerSpacing^^^';
    buffer.writeln(pointer);
  }
}

/// Represents a validation warning with position and suggestions
class ValidationWarning {
  final String message;
  final int position;
  final String suggestion;
  final int? queryPartIndex; // Track which query part contains the warning

  ValidationWarning({
    required this.message,
    required this.position,
    this.suggestion = '',
    this.queryPartIndex,
  });

  /// Converts warning to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'position': position,
      if (suggestion.isNotEmpty) 'suggestion': suggestion,
      if (queryPartIndex != null) 'queryPartIndex': queryPartIndex,
    };
  }

  /// Formats the warning with query context
  String format(String query) {
    final buffer = StringBuffer();

    // Include query part information if available
    if (queryPartIndex != null) {
      buffer.writeln(
          'Warning at position $position (in query part ${queryPartIndex! + 1}): $message');
    } else {
      buffer.writeln('Warning at position $position: $message');
    }
    buffer.writeln();

    // Show query snippet with position pointer
    _addQuerySnippet(buffer, query, position);
    buffer.writeln();

    if (suggestion.isNotEmpty) {
      buffer.writeln(suggestion);
    }

    return buffer.toString();
  }

  /// Adds a query snippet with a pointer to the warning position
  void _addQuerySnippet(StringBuffer buffer, String query, int pos) {
    // For long queries, show a snippet around the warning position
    const snippetRadius = 40; // Characters to show on each side

    int start = 0;
    int end = query.length;
    String prefix = '';
    String suffix = '';

    if (query.length > snippetRadius * 2) {
      start = (pos - snippetRadius).clamp(0, query.length);
      end = (pos + snippetRadius).clamp(0, query.length);

      if (start > 0) prefix = '...';
      if (end < query.length) suffix = '...';
    }

    final snippet = query.substring(start, end);
    final adjustedPos = pos - start;

    buffer.writeln('Query: $prefix$snippet$suffix');

    // Create pointer with proper spacing
    final pointerPrefix = ' ' * 7; // Length of "Query: "
    final pointerSpacing = ' ' * (prefix.length + adjustedPos);
    final pointer = '$pointerPrefix$pointerSpacing^';
    buffer.writeln(pointer);
  }
}

/// Information about a single query part
class QueryPartInfo {
  final String scheme;
  final String path;
  final Map<String, List<String>> parameters;
  final Map<String, List<String>> transforms;
  final bool isPipe;
  final bool isRequired;

  QueryPartInfo({
    required this.scheme,
    required this.path,
    required this.parameters,
    required this.transforms,
    required this.isPipe,
    required this.isRequired,
  });

  /// Converts query part info to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'scheme': scheme,
      'path': path,
      'parameters': parameters,
      'transforms': transforms,
      'isPipe': isPipe,
      'isRequired': isRequired,
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('$scheme:$path');
    if (parameters.isNotEmpty) {
      buffer.write(' [params: ${parameters.keys.join(", ")}]');
    }
    if (transforms.isNotEmpty) {
      buffer.write(' [transforms: ${transforms.keys.join(", ")}]');
    }
    if (isPipe) buffer.write(' [pipe]');
    if (isRequired) buffer.write(' [required]');
    return buffer.toString();
  }
}

/// Detailed information about a valid query
class QueryInfo {
  final List<QueryPartInfo> parts;
  final List<String> operators;
  final List<String> variables;
  final int totalParts;

  QueryInfo({
    required this.parts,
    required this.operators,
    required this.variables,
    required this.totalParts,
  });

  /// Converts query info to a map for JSON serialization
  Map<String, dynamic> toMap() {
    return {
      'totalParts': totalParts,
      'operators': operators,
      'variables': variables,
      'parts': parts.map((p) => p.toMap()).toList(),
    };
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Query Information:');
    buffer.writeln('  Total parts: $totalParts');
    if (operators.isNotEmpty) {
      buffer.writeln('  Operators: ${operators.join(", ")}');
    }
    if (variables.isNotEmpty) {
      buffer.writeln('  Variables: ${variables.join(", ")}');
    }
    buffer.writeln('  Parts:');
    for (var i = 0; i < parts.length; i++) {
      buffer.writeln('    ${i + 1}. ${parts[i]}');
    }
    return buffer.toString();
  }
}

/// Result of query validation containing errors, warnings, and query info
class ValidationResult {
  final String query;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;
  final QueryInfo? info;

  ValidationResult(this.query, this.errors, this.warnings, {this.info});

  /// Returns true if the query has no errors
  bool get isValid => errors.isEmpty;

  /// Returns true if the query has warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Returns a JSON string representation
  String toJson() {
    return jsonEncode({
      'query': query,
      'isValid': isValid,
      'errors': errors.map((e) => e.toMap()).toList(),
      'warnings': warnings.map((w) => w.toMap()).toList(),
      'info': info?.toMap(),
    });
  }

  @override
  String toString() {
    if (isValid && info != null) {
      // Format query information in a readable way
      return info!.toString();
    } else {
      // Format all errors and warnings with helpful messages
      final buffer = StringBuffer();
      if (errors.isNotEmpty) {
        buffer.writeln('Errors (${errors.length}):');
        for (var error in errors) {
          buffer.writeln(error.format(query));
        }
      }
      if (warnings.isNotEmpty) {
        buffer.writeln('Warnings (${warnings.length}):');
        for (var warning in warnings) {
          buffer.writeln(warning.format(query));
        }
      }
      return buffer.toString();
    }
  }
}

/// Validator for query string syntax
class QueryValidator {
  /// Validates a query string and returns ValidationResult with detailed info
  static ValidationResult validate(String query) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    if (query.isEmpty) {
      return ValidationResult(query, errors, warnings);
    }

    // Split query by operators to get individual parts and track positions
    final parts = _splitQueryParts(query);
    var offset = 0;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final partIndex = i; // Track which query part we're validating

      // Validate scheme for this part
      _validateScheme(part, offset, partIndex, errors);

      // Validate parameters for this part
      _validateParameters(part, offset, partIndex, errors);

      // Validate variables for this part
      _validateVariables(part, offset, partIndex, errors);

      // Update offset for next part (add part length + operator length)
      offset += part.length;
      if (i < parts.length - 1) {
        // Find the operator that follows this part
        final remainingQuery = query.substring(offset);
        for (var op in ValidationRules.validOperators) {
          if (remainingQuery.startsWith(' $op ')) {
            offset += op.length + 2; // operator + spaces
            break;
          }
        }
      }
    }

    // Validate operators (these span across parts, so no specific part index)
    _validateOperators(query, errors);

    // Detect warnings for edge cases
    _detectWarnings(query, warnings);

    // If validation succeeded, extract query information
    QueryInfo? info;
    if (errors.isEmpty) {
      info = _extractQueryInfo(query);
    }

    return ValidationResult(query, errors, warnings, info: info);
  }

  /// Splits query string into parts by operators
  static List<String> _splitQueryParts(String query) {
    final parts = <String>[];
    var currentPart = StringBuffer();
    var i = 0;

    while (i < query.length) {
      var foundOperator = false;

      // Check for operators
      for (var op in ValidationRules.validOperators) {
        if (i + op.length + 2 <= query.length &&
            query.substring(i, i + op.length + 2) == ' $op ') {
          // Found an operator
          if (currentPart.isNotEmpty) {
            parts.add(currentPart.toString());
            currentPart.clear();
          }
          i += op.length + 2; // Skip operator and spaces
          foundOperator = true;
          break;
        }
      }

      if (!foundOperator) {
        currentPart.write(query[i]);
        i++;
      }
    }

    if (currentPart.isNotEmpty) {
      parts.add(currentPart.toString());
    }

    return parts;
  }

  /// Extracts query information from parsed query parts
  static QueryInfo _extractQueryInfo(String query) {
    // Extract operators from the query
    final operators = _extractOperators(query);

    // Extract variables from the query
    final variables = _extractVariables(query);

    // Split query into parts
    final queryParts = _splitQueryParts(query);

    // Parse each query part to extract detailed information
    final partInfos = <QueryPartInfo>[];
    var isRequired = true; // First part is always required
    var isPipe = false;

    for (var i = 0; i < queryParts.length; i++) {
      final part = queryParts[i];
      final partInfo = _parseQueryPartInfo(part, isRequired, isPipe);
      partInfos.add(partInfo);

      // Determine if next part is required or pipe based on operator
      if (i < operators.length) {
        final nextOp = operators[i];
        isRequired = (nextOp == '++' || nextOp == '>>' || nextOp == '>>>');
        isPipe = (nextOp == '>>' || nextOp == '>>>');
      }
    }

    return QueryInfo(
      parts: partInfos,
      operators: operators,
      variables: variables,
      totalParts: queryParts.length,
    );
  }

  /// Extracts operators from the query string
  static List<String> _extractOperators(String query) {
    final operators = <String>[];
    var i = 0;

    while (i < query.length) {
      // Check for operators with spaces
      for (var op in ValidationRules.validOperators) {
        if (i + op.length + 2 <= query.length &&
            query.substring(i, i + op.length + 2) == ' $op ') {
          operators.add(op);
          i += op.length + 2;
          break;
        }
      }
      i++;
    }

    return operators;
  }

  /// Parses a single query part to extract information
  static QueryPartInfo _parseQueryPartInfo(
      String part, bool isRequired, bool isPipe) {
    // Extract scheme
    var scheme = 'html'; // default
    var path = part;

    final schemeMatch = RegExp(r'^([a-z]+):').firstMatch(part);
    if (schemeMatch != null) {
      scheme = schemeMatch.group(1)!;
      path = part.substring(scheme.length + 1);
    }

    // For template scheme, the entire content is the path
    if (scheme == 'template') {
      return QueryPartInfo(
        scheme: scheme,
        path: path,
        parameters: {},
        transforms: {},
        isPipe: isPipe,
        isRequired: isRequired,
      );
    }

    // Extract parameters and transforms
    final parameters = <String, List<String>>{};
    final transforms = <String, List<String>>{};

    // Find the parameter section (starts with ?)
    final paramIndex = path.indexOf('?');
    if (paramIndex != -1) {
      final pathPart = path.substring(0, paramIndex);
      final paramPart = path.substring(paramIndex + 1);
      path = pathPart;

      // Parse parameters
      final paramPairs = paramPart.split('&');
      for (var pair in paramPairs) {
        if (pair.isEmpty) continue;

        final eqIndex = pair.indexOf('=');
        if (eqIndex != -1) {
          final key = pair.substring(0, eqIndex);
          final value = pair.substring(eqIndex + 1);

          // Categorize as parameter or transform
          const transformKeys = {
            'transform',
            'filter',
            'update',
            'regexp',
            'save',
            'keep',
            'index'
          };
          if (transformKeys.contains(key)) {
            if (transforms.containsKey(key)) {
              transforms[key]!.add(value);
            } else {
              transforms[key] = [value];
            }
          } else {
            if (parameters.containsKey(key)) {
              parameters[key]!.add(value);
            } else {
              parameters[key] = [value];
            }
          }
        } else {
          // Parameter without value (like &keep)
          const transformKeys = {'keep', 'required'};
          if (transformKeys.contains(pair)) {
            transforms[pair] = [''];
          } else {
            parameters[pair] = [''];
          }
        }
      }
    }

    return QueryPartInfo(
      scheme: scheme,
      path: path,
      parameters: parameters,
      transforms: transforms,
      isPipe: isPipe,
      isRequired: isRequired,
    );
  }

  /// Validates scheme syntax, adds errors to list
  static void _validateScheme(
      String part, int offset, int partIndex, List<ValidationError> errors) {
    // Extract scheme prefix using regex
    final schemeMatch = RegExp(r'^([a-z]+):').firstMatch(part);

    if (schemeMatch == null) {
      // Check if there's a scheme-like word without ':'
      final wordMatch = RegExp(r'^([a-z]+)').firstMatch(part);
      if (wordMatch != null) {
        final word = wordMatch.group(1)!;
        // Only report error if the word is close to a valid scheme
        if (_isCloseToValidScheme(word)) {
          errors.add(ValidationError(
            message: 'Missing ":" after scheme "$word"',
            position: offset + word.length,
            suggestion: 'Use: $word:path',
            example:
                'Valid schemes: ${ValidationRules.validSchemes.join(", ")}',
            queryPartIndex: partIndex,
          ));
        }
      }
      return; // No scheme, that's okay (defaults to html)
    }

    final scheme = schemeMatch.group(1)!;
    if (!ValidationRules.validSchemes.contains(scheme)) {
      final suggestion =
          _suggestCorrection(scheme, ValidationRules.validSchemes);
      errors.add(ValidationError(
        message: 'Invalid scheme "$scheme"',
        position: offset,
        suggestion: suggestion.isNotEmpty ? 'Did you mean "$suggestion"?' : '',
        example: 'Valid schemes: ${ValidationRules.validSchemes.join(", ")}',
        queryPartIndex: partIndex,
      ));
    }
  }

  /// Checks if a word is close to a valid scheme (for missing colon detection)
  static bool _isCloseToValidScheme(String word) {
    for (var scheme in ValidationRules.validSchemes) {
      if (_levenshteinDistance(word, scheme) <=
          ValidationRules.suggestionThreshold) {
        return true;
      }
    }
    return false;
  }

  /// Validates parameter syntax, adds errors to list
  static void _validateParameters(
      String part, int offset, int partIndex, List<ValidationError> errors) {
    // Find all ? characters
    final questionMarks = <int>[];
    for (var i = 0; i < part.length; i++) {
      if (part[i] == '?') questionMarks.add(i);
    }

    // If there are multiple ? characters, check if they're properly separated
    if (questionMarks.length > 1) {
      // Check if the second ? is used incorrectly (should be & instead)
      // The first ? starts the parameter section, subsequent ones should be &
      for (var i = 1; i < questionMarks.length; i++) {
        final pos = questionMarks[i];
        // Check if this ? is not part of a valid pattern like ??
        // In most cases, a second ? indicates incorrect parameter syntax
        errors.add(ValidationError(
          message:
              'Multiple "?" found in parameters. Use "&" to separate parameters',
          position: offset + pos,
          suggestion: 'Replace additional "?" with "&"',
          example: 'Example: ?param1=value&param2=value',
          queryPartIndex: partIndex,
        ));
      }
    }
  }

  /// Validates variable syntax, adds errors to list
  static void _validateVariables(
      String part, int offset, int partIndex, List<ValidationError> errors) {
    var depth = 0;
    var lastOpen = -1;

    for (var i = 0; i < part.length; i++) {
      if (i < part.length - 1 && part[i] == '\$' && part[i + 1] == '{') {
        depth++;
        if (lastOpen == -1) lastOpen = i;
        i++; // Skip the {
      } else if (part[i] == '}' && depth > 0) {
        depth--;
        if (depth == 0) lastOpen = -1;
      }
    }

    if (depth > 0) {
      errors.add(ValidationError(
        message: 'Unmatched "\${" in variable syntax',
        position: offset + lastOpen,
        example: 'Variables should be: \${varName}',
        queryPartIndex: partIndex,
      ));
    }
  }

  /// Validates operator usage, adds errors to list
  static void _validateOperators(String query, List<ValidationError> errors) {
    // Track position in query
    var i = 0;

    while (i < query.length) {
      // Check for potential operator sequences
      // Look for sequences that might be operators: +, |, >
      if (i < query.length &&
          (query[i] == '+' || query[i] == '|' || query[i] == '>')) {
        // Extract the potential operator sequence
        final startPos = i;
        var operatorSeq = StringBuffer();

        // Collect consecutive operator characters
        while (i < query.length &&
            (query[i] == '+' || query[i] == '|' || query[i] == '>')) {
          operatorSeq.write(query[i]);
          i++;
        }

        final opStr = operatorSeq.toString();

        // Check if this looks like an operator (has preceding and following space or is at boundary)
        final hasPrecedingSpace = startPos == 0 || query[startPos - 1] == ' ';
        final hasFollowingSpace = i >= query.length || query[i] == ' ';

        // If it has spaces around it, it should be a valid operator
        if (hasPrecedingSpace && hasFollowingSpace) {
          // Check if it's a valid operator
          if (!ValidationRules.validOperators.contains(opStr)) {
            // Try to suggest a correction
            String suggestion = '';
            String example = '';

            // Common mistakes
            if (opStr == '+') {
              suggestion = 'Did you mean "++"?';
              example = 'Use: query1 ++ query2';
            } else if (opStr == '|') {
              suggestion = 'Did you mean "||"?';
              example = 'Use: query1 || query2';
            } else if (opStr == '>') {
              suggestion = 'Did you mean ">>" or ">>>"?';
              example = 'Use: query1 >> query2 or query1 >>> query2';
            } else if (opStr == '+++' || opStr.startsWith('++')) {
              suggestion = 'Did you mean "++"?';
              example = 'Use: query1 ++ query2';
            } else if (opStr == '|||' || opStr.startsWith('||')) {
              suggestion = 'Did you mean "||"?';
              example = 'Use: query1 || query2';
            } else if (opStr == '>>>>' || opStr.length > 3) {
              suggestion = 'Did you mean ">>>" or ">>"?';
              example = 'Use: query1 >>> query2 or query1 >> query2';
            } else {
              suggestion =
                  'Valid operators: ${ValidationRules.validOperators.join(", ")}';
            }

            errors.add(ValidationError(
              message: 'Invalid operator "$opStr"',
              position: startPos,
              suggestion: suggestion,
              example: example,
            ));
          }
        }
      } else {
        i++;
      }
    }
  }

  /// Detects potential issues, adds warnings to list
  static void _detectWarnings(String query, List<ValidationWarning> warnings) {
    // Split query into parts to analyze each one
    final parts = _splitQueryParts(query);
    var offset = 0;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];
      final partIndex = i;

      // Check for regexp patterns
      _validateRegexpPatterns(part, offset, partIndex, warnings);

      // Check for template syntax
      _validateTemplateSyntax(part, offset, partIndex, warnings);

      // Update offset for next part
      offset += part.length;
      if (i < parts.length - 1) {
        final remainingQuery = query.substring(offset);
        for (var op in ValidationRules.validOperators) {
          if (remainingQuery.startsWith(' $op ')) {
            offset += op.length + 2;
            break;
          }
        }
      }
    }
  }

  /// Validates regexp patterns for common escaping issues
  static void _validateRegexpPatterns(String part, int offset, int partIndex,
      List<ValidationWarning> warnings) {
    // Look for regexp transforms in the query part
    // Patterns: ?transform=regexp:... or ?regexp=...
    final regexpMatch =
        RegExp(r'\?(?:transform=)?regexp:([^&\s]+)').firstMatch(part);

    if (regexpMatch == null) return;

    final regexpPattern = regexpMatch.group(1)!;
    final regexpStart =
        offset + regexpMatch.start + regexpMatch.group(0)!.indexOf(':') + 1;

    // Extract the pattern part (before first unescaped /)
    final patternParts = regexpPattern.split(RegExp(r'(?<!\\)/'));
    if (patternParts.isEmpty || patternParts.length < 2) return;

    final pattern =
        patternParts[1]; // First part is empty, second is the pattern

    // Check for common unescaped special characters that might be mistakes
    final specialChars = {
      '.': 'matches any character',
      '*': 'matches 0 or more of previous',
      '+': 'matches 1 or more of previous',
      '?': 'matches 0 or 1 of previous',
      '(': 'starts capture group',
      ')': 'ends capture group',
      '[': 'starts character class',
      ']': 'ends character class',
      '{': 'starts quantifier',
      '}': 'ends quantifier',
      '|': 'alternation (OR)',
      '^': 'matches start of string',
      '\$': 'matches end of string',
    };

    // Check if pattern contains literal-looking text with special chars
    // This is a heuristic: if we see common words with special chars, warn
    for (var entry in specialChars.entries) {
      final char = entry.key;
      final meaning = entry.value;

      // Skip if character is escaped
      if (pattern.contains('\\$char')) continue;

      // Check for unescaped special character
      if (pattern.contains(char)) {
        // Common patterns that are likely intentional - check more carefully
        if (char == '.') {
          // Check if all dots are part of .*, .+, or .?
          var allDotsAreIntentional = true;
          for (var i = 0; i < pattern.length; i++) {
            if (pattern[i] == '.') {
              // Check if followed by *, +, or ?
              if (i + 1 < pattern.length &&
                  (pattern[i + 1] == '*' ||
                      pattern[i + 1] == '+' ||
                      pattern[i + 1] == '?')) {
                continue; // This dot is intentional
              }
              allDotsAreIntentional = false;
              break;
            }
          }
          if (allDotsAreIntentional) continue;
        }
        if (char == '*' && pattern.contains('.*')) continue; // .* is common
        if (char == '+' && pattern.contains('.+')) continue; // .+ is common
        if (char == '?' && pattern.contains('.?')) continue; // .? is common
        if (char == '^' && pattern.startsWith('^'))
          continue; // ^ at start is intentional
        if (char == '\$' && pattern.endsWith('\$'))
          continue; // $ at end is intentional

        // Warn about potentially unescaped special character
        final charPos = pattern.indexOf(char);
        warnings.add(ValidationWarning(
          message: 'Unescaped special character "$char" in regexp pattern',
          position: regexpStart + charPos,
          suggestion:
              'In regex, "$char" $meaning. If you want a literal "$char", use "\\$char"',
          queryPartIndex: partIndex,
        ));
        break; // Only warn once per pattern
      }
    }
  }

  /// Validates template syntax for common mistakes
  static void _validateTemplateSyntax(String part, int offset, int partIndex,
      List<ValidationWarning> warnings) {
    // Check if this is a template scheme
    if (!part.startsWith('template:')) return;

    final templateContent = part.substring('template:'.length);

    // Check for common template mistakes

    // 1. Check for variables that might be missing the $ prefix
    // Look for patterns like {varName} instead of ${varName}
    final bareVariablePattern = RegExp(r'(?<!\$)\{([a-zA-Z_][a-zA-Z0-9_]*)\}');
    final bareMatches = bareVariablePattern.allMatches(templateContent);

    for (var match in bareMatches) {
      final varName = match.group(1)!;
      final pos = offset + 'template:'.length + match.start;

      warnings.add(ValidationWarning(
        message: 'Template variable missing "\$" prefix',
        position: pos,
        suggestion:
            'Use "\${$varName}" instead of "{$varName}" for variable substitution',
        queryPartIndex: partIndex,
      ));
    }

    // 2. Check for malformed variable expressions
    // Look for ${ without proper closing or with invalid content
    final dollarBracePattern = RegExp(r'\$\{([^}]*)\}');
    final dollarMatches = dollarBracePattern.allMatches(templateContent);

    for (var match in dollarMatches) {
      final varContent = match.group(1)!;

      // Check if variable content is empty
      if (varContent.trim().isEmpty) {
        final pos = offset + 'template:'.length + match.start;
        warnings.add(ValidationWarning(
          message: 'Empty template variable',
          position: pos,
          suggestion:
              'Template variables should contain a variable name: \${varName}',
          queryPartIndex: partIndex,
        ));
      }

      // Check for spaces at start/end (might be unintentional)
      if (varContent != varContent.trim() && varContent.trim().isNotEmpty) {
        final pos = offset + 'template:'.length + match.start;
        warnings.add(ValidationWarning(
          message: 'Template variable has leading/trailing whitespace',
          position: pos,
          suggestion:
              'Use "\${${varContent.trim()}}" instead of "\${$varContent}"',
          queryPartIndex: partIndex,
        ));
      }
    }

    // 3. Check for single $ without { (might be intended as variable)
    final singleDollarPattern = RegExp(r'\$(?!\{)([a-zA-Z_][a-zA-Z0-9_]*)');
    final singleMatches = singleDollarPattern.allMatches(templateContent);

    for (var match in singleMatches) {
      final varName = match.group(1);
      if (varName != null && varName.isNotEmpty) {
        final pos = offset + 'template:'.length + match.start;
        warnings.add(ValidationWarning(
          message: 'Possible template variable without braces',
          position: pos,
          suggestion:
              'Use "\${$varName}" instead of "\$$varName" for variable substitution',
          queryPartIndex: partIndex,
        ));
      }
    }
  }

  /// Extracts all variables used in query
  static List<String> _extractVariables(String query) {
    final variables = <String>{};

    // Match ${variable} patterns
    final variablePattern = RegExp(r'\$\{([^}]+)\}');
    final matches = variablePattern.allMatches(query);

    for (var match in matches) {
      final varContent = match.group(1)!;
      // Extract variable names from expressions
      // For simple variables like ${varName}, just add the name
      // For expressions like ${var1 + var2}, extract all identifiers

      // Simple approach: extract all word characters that could be variable names
      final identifiers =
          RegExp(r'[a-zA-Z_][a-zA-Z0-9_]*').allMatches(varContent);
      for (var identifier in identifiers) {
        final varName = identifier.group(0)!;
        // Filter out common function names or keywords that aren't variables
        if (!['true', 'false', 'null'].contains(varName)) {
          variables.add(varName);
        }
      }
    }

    return variables.toList()..sort();
  }

  /// Suggests corrections for common typos
  static String _suggestCorrection(String invalid, List<String> valid) {
    var minDistance = ValidationRules.suggestionThreshold + 1;
    var suggestion = '';

    for (final validOption in valid) {
      final distance = _levenshteinDistance(invalid, validOption);
      if (distance < minDistance) {
        minDistance = distance;
        suggestion = validOption;
      }
    }

    return minDistance <= ValidationRules.suggestionThreshold ? suggestion : '';
  }

  /// Calculates Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // Create a matrix to store distances
    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    // Initialize first row and column
    for (var i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    // Calculate distances
    for (var i = 1; i <= s1.length; i++) {
      for (var j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}
