# Design Document

## Overview

This design adds comprehensive syntax validation to the QueryString class as a **separate, optional method** that users can call manually to get detailed information about syntax issues and warnings. The validation will NOT run automatically during construction or execution, ensuring that bugs in validation logic don't prevent queries from running.

The validation system will check for:
- Invalid or misspelled scheme names
- Malformed parameter syntax (multiple `?` without `&`)
- Unmatched variable syntax (`${}`)
- Invalid operators
- Missing separators (`:` after scheme)
- Common typos with suggestions
- Potential issues (warnings that don't prevent execution)

## Architecture

The validation system will be implemented as a separate, optional method that users can call explicitly:

```
QueryString Constructor
    ↓
Query Parsing (existing)
    ↓
Query Execution (existing)

[Separately, user can call:]
QueryString.validate()
    ↓
Returns ValidationResult
    - errors: List<ValidationError>
    - warnings: List<ValidationWarning>
    - isValid: bool
```

### Validation Flow

When user calls `queryString.validate()`:

1. **Pre-parse validation**: Check overall structure
2. **Scheme validation**: Verify scheme names and separators
3. **Parameter validation**: Check parameter syntax
4. **Variable validation**: Verify `${}` syntax
5. **Operator validation**: Check operator usage
6. **Warning detection**: Identify potential issues
7. **Result compilation**: Collect all errors and warnings into ValidationResult

## Components and Interfaces

### New Components

#### ValidationResult

A class that holds validation results and query information:

```dart
class ValidationResult {
  final String query;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;
  final QueryInfo? info; // Detailed query information (only when valid)
  
  ValidationResult(this.query, this.errors, this.warnings, {this.info});
  
  bool get isValid => errors.isEmpty;
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
```

#### QueryInfo

A class that holds detailed information about a valid query:

```dart
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
```

#### ValidationError

A class representing a validation error:

```dart
class ValidationError {
  final String message;
  final int position;
  final String suggestion;
  final String example;
  
  ValidationError({
    required this.message,
    required this.position,
    this.suggestion = '',
    this.example = '',
  });
  
  String format(String query) {
    // Format with position, snippet, suggestion, and example
  }
}
```

#### ValidationWarning

A class representing a validation warning:

```dart
class ValidationWarning {
  final String message;
  final int position;
  final String suggestion;
  
  ValidationWarning({
    required this.message,
    required this.position,
    this.suggestion = '',
  });
  
  String format(String query) {
    // Format with position and suggestion
  }
}
```

#### QueryValidator

A new class responsible for validating query string syntax:

```dart
class QueryValidator {
  /// Validates a query string and returns ValidationResult with detailed info
  static ValidationResult validate(String query);
  
  /// Extracts query information from parsed query parts
  static QueryInfo _extractQueryInfo(String query, List<QueryPart> parts);
  
  /// Validates scheme syntax, adds errors to list
  static void _validateScheme(String part, int offset, List<ValidationError> errors);
  
  /// Validates parameter syntax, adds errors to list
  static void _validateParameters(String part, int offset, List<ValidationError> errors);
  
  /// Validates variable syntax, adds errors to list
  static void _validateVariables(String part, int offset, List<ValidationError> errors);
  
  /// Validates operator usage, adds errors to list
  static void _validateOperators(String query, List<ValidationError> errors);
  
  /// Detects potential issues, adds warnings to list
  static void _detectWarnings(String query, List<ValidationWarning> warnings);
  
  /// Extracts all variables used in query
  static List<String> _extractVariables(String query);
  
  /// Suggests corrections for common typos
  static String _suggestCorrection(String invalid, List<String> valid);
  
  /// Calculates Levenshtein distance
  static int _levenshteinDistance(String s1, String s2);
}
```

### Modified Components

#### QueryString Class

Add a new `validate()` method to QueryString:

```dart
class QueryString {
  // Existing fields and constructor (unchanged)
  
  /// Validates the query string syntax and returns detailed results
  /// This method does not affect query execution
  ValidationResult validate() {
    if (query == null || query!.isEmpty) {
      return ValidationResult(query ?? '', [], []);
    }
    return QueryValidator.validate(query!);
  }
}
```

## Data Models

### Validation Rules

The validator will maintain a set of validation rules:

```dart
class ValidationRules {
  static const validSchemes = ['html', 'json', 'url', 'template'];
  static const validOperators = ['++', '||', '>>', '>>>'];
  static const parameterSeparators = ['?', '&'];
  
  // Levenshtein distance threshold for suggestions
  static const suggestionThreshold = 2;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing the acceptance criteria, the following properties provide comprehensive, non-redundant coverage:

### Property 1: Invalid scheme detection

*For any* query string containing a scheme that is not in the valid schemes list, the validator should throw a QueryValidationException with the invalid scheme name and a list of valid schemes.

**Validates: Requirements 1.1**

### Property 2: Parameter syntax validation

*For any* query string containing multiple `?` characters in a single query part, the validator should throw a QueryValidationException indicating the parameter syntax error.

**Validates: Requirements 1.2**

### Property 3: Variable syntax validation

*For any* query string containing unmatched `${` or `}` characters, the validator should throw a QueryValidationException indicating the position of the unmatched bracket.

**Validates: Requirements 1.3**

### Property 4: Operator validation

*For any* query string containing an operator-like sequence that is not in the valid operators list, the validator should throw a QueryValidationException listing valid operators.

**Validates: Requirements 1.4**

### Property 5: Scheme separator validation

*For any* query string where a valid scheme prefix is not followed by `:`, the validator should throw a QueryValidationException indicating the missing separator.

**Validates: Requirements 1.5**

### Property 6: Error position reporting

*For any* validation error, the exception should include the character position or query part index where the error occurred.

**Validates: Requirements 2.1, 2.2**

### Property 7: Typo suggestion

*For any* invalid scheme that is within edit distance 2 of a valid scheme, the validator should suggest the closest valid scheme in the error message.

**Validates: Requirements 3.1**

### Property 8: Validation independence

*For any* query string, calling `validate()` should not affect the ability to execute the query, and validation should not be automatically invoked during construction or execution.

**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

### Property 9: Complete error reporting

*For any* query string with multiple validation errors, the ValidationResult should contain all errors found, not just the first one.

**Validates: Requirements 5.3**

## Error Handling

### ValidationResult Format

The ValidationResult will contain all errors and warnings:

```dart
ValidationResult result = queryString.validate();

if (!result.isValid) {
  print('Found ${result.errors.length} errors:');
  for (var error in result.errors) {
    print(error.format(result.query));
  }
}

if (result.hasWarnings) {
  print('Found ${result.warnings.length} warnings:');
  for (var warning in result.warnings) {
    print(warning.format(result.query));
  }
}
```

### Error Message Format

Individual error messages will follow this format:

```
Error at position {pos}: {message}

Query: {query}
       {pointer to error position}

{suggestion or example}
```

Example:

```
Error at position 15: Invalid scheme 'jsn'

Query: html:div ++ jsn:items
                   ^^^

Did you mean 'json'? Valid schemes are: html, json, url, template
```

### Validation Errors

The validator will catch and report:

1. **Invalid scheme**: Scheme not in valid list
2. **Missing scheme separator**: Scheme without `:`
3. **Multiple `?` in parameters**: Should use `&` for additional parameters
4. **Unmatched `${}`**: Variable syntax error
5. **Invalid operator**: Operator not recognized

### Validation Warnings

The validator will warn about potential issues:

1. **Malformed regexp**: Unescaped special characters
2. **Suspicious patterns**: Patterns that might be typos
3. **Deprecated syntax**: Old syntax that still works but should be updated

### Error Recovery

Since validation is separate from execution:
- Validation errors don't prevent query execution
- Users can choose to ignore validation results
- Bugs in validation logic don't break query execution
- Users can debug validation issues independently

## Testing Strategy

### Unit Testing

Unit tests will verify specific validation scenarios:

1. **Valid queries**: Ensure valid queries pass validation
2. **Invalid schemes**: Test detection of invalid scheme names
3. **Scheme typos**: Test suggestion of correct schemes
4. **Parameter syntax**: Test detection of `?` vs `&` errors
5. **Variable syntax**: Test detection of unmatched `${}`
6. **Operator validation**: Test detection of invalid operators
7. **Missing separators**: Test detection of missing `:`
8. **Error messages**: Verify error message format and content
9. **Position reporting**: Verify error positions are accurate
10. **Multiple errors**: Verify first error is reported

### Property-Based Testing

Property-based tests will verify universal properties using the **test** package with custom generators.

Each property test should run a minimum of 100 iterations to ensure comprehensive coverage.

**Property test requirements:**
- Each property-based test must be tagged with a comment referencing the design document property
- Tag format: `// Feature: query-validation, Property N: <property text>`
- Each correctness property must be implemented by a single property-based test

**Test generators needed:**
- Valid query strings (all schemes, operators, parameters)
- Invalid scheme names (random strings, typos)
- Malformed parameter syntax
- Unmatched variable brackets
- Invalid operators

**Property tests to implement:**

1. **Property 1 test**: Generate random invalid schemes, verify error is in ValidationResult with valid schemes list
2. **Property 2 test**: Generate queries with multiple `?`, verify parameter syntax error in ValidationResult
3. **Property 3 test**: Generate queries with unmatched `${}`, verify variable syntax error in ValidationResult
4. **Property 4 test**: Generate queries with invalid operators, verify operator validation error in ValidationResult
5. **Property 5 test**: Generate queries with schemes missing `:`, verify separator error in ValidationResult
6. **Property 6 test**: Generate various invalid queries, verify error position is accurate in ValidationResult
7. **Property 7 test**: Generate typos of valid schemes, verify suggestions are provided in ValidationResult
8. **Property 8 test**: Generate invalid queries, verify they can still be executed (validation doesn't prevent execution)
9. **Property 9 test**: Generate queries with multiple errors, verify all errors are reported in ValidationResult

### Integration Testing

Integration tests will verify validation works with real-world query patterns:
- Complex multi-part queries
- Queries with all operators
- Queries with variables and templates
- Queries with regexp transforms
- Edge cases from user reports

## Implementation Approach

### Solution Design

The validation will be implemented as a separate concern from parsing, allowing it to be:
- Tested independently
- Easily extended with new rules
- Disabled if needed (via flag)

**Implementation phases:**

1. **Phase 1**: Create QueryValidator class with basic structure
2. **Phase 2**: Implement individual validation rules
3. **Phase 3**: Implement error formatting and suggestions
4. **Phase 4**: Integrate into QueryString constructor
5. **Phase 5**: Add comprehensive tests

### Detailed Implementation

#### Scheme Validation

```dart
static void _validateScheme(String part, int offset, List<ValidationError> errors) {
  // Extract scheme prefix
  final schemeMatch = RegExp(r'^([a-z]+):').firstMatch(part);
  
  if (schemeMatch == null) {
    // Check if there's a scheme-like word without ':'
    final wordMatch = RegExp(r'^([a-z]+)').firstMatch(part);
    if (wordMatch != null) {
      final word = wordMatch.group(1)!;
      if (_isCloseToValidScheme(word)) {
        errors.add(ValidationError(
          message: 'Missing ":" after scheme "$word"',
          position: offset + word.length,
          suggestion: 'Use: $word:path',
        ));
      }
    }
    return; // No scheme, that's okay (defaults to html)
  }
  
  final scheme = schemeMatch.group(1)!;
  if (!ValidationRules.validSchemes.contains(scheme)) {
    final suggestion = _suggestCorrection(scheme, ValidationRules.validSchemes);
    errors.add(ValidationError(
      message: 'Invalid scheme "$scheme"',
      position: offset,
      suggestion: suggestion.isNotEmpty 
        ? 'Did you mean "$suggestion"?'
        : '',
      example: 'Valid schemes: ${ValidationRules.validSchemes.join(", ")}',
    ));
  }
}
```

#### Parameter Validation

```dart
static void _validateParameters(String part, int offset, List<ValidationError> errors) {
  // Find all ? characters
  final questionMarks = <int>[];
  for (var i = 0; i < part.length; i++) {
    if (part[i] == '?') questionMarks.add(i);
  }
  
  if (questionMarks.length > 1) {
    // Check if they're properly separated by &
    final paramSection = part.substring(questionMarks[0]);
    if (paramSection.contains('?') && !paramSection.substring(1).startsWith('?')) {
      errors.add(ValidationError(
        message: 'Multiple "?" found in parameters. Use "&" to separate parameters',
        position: offset + questionMarks[1],
        example: 'Example: ?param1=value&param2=value',
      ));
    }
  }
}
```

#### Variable Validation

```dart
static void _validateVariables(String part, int offset, List<ValidationError> errors) {
  var depth = 0;
  var lastOpen = -1;
  
  for (var i = 0; i < part.length - 1; i++) {
    if (part[i] == '\$' && part[i + 1] == '{') {
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
    ));
  }
}
```

#### Typo Suggestion (Levenshtein Distance)

```dart
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

static int _levenshteinDistance(String s1, String s2) {
  // Standard Levenshtein distance algorithm
  // ... implementation
}
```

### Alternative Approaches Considered

1. **Validation during parsing**: Rejected because it mixes concerns and makes testing harder
2. **Regex-based validation**: Rejected because it's less flexible and harder to provide good error messages
3. **Optional validation flag**: Considered for performance, but validation is fast enough to always enable
4. **Warning system instead of errors**: Rejected because syntax errors should fail fast

## Dependencies

- No new external dependencies required
- Uses existing Dart core libraries (RegExp, String manipulation)
- Integrates with existing QueryString class

## Performance Considerations

- Validation adds minimal overhead (< 1ms for typical queries)
- Validation is O(n) where n is query string length
- Results are not cached (validation happens once per QueryString construction)
- For very long queries (> 10KB), validation may take a few milliseconds

## Backward Compatibility

- **No breaking changes**: Validation is opt-in and doesn't affect query execution
- **Additive API**: Only adds new `validate()` method to QueryString
- **Safe to adopt**: Users can start using validation without changing existing code
- **Gradual migration**: Users can validate queries in development/testing without affecting production

### Usage Examples

1. **Development/debugging with errors**:
   ```dart
   final query = QueryString('jsn:items?save=x?keep');
   final result = query.validate();
   
   if (!result.isValid) {
     print('Query has errors:');
     print(result); // Human-readable format
     // Or get JSON:
     print(result.toJson());
   }
   ```
   
   Output:
   ```
   Errors (2):
   Error at position 0: Invalid scheme 'jsn'
   
   Query: jsn:items?save=x?keep
          ^^^
   
   Did you mean 'json'? Valid schemes: html, json, url, template
   
   Error at position 16: Multiple "?" found in parameters
   
   Query: jsn:items?save=x?keep
                           ^
   
   Example: ?param1=value&param2=value
   ```

2. **Development/debugging with valid query**:
   ```dart
   final query = QueryString('json:items?save=x&keep ++ template:\${x}');
   final result = query.validate();
   
   if (result.isValid) {
     print('Query is valid!');
     print(result); // Shows query information
     // Or get JSON:
     print(result.toJson());
   }
   ```
   
   Output:
   ```
   Query Information:
     Total parts: 2
     Operators: ++
     Variables: x
     Parts:
       1. json:items [params: save, keep]
       2. template:${x}
   ```

3. **Testing**:
   ```dart
   test('query syntax is valid', () {
     final query = QueryString(myQueryString);
     final result = query.validate();
     expect(result.isValid, isTrue);
     expect(result.info!.totalParts, equals(3));
   });
   ```

4. **Production** (optional):
   ```dart
   final query = QueryString(userInput);
   // Optionally validate in production
   if (debugMode) {
     final result = query.validate();
     if (result.hasWarnings) {
       logger.warn('Query warnings: ${result.toJson()}');
     }
   }
   // Execute regardless of validation
   final data = query.execute(node);
   ```

5. **API/logging**:
   ```dart
   final query = QueryString(userQuery);
   final result = query.validate();
   
   // Send to API or log as JSON
   await api.logQuery(result.toJson());
   ```
