/// Data Transforms - Complex data processing operations
///
/// This module handles sophisticated data transformations including JSON parsing,
/// JavaScript variable extraction, and object updates. These transforms work with
/// structured data and require more complex processing than simple text operations.
///
/// ## Supported Transforms
///
/// ### JSON Transform
/// Parse JSON strings and extract JavaScript variables:
/// - **json** - Parse plain JSON
/// - **json:varName** - Extract specific JavaScript variable
/// - **json:pattern_*** - Extract variables matching wildcard pattern
///
/// ### JavaScript Evaluation
/// Execute JavaScript code and extract variables:
/// - **jseval** - Auto-detect and extract variables
/// - **jseval:varName** - Extract specific variable
/// - **jseval:var1,var2** - Extract multiple variables
///
/// ### Update Transform
/// Merge JSON objects:
/// - **update:{"key":"value"}** - Merge update data into object
///
/// ## Usage Examples
///
/// ### Plain JSON Parsing
/// ```dart
/// final result = applyJsonTransform('{"name":"Alice"}', null);
/// // Returns: {'name': 'Alice'}
/// ```
///
/// ### JavaScript Variable Extraction
/// ```dart
/// final js = 'var config = {"api": "https://api.example.com"};';
/// final result = applyJsonTransform(js, 'config');
/// // Returns: {'api': 'https://api.example.com'}
/// ```
///
/// ### Wildcard Pattern Matching
/// ```dart
/// final js = '''
///   var config_api = "https://api.example.com";
///   var config_key = "abc123";
/// ''';
/// final result = applyJsonTransform(js, 'config_*');
/// // Extracts both config_api and config_key
/// ```
///
/// ### JavaScript Evaluation
/// ```dart
/// JsExecutorRegistry.register(FlutterJsExecutor());
/// final result = applyJsEvalTransform('var x = 42;', 'x');
/// // Returns: 42
/// ```
///
/// ### Object Update
/// ```dart
/// final obj = {'name': 'Alice', 'age': 30};
/// final result = applyUpdate(obj, '{"age": 31, "city": "NYC"}');
/// // Returns: {'name': 'Alice', 'age': 31, 'city': 'NYC'}
/// ```
///
/// ## JavaScript Executor Setup
///
/// JavaScript evaluation requires a registered executor:
///
/// ```dart
/// import 'package:web_query/js.dart';
///
/// // Register the executor once at app startup
/// JsExecutorRegistry.register(FlutterJsExecutor());
///
/// // Now jseval transforms will work
/// final result = applyJsEvalTransform(jsCode, 'variableName');
/// ```
///
/// ## Supported JSON Types
///
/// The JSON transform handles all JSON value types:
/// - Objects: `{"key": "value"}`
/// - Arrays: `[1, 2, 3]`
/// - Strings: `"text"`
/// - Numbers: `42`, `3.14`, `-5`, `1.2e10`
/// - Booleans: `true`, `false`
/// - Null: `null`
///
/// ## Error Handling
///
/// All transforms handle errors gracefully:
/// - Invalid JSON: logs warning, returns null
/// - Missing JS executor: logs warning with setup instructions, returns null
/// - JS execution errors: logs warning, returns null
/// - Invalid update data: logs warning, returns original value
library;

import 'dart:convert' as json;

import 'package:logging/logging.dart';
import 'package:web_query/src/utils.dart/core.dart';

final _log = Logger('QueryString.Transforms.Data');

