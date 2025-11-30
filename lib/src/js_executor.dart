import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:logging/logging.dart';

final _log = Logger('QueryString.JsExecutor');

/// Abstract interface for JavaScript execution
abstract class JavaScriptExecutor {
  /// Execute JavaScript code and return the result
  Future<dynamic> execute(String script);

  /// Extract variables from JavaScript code (async)
  Future<Map<String, dynamic>> extractVariables(String script,
      {List<String>? variableNames});

  /// Extract variables from JavaScript code (synchronous)
  dynamic extractVariablesSync(String script, List<String>? variableNames);
}

/// Default implementation using flutter_js
class FlutterJsExecutor implements JavaScriptExecutor {
  JavascriptRuntime? _runtime;

  JavascriptRuntime get runtime {
    _runtime ??= getJavascriptRuntime();
    return _runtime!;
  }

  @override
  Future<dynamic> execute(String script) async {
    try {
      final result = runtime.evaluate(script);
      if (result.isError) {
        _log.warning('JavaScript execution error: ${result.stringResult}');
        return null;
      }
      return result.stringResult;
    } catch (e) {
      _log.warning('Failed to execute JavaScript: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> extractVariables(String script,
      {List<String>? variableNames}) async {
    final result = extractVariablesSync(script, variableNames);
    return result is Map<String, dynamic> ? result : {};
  }

  @override
  dynamic extractVariablesSync(String script, List<String>? variableNames) {
    try {
      // Build the capture script
      final captureScript = _buildCaptureScript(script, variableNames);

      // Execute the script
      final result = runtime.evaluate(captureScript);
      if (result.isError) {
        _log.warning(
            'JavaScript variable extraction error: ${result.stringResult}');
        return {};
      }

      // Get the JSON string result
      final jsonResult = result.stringResult;

      if (jsonResult.isEmpty ||
          jsonResult == 'undefined' ||
          jsonResult == 'null') {
        return {};
      }

      // Parse the JSON string
      try {
        final parsed = jsonDecode(jsonResult);

        // If only one variable requested, return its value directly
        if (variableNames != null &&
            variableNames.length == 1 &&
            parsed is Map) {
          return parsed[variableNames.first];
        }

        return parsed;
      } catch (e) {
        _log.warning('Failed to parse JSON result: $jsonResult, error: $e');
        return {};
      }
    } catch (e) {
      _log.warning('Failed to extract variables: $e');
      return {};
    }
  }

  String _buildCaptureScript(String script, List<String>? variableNames) {
    if (variableNames != null && variableNames.isNotEmpty) {
      // Capture specific variables
      final captures = variableNames
          .map((name) =>
              '"$name": (typeof $name !== "undefined" ? $name : null)')
          .join(',\n    ');

      return '''
(function() {
  eval(${_escapeScript(script)});
  return JSON.stringify({
    $captures
  });
})();
''';
    } else {
      // Capture all variables (auto-detect)
      return '''
(function() {
  var __before__ = Object.keys(globalThis);
  
  eval(${_escapeScript(script)});
  
  var __after__ = Object.keys(globalThis);
  var __captured__ = {};
  
  for (var i = 0; i < __after__.length; i++) {
    var key = __after__[i];
    if (__before__.indexOf(key) === -1) {
      try {
        __captured__[key] = globalThis[key];
      } catch(e) {}
    }
  }
  
  return JSON.stringify(__captured__);
})();
''';
    }
  }

  String _escapeScript(String script) {
    // Escape the script for use in eval()
    return jsonEncode(script);
  }

  /// Dispose the JavaScript runtime
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
  }
}

/// Singleton instance for global access
class JsExecutorRegistry {
  static JavaScriptExecutor? _instance;

  /// Get the current JavaScript executor
  static JavaScriptExecutor? get instance => _instance;

  /// Set the JavaScript executor
  static set instance(JavaScriptExecutor? executor) {
    _instance = executor;
  }

  /// Check if an executor is configured
  static bool get isConfigured => _instance != null;

  /// Get or create default executor
  static JavaScriptExecutor getOrCreateDefault() {
    _instance ??= FlutterJsExecutor();
    return _instance!;
  }
}
