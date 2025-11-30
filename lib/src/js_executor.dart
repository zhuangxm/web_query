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

  /// Get or create runtime with initialized globals
  JavascriptRuntime _getRuntime() {
    if (_runtime == null) {
      _runtime = getJavascriptRuntime();
      _initializeGlobals(_runtime!);
    }
    return _runtime!;
  }

  /// Reset the runtime by disposing and creating a new one
  void _resetRuntime() {
    _runtime?.dispose();
    _runtime = null;
  }

  void _initializeGlobals(JavascriptRuntime runtime) {
    // Set up common browser globals
    final initScript = '''
      // Create window object as alias to globalThis
      var window = globalThis;
      
      // Create document mock object
      var document = {
        getElementById: function(id) { return null; },
        getElementsByTagName: function(tag) {return null;},
        querySelector: function(selector) { return null; },
        querySelectorAll: function(selector) { return []; },
        createElement: function(tag) { return {}; },
        body: {},
        head: {},
        title: '',
        location: {
          href: '',
          protocol: 'https:',
          host: '',
          hostname: '',
          port: '',
          pathname: '/',
          search: '',
          hash: ''
        }
      };
      
      // Create console mock
      var console = {
        log: function() {},
        warn: function() {},
        error: function() {},
        info: function() {},
        debug: function() {}
      };
      
      // Create navigator mock
      var navigator = {
        userAgent: 'Mozilla/5.0 (Flutter) AppleWebKit/537.36',
        language: 'en-US',
        languages: ['en-US', 'en'],
        platform: 'Flutter',
        onLine: true
      };
      
      // Create location as alias to document.location
      var location = document.location;
      
      // Create localStorage and sessionStorage mocks
      var localStorage = {
        getItem: function(key) { return null; },
        setItem: function(key, value) {},
        removeItem: function(key) {},
        clear: function() {},
        length: 0
      };
      var sessionStorage = localStorage;
      
      // Create common functions
      var setTimeout = function(fn, delay) { return 0; };
      var setInterval = function(fn, delay) { return 0; };
      var clearTimeout = function(id) {};
      var clearInterval = function(id) {};
      
      // Create alert, confirm, prompt mocks
      var alert = function(msg) {};
      var confirm = function(msg) { return false; };
      var prompt = function(msg, defaultValue) { return null; };
    ''';

    try {
      runtime.evaluate(initScript);
      _log.fine('JavaScript globals initialized');
    } catch (e) {
      _log.warning('Failed to initialize JavaScript globals: $e');
    }
  }

  @override
  Future<dynamic> execute(String script) async {
    try {
      // Reset runtime for fresh execution
      _resetRuntime();
      final runtime = _getRuntime();

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
      // Reset runtime for fresh execution
      _resetRuntime();
      final runtime = _getRuntime();

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

  /// Dispose the JavaScript runtime
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
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
  
  // Custom JSON.stringify with circular reference handling
  function safeStringify(obj, seen) {
    seen = seen || new WeakSet();
    
    if (obj === null || obj === undefined) return JSON.stringify(obj);
    if (typeof obj !== 'object') return JSON.stringify(obj);
    
    // Check for circular reference
    if (seen.has(obj)) return JSON.stringify('[Circular]');
    seen.add(obj);
    
    if (Array.isArray(obj)) {
      var items = obj.map(function(item) {
        return safeStringify(item, seen);
      });
      return '[' + items.join(',') + ']';
    }
    
    var pairs = [];
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        try {
          var value = safeStringify(obj[key], seen);
          pairs.push(JSON.stringify(key) + ':' + value);
        } catch (e) {
          // Skip properties that can't be serialized
        }
      }
    }
    return '{' + pairs.join(',') + '}';
  }
  
  return safeStringify({
    $captures
  });
})();
''';
    } else {
      // Capture all variables (auto-detect)
      return '''
(function() {
  // Custom JSON.stringify with circular reference handling
  function safeStringify(obj, seen) {
    seen = seen || new WeakSet();
    
    if (obj === null || obj === undefined) return JSON.stringify(obj);
    if (typeof obj !== 'object') return JSON.stringify(obj);
    
    // Check for circular reference
    if (seen.has(obj)) return JSON.stringify('[Circular]');
    seen.add(obj);
    
    if (Array.isArray(obj)) {
      var items = obj.map(function(item) {
        return safeStringify(item, seen);
      });
      return '[' + items.join(',') + ']';
    }
    
    var pairs = [];
    for (var key in obj) {
      if (obj.hasOwnProperty(key)) {
        try {
          var value = safeStringify(obj[key], seen);
          pairs.push(JSON.stringify(key) + ':' + value);
        } catch (e) {
          // Skip properties that can't be serialized
        }
      }
    }
    return '{' + pairs.join(',') + '}';
  }
  
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
  
  return safeStringify(__captured__);
})();
''';
    }
  }

  String _escapeScript(String script) {
    // Escape the script for use in eval()
    return jsonEncode(script);
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