/// Apply JSON transform to parse JSON strings and extract JavaScript variables
///
/// Parses JSON data or extracts JSON values from JavaScript variable assignments.
/// Supports wildcard patterns for matching multiple variables.
///
/// ## Parameters
///
/// - [value] - The input value (typically a string containing JSON or JavaScript)
/// - [varName] - Optional variable name or pattern to extract from JavaScript
///
/// ## Variable Extraction
///
/// When [varName] is provided, the transform looks for JavaScript variable
/// assignments and extracts the JSON value:
///
/// - **Exact match**: `json:config` matches `var config = {...};`
/// - **Wildcard**: `json:config_*` matches `config_api`, `config_key`, etc.
/// - **Patterns**: Supports `var`, `let`, `const`, and property assignments
///
/// ## Supported Value Types
///
/// - Objects: `{...}`
/// - Arrays: `[...]`
/// - Numbers: integers, decimals, scientific notation
/// - Strings: single or double quoted
/// - Booleans: `true`, `false`
/// - Null: `null`
///
/// ## Returns
///
/// - Parsed JSON value (object, array, primitive, boolean, or null)
/// - null if parsing fails or variable not found
///
/// ## Examples
///
/// ```dart
/// // Plain JSON
/// applyJsonTransform('{"x": 1}', null);  // {'x': 1}
///
/// // Variable extraction
/// applyJsonTransform('var data = [1,2,3];', 'data');  // [1, 2, 3]
///
/// // Wildcard pattern
/// applyJsonTransform('var cfg_a = 1; var cfg_b = 2;', 'cfg_*');
/// // Extracts first match
///
/// // Null handling
/// applyJsonTransform(null, 'var');  // null
/// ```
dynamic applyJsonTransform(dynamic value, String? varName) {
  if (value == null) return null;

  var text = value.toString().trim();

  // If varName is provided, extract the JSON from JavaScript variable assignment
  if (varName != null && varName.isNotEmpty) {
    // Convert wildcard pattern to regex
    // Escape special regex chars except * which becomes .*
    final escapedName = RegExp.escape(varName).replaceAll(r'\*', '.*');

    // Match patterns like: var config = {...}; or window.__DATA__ = {...};
    // Note: JavaScript variables may or may not end with semicolon
    final patterns = [
      // Objects - match with or without semicolon
      RegExp('$escapedName\\s*=\\s*({[\\s\\S]*?})\\s*(?:;|\$)',
          multiLine: false),
      // Arrays - match with or without semicolon
      RegExp('$escapedName\\s*=\\s*(\\[[\\s\\S]*?\\])\\s*(?:;|\$)',
          multiLine: false),
      // Numbers (including decimals, negative, scientific notation)
      RegExp(
          '$escapedName\\s*=\\s*(-?\\d+\\.?\\d*(?:[eE][+-]?\\d+)?)\\s*(?:;|\$)',
          multiLine: false),
      // Strings (single or double quotes)
      RegExp('$escapedName\\s*=\\s*(["\'][\\s\\S]*?["\'])\\s*(?:;|\$)',
          multiLine: false),
      // Booleans
      RegExp('$escapedName\\s*=\\s*(true|false)\\s*(?:;|\$)', multiLine: false),
      // Null
      RegExp('$escapedName\\s*=\\s*(null)\\s*(?:;|\$)', multiLine: false),
    ];

    bool found = false;

    for (var pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        text = match.group(1)!;
        found = true;
        break;
      }
    }

    if (!found) {
      return null;
    }
  }

  return tryParseJson(text);
}

/// Apply update transform to merge JSON objects
///
/// Merges update data into an existing JSON object. The update data overwrites
/// existing keys and adds new keys. Non-object values are returned unchanged.
///
/// ## Parameters
///
/// - [value] - The base object to update (must be a Map)
/// - [updates] - JSON string containing update data
///
/// ## Returns
///
/// - Merged object if value is a Map and updates are valid JSON
/// - Original value if value is not a Map or updates are invalid
///
/// ## Examples
///
/// ```dart
/// final obj = {'name': 'Alice', 'age': 30};
/// applyUpdate(obj, '{"age": 31}');
/// // Returns: {'name': 'Alice', 'age': 31}
///
/// applyUpdate(obj, '{"city": "NYC"}');
/// // Returns: {'name': 'Alice', 'age': 30, 'city': 'NYC'}
///
/// applyUpdate('not an object', '{"x": 1}');
/// // Returns: 'not an object' (unchanged)
/// ```
dynamic applyUpdate(dynamic value, String updates) {
  if (value is! Map) return value;

  try {
    final updateMap = json.jsonDecode(updates);
    return applyUpdateJson(value, updateMap);
  } catch (e) {
    _log.warning('Failed to apply update: $e');
    return value;
  }
}

dynamic applyUpdateJson(dynamic value, Map updateMap) {
  if (value is! Map) return value;

  try {
    return {...value, ...updateMap};
  } catch (e) {
    _log.warning('Failed to apply update: $e');
    return value;
  }
}

