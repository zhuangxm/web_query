# Query Validation Guide

This guide provides comprehensive information about the query validation system in Web Query.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Validation API](#validation-api)
- [Error Types](#error-types)
- [Common Mistakes](#common-mistakes)
- [Best Practices](#best-practices)
- [Integration Examples](#integration-examples)

## Overview

The Web Query validation system helps you catch syntax errors before they cause runtime issues. Validation is **optional** and **separate** from query execution, ensuring that:

- Validation bugs don't prevent queries from running
- You can validate in development but skip in production
- You get detailed error messages with suggestions
- All errors are reported, not just the first one

## Quick Start

### Basic Validation

```dart
import 'package:web_query/query.dart';

// Create a query
final query = QueryString('json:items?save=x&keep ++ template:${x}');

// Validate it
final result = query.validate();

// Check if valid
if (result.isValid) {
  print('✓ Query is valid');
  print(result.info); // Detailed query information
} else {
  print('✗ Query has errors:');
  for (var error in result.errors) {
    print(error.format(result.query));
  }
}
```

### Validation in Tests

```dart
test('query syntax is valid', () {
  final query = QueryString('json:user/name ++ json:user/email');
  final result = query.validate();
  
  expect(result.isValid, isTrue);
  expect(result.info!.totalParts, equals(2));
  expect(result.info!.operators, equals(['++']));
});
```

## Validation API

### ValidationResult

The `validate()` method returns a `ValidationResult` object:

```dart
class ValidationResult {
  final String query;                    // Original query string
  final List<ValidationError> errors;    // All errors found
  final List<ValidationWarning> warnings; // Potential issues
  final QueryInfo? info;                 // Query details (when valid)
  
  bool get isValid;                      // True if no errors
  bool get hasWarnings;                  // True if warnings exist
  
  String toString();                     // Human-readable format
  String toJson();                       // JSON format
}
```

### ValidationError

Each error contains:

```dart
class ValidationError {
  final String message;      // Error description
  final int position;        // Character position in query
  final String suggestion;   // Suggested fix (if available)
  final String example;      // Example of correct syntax
  
  String format(String query); // Formatted error message
}
```

### ValidationWarning

Warnings indicate potential issues that don't prevent execution:

```dart
class ValidationWarning {
  final String message;      // Warning description
  final int position;        // Character position in query
  final String suggestion;   // Suggested improvement
  
  String format(String query); // Formatted warning message
}
```

### QueryInfo

For valid queries, detailed information is provided:

```dart
class QueryInfo {
  final List<QueryPartInfo> parts;  // Individual query parts
  final List<String> operators;     // Operators used (++, ||, >>, >>>)
  final List<String> variables;     // Variables referenced (${var})
  final int totalParts;             // Number of query parts
  
  String toString();                // Human-readable format
  Map<String, dynamic> toMap();     // Map representation
}
```

### QueryPartInfo

Each query part contains:

```dart
class QueryPartInfo {
  final String scheme;                        // html, json, url, template
  final String path;                          // Selector or path
  final Map<String, List<String>> parameters; // Query parameters
  final Map<String, List<String>> transforms; // Transforms applied
  final bool isPipe;                          // Is this a pipe operation?
  final bool isRequired;                      // Is this required (++)?
  
  String toString();                          // Human-readable format
  Map<String, dynamic> toMap();               // Map representation
}
```

## Error Types

### 1. Invalid Scheme

**Cause:** Scheme name is not in the valid list (`html`, `json`, `url`, `template`)

**Example:**
```dart
// ❌ Invalid
QueryString('jsn:items')
QueryString('htm:div')
QueryString('templ:${x}')

// ✓ Valid
QueryString('json:items')
QueryString('html:div')
QueryString('template:${x}')
```

**Error Message:**
```
Error at position 0: Invalid scheme 'jsn'

Query: jsn:items
       ^^^

Did you mean 'json'? Valid schemes are: html, json, url, template
```

### 2. Missing Scheme Separator

**Cause:** Scheme prefix without `:` separator

**Example:**
```dart
// ❌ Invalid
QueryString('json items')
QueryString('html div')

// ✓ Valid
QueryString('json:items')
QueryString('html:div')
```

**Error Message:**
```
Error at position 4: Missing ":" after scheme "json"

Query: json items
           ^

Use: json:items
```

### 3. Parameter Syntax Error

**Cause:** Multiple `?` characters without `&` separators

**Example:**
```dart
// ❌ Invalid
QueryString('json:items?save=x?keep')
QueryString('div/@text?transform=upper?filter=test')

// ✓ Valid
QueryString('json:items?save=x&keep')
QueryString('div/@text?transform=upper&filter=test')
```

**Error Message:**
```
Error at position 20: Multiple "?" found in parameters

Query: json:items?save=x?keep
                        ^

Example: ?param1=value&param2=value
```

### 4. Unmatched Variable Syntax

**Cause:** Unclosed `${` or extra `}` in variable syntax

**Example:**
```dart
// ❌ Invalid
QueryString('template:Hello ${name')
QueryString('template:${user/name')
QueryString('json:items/${id')

// ✓ Valid
QueryString('template:Hello ${name}')
QueryString('template:${user}')
QueryString('json:items/${id}')
```

**Error Message:**
```
Error at position 22: Unmatched "${" in variable syntax

Query: template:Hello ${name
                      ^^

Variables should be: ${varName}
```

### 5. Invalid Operator

**Cause:** Operator-like sequence that's not in the valid list

**Example:**
```dart
// ❌ Invalid
QueryString('json:a + json:b')
QueryString('json:a & json:b')
QueryString('json:a > json:b')

// ✓ Valid
QueryString('json:a ++ json:b')  // Required (AND)
QueryString('json:a || json:b')  // Fallback (OR)
QueryString('json:a >> json:b')  // Pipe
QueryString('json:a >>> json:b') // Pipe with flatten
```

**Error Message:**
```
Error at position 7: Invalid operator "+"

Query: json:a + json:b
              ^

Valid operators are: ++, ||, >>, >>>
```

## Common Mistakes

### Mistake 1: Typo in Scheme Name

```dart
// ❌ Common typos
'jsn:items'      // Missing 'o'
'htm:div'        // Missing 'l'
'templ:${x}'     // Incomplete
'jason:data'     // Wrong spelling

// ✓ Correct
'json:items'
'html:div'
'template:${x}'
'json:data'
```

**Tip:** The validator suggests the closest valid scheme when it detects a typo.

### Mistake 2: Forgetting the Colon

```dart
// ❌ Missing colon
'json items'
'html div'
'url host'

// ✓ Correct
'json:items'
'html:div'
'url:host'
```

### Mistake 3: Using ? Instead of &

```dart
// ❌ Multiple ? without &
'json:items?save=x?keep'
'div/@text?transform=upper?filter=test'

// ✓ Correct
'json:items?save=x&keep'
'div/@text?transform=upper&filter=test'
```

**Why:** The first `?` starts the parameter section, subsequent parameters use `&`.

### Mistake 4: Unclosed Variables

```dart
// ❌ Unclosed variable
'template:Hello ${name'
'json:items/${id'
'template:${user/name'

// ✓ Correct
'template:Hello ${name}'
'json:items/${id}'
'template:${user}'
```

**Tip:** Always close `${` with `}`.

### Mistake 5: Wrong Operator

```dart
// ❌ Single character operators
'json:a + json:b'   // Use ++
'json:a | json:b'   // Use ||
'json:a > json:b'   // Use >>

// ✓ Correct
'json:a ++ json:b'  // Required (both)
'json:a || json:b'  // Fallback (first available)
'json:a >> json:b'  // Pipe (pass result)
```

## Best Practices

### 1. Validate During Development

```dart
// Always validate complex queries during development
final query = QueryString(complexQueryString);
final result = query.validate();

if (!result.isValid) {
  print('Query errors:');
  print(result);
  return; // Fix before proceeding
}

// Continue with execution
final data = query.execute(node);
```

### 2. Add Validation Tests

```dart
group('Query Validation', () {
  test('user query is valid', () {
    final query = QueryString('json:user/name ++ json:user/email');
    final result = query.validate();
    
    expect(result.isValid, isTrue);
    expect(result.info!.totalParts, equals(2));
  });
  
  test('invalid scheme is caught', () {
    final query = QueryString('jsn:items');
    final result = query.validate();
    
    expect(result.isValid, isFalse);
    expect(result.errors.length, greaterThan(0));
    expect(result.errors[0].message, contains('Invalid scheme'));
  });
});
```

### 3. Log Validation Results

```dart
// Log validation results for monitoring
final query = QueryString(userInput);
final result = query.validate();

if (!result.isValid || result.hasWarnings) {
  logger.info('Query validation', {
    'query': result.query,
    'isValid': result.isValid,
    'errors': result.errors.length,
    'warnings': result.warnings.length,
    'details': result.toJson(),
  });
}
```

### 4. Use JSON Output for APIs

```dart
// Send validation results to monitoring APIs
final query = QueryString(userQuery);
final result = query.validate();

await api.post('/analytics/query-validation', {
  'timestamp': DateTime.now().toIso8601String(),
  'validation': jsonDecode(result.toJson()),
});
```

### 5. Validate User Input

```dart
// Validate user-provided queries before execution
String? validateUserQuery(String userInput) {
  final query = QueryString(userInput);
  final result = query.validate();
  
  if (!result.isValid) {
    // Return first error message
    return result.errors.first.message;
  }
  
  return null; // Valid
}

// In UI
final error = validateUserQuery(textController.text);
if (error != null) {
  showError(error);
  return;
}

// Execute query
executeQuery(textController.text);
```

### 6. Optional Production Validation

```dart
// Validate only in debug mode
final query = QueryString(userInput);

if (kDebugMode) {
  final result = query.validate();
  if (result.hasWarnings) {
    debugPrint('Query warnings: ${result}');
  }
}

// Execute regardless of validation
final data = query.execute(node);
```

## Integration Examples

### Example 1: CLI Tool

```dart
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: query_tool <query>');
    return;
  }
  
  final queryString = args[0];
  final query = QueryString(queryString);
  final result = query.validate();
  
  if (!result.isValid) {
    print('❌ Invalid query:');
    print(result);
    exit(1);
  }
  
  print('✓ Valid query');
  print(result.info);
  
  // Execute query...
}
```

### Example 2: Web API

```dart
@Post('/validate-query')
Future<Response> validateQuery(@Body() Map<String, dynamic> body) async {
  final queryString = body['query'] as String;
  final query = QueryString(queryString);
  final result = query.validate();
  
  return Response.json({
    'valid': result.isValid,
    'errors': result.errors.map((e) => {
      'message': e.message,
      'position': e.position,
      'suggestion': e.suggestion,
    }).toList(),
    'info': result.info?.toMap(),
  });
}
```

### Example 3: Flutter App

```dart
class QueryInputWidget extends StatefulWidget {
  @override
  _QueryInputWidgetState createState() => _QueryInputWidgetState();
}

class _QueryInputWidgetState extends State<QueryInputWidget> {
  final _controller = TextEditingController();
  ValidationResult? _validationResult;
  
  void _validateQuery() {
    final query = QueryString(_controller.text);
    setState(() {
      _validationResult = query.validate();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Query',
            errorText: _validationResult?.isValid == false
                ? _validationResult!.errors.first.message
                : null,
          ),
          onChanged: (_) => _validateQuery(),
        ),
        if (_validationResult?.isValid == true)
          Text('✓ Valid query', style: TextStyle(color: Colors.green)),
        if (_validationResult?.hasWarnings == true)
          Text('⚠ ${_validationResult!.warnings.length} warnings',
              style: TextStyle(color: Colors.orange)),
      ],
    );
  }
}
```

### Example 4: Testing Framework

```dart
/// Helper function for testing query validation
void expectValidQuery(String queryString, {
  int? expectedParts,
  List<String>? expectedOperators,
  List<String>? expectedVariables,
}) {
  final query = QueryString(queryString);
  final result = query.validate();
  
  expect(result.isValid, isTrue,
      reason: 'Query should be valid: ${result}');
  
  if (expectedParts != null) {
    expect(result.info!.totalParts, equals(expectedParts));
  }
  
  if (expectedOperators != null) {
    expect(result.info!.operators, equals(expectedOperators));
  }
  
  if (expectedVariables != null) {
    expect(result.info!.variables, equals(expectedVariables));
  }
}

// Usage in tests
test('complex query validation', () {
  expectValidQuery(
    'json:items?save=x&keep ++ template:${x}',
    expectedParts: 2,
    expectedOperators: ['++'],
    expectedVariables: ['x'],
  );
});
```

### Example 5: Query Builder

```dart
class QueryBuilder {
  final List<String> _parts = [];
  
  QueryBuilder json(String path) {
    _parts.add('json:$path');
    return this;
  }
  
  QueryBuilder html(String selector) {
    _parts.add('html:$selector');
    return this;
  }
  
  QueryBuilder template(String template) {
    _parts.add('template:$template');
    return this;
  }
  
  QueryBuilder required() {
    if (_parts.isNotEmpty) {
      _parts.add('++');
    }
    return this;
  }
  
  QueryBuilder fallback() {
    if (_parts.isNotEmpty) {
      _parts.add('||');
    }
    return this;
  }
  
  String build() {
    return _parts.join(' ');
  }
  
  ValidationResult validate() {
    final query = QueryString(build());
    return query.validate();
  }
}

// Usage
final builder = QueryBuilder()
    .json('user/name')
    .required()
    .json('user/email');

final result = builder.validate();
if (result.isValid) {
  final query = QueryString(builder.build());
  // Execute...
}
```

## Troubleshooting

### Q: Why isn't validation catching my error?

**A:** Validation only checks syntax, not semantic correctness. For example:
- `json:nonexistent/path` is syntactically valid (even if the path doesn't exist)
- `html:.missing-class` is syntactically valid (even if the class doesn't exist)

Validation ensures your query is well-formed, but doesn't guarantee it will return data.

### Q: Can I disable validation?

**A:** Validation is already opt-in. Simply don't call `validate()` and your queries will execute normally.

### Q: Does validation affect performance?

**A:** Validation adds minimal overhead (< 1ms for typical queries). It's fast enough for development and testing, but you can skip it in production if needed.

### Q: What if validation has a bug?

**A:** Since validation is separate from execution, bugs in validation won't prevent your queries from running. Report the bug and continue using queries normally.

### Q: Can I customize validation rules?

**A:** Currently, validation rules are fixed. If you need custom validation, you can:
1. Use the existing validation as a first pass
2. Add your own checks on top of it
3. Submit a feature request for custom rules

## Summary

The validation system provides:

✅ **Comprehensive error detection** - Catches common syntax mistakes  
✅ **Smart suggestions** - Helps you fix errors quickly  
✅ **Detailed query information** - Understand your queries better  
✅ **Optional and safe** - Won't break your queries  
✅ **Multiple output formats** - Human-readable and JSON  
✅ **Complete error reporting** - Shows all errors, not just the first  

Use validation during development and testing to catch issues early, and optionally in production for monitoring and debugging.