/// Apply JavaScript evaluation transform to extract variables from JS code
///
/// Executes JavaScript code using the registered JS executor and extracts
/// specified variables. Requires [JsExecutorRegistry] to be configured.
///
/// ## Parameters
///
/// - [value] - JavaScript code to execute (as string)
/// - [variableNames] - Optional comma-separated list of variable names to extract
///
/// ## Variable Extraction Modes
///
/// - **Auto-detect**: `jseval` - Executor determines which variables to extract
/// - **Single variable**: `jseval:config` - Extract one variable
/// - **Multiple variables**: `jseval:userId,userName` - Extract multiple variables
/// - **Wildcard patterns**: `jseval:flashvars_*` - Extract matching variables
///
/// ## Setup Required
///
/// Before using jseval transforms, register a JS executor:
///
/// ```dart
/// import 'package:web_query/js.dart';
///
/// JsExecutorRegistry.register(FlutterJsExecutor());
/// ```
///
/// ## Returns
///
/// - Extracted variable value(s) as determined by the JS executor
/// - null if executor not configured, execution fails, or value is null/empty
///
/// ## Examples
///
/// ```dart
/// // Setup
/// JsExecutorRegistry.register(FlutterJsExecutor());
///
/// // Single variable
/// applyJsEvalTransform('var x = 42;', 'x');  // 42
///
/// // Multiple variables
/// applyJsEvalTransform('var a = 1; var b = 2;', 'a,b');
/// // Returns structured result with both values
///
/// // Auto-detect
/// applyJsEvalTransform('var config = {...};', null);
/// // Executor determines what to extract
/// ```
///
/// ## Error Handling
///
/// - Missing executor: logs warning with setup instructions, returns null
/// - Execution errors: logs warning, returns null
/// - Empty script: returns null
dynamic applyJsEvalTransform(dynamic value, String? variableNames) {
  if (value == null) return null;

  try {
    // Get JS executor from registry
    final jsExecutor = JsExecutorRegistry.instance;
    if (jsExecutor == null) {
      _log.warning(
          'JavaScript executor not configured. Use: import "package:web_query/js.dart"; configureJsExecutor(FlutterJsExecutor());');
      return null;
    }

    final script = value.toString().trim();
    if (script.isEmpty) return null;

    // Parse variable names if provided
    List<String>? varList;
    if (variableNames != null && variableNames.isNotEmpty) {
      varList = variableNames.split(',').map((e) => e.trim()).toList();
    }

    // Execute JavaScript synchronously using flutter_js
    // flutter_js evaluate() is synchronous, so this works
    final result = jsExecutor.extractVariablesSync(script, varList);

    return result;
  } catch (e) {
    _log.warning('Failed to execute JavaScript: $e');
    return null;
  }
}

/// Registry for JavaScript executor instances
///
/// Provides centralized management of JavaScript executor configuration.
/// Replaces the old global `_jsExecutorInstance` pattern with a cleaner
/// registry-based approach.
///
/// ## Usage
///
/// ### Registration
///
/// Register a JS executor once at application startup:
///
/// ```dart
/// import 'package:web_query/js.dart';
///
/// void main() {
///   // Register the executor
///   JsExecutorRegistry.register(FlutterJsExecutor());
///
///   // Now jseval transforms will work
///   runApp(MyApp());
/// }
/// ```
///
/// ### Checking Configuration
///
/// ```dart
/// if (JsExecutorRegistry.isConfigured) {
///   print('JS executor is ready');
/// } else {
///   print('JS executor not configured');
/// }
/// ```
///
/// ### Testing
///
/// Clear the executor between tests:
///
/// ```dart
/// tearDown(() {
///   JsExecutorRegistry.clear();
/// });
/// ```
///
/// ## Migration from Old API
///
/// The old global pattern has been replaced:
///
/// ```dart
/// // Old (deprecated)
/// setJsExecutorInstance(FlutterJsExecutor());
///
/// // New (preferred)
/// JsExecutorRegistry.register(FlutterJsExecutor());
/// ```
///
/// The old `setJsExecutorInstance()` function still works but is deprecated.
///
/// ## Thread Safety
///
/// This registry uses a static field and is not thread-safe. Register the
/// executor once during application initialization before any concurrent access.
class JsExecutorRegistry {
  static dynamic _instance;

  /// Register a JavaScript executor instance
  static void register(dynamic executor) {
    _instance = executor;
  }

  /// Get the registered JavaScript executor instance
  static dynamic get instance => _instance;

  /// Check if a JavaScript executor is configured
  static bool get isConfigured => _instance != null;

  /// Clear the registered executor (mainly for testing)
  static void clear() {
    _instance = null;
  }
}
