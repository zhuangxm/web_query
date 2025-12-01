import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:logging/logging.dart';

final _log = Logger('QueryString.JsExecutor');

/// Abstract interface for JavaScript execution
abstract class JavaScriptExecutor {
  /// Execute JavaScript code and return the result
  Future<dynamic> execute(String script);

  /// Extract variables from JavaScript code (async)
  Future<Map<String, dynamic>?> extractVariables(String script,
      {List<String>? variableNames});

  /// Extract variables from JavaScript code (synchronous)
  dynamic extractVariablesSync(String script, List<String>? variableNames);

  /// Reset the runtime to start fresh (call once per QueryString.execute())
  void reset();
}

/// Default implementation using flutter_js
class FlutterJsExecutor implements JavaScriptExecutor {
  JavascriptRuntime? _runtime;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 10;

  /// Maximum script size in bytes (default: 1MB)
  final int maxScriptSize;

  /// Maximum result size in bytes (default: 10MB)
  final int maxResultSize;

  /// Whether to truncate large scripts instead of rejecting them
  final bool truncateLargeScripts;

  FlutterJsExecutor({
    this.maxScriptSize = 1024 * 1024, // 1MB
    this.maxResultSize = 10 * 1024 * 1024, // 10MB
    this.truncateLargeScripts = false,
  });

  /// Get or create runtime with initialized globals
  JavascriptRuntime _getRuntime() {
    if (_runtime == null) {
      try {
        _runtime = getJavascriptRuntime(xhr: false);
        _initializeGlobals(_runtime!);
      } catch (e) {
        _log.severe('Failed to create JavaScript runtime: $e');
        rethrow;
      }
    }
    return _runtime!;
  }

  /// Reset the runtime by clearing global variables (safer than dispose)
  void _resetRuntime() {
    // Don't dispose - it causes crashes
    // Instead, just clear user-defined variables
    if (_runtime == null) return;

    try {
      // Clear user-defined variables but keep our mocks
      const clearScript = '''
        (function() {
          var keysToKeep = ['window', 'document', 'console', 'navigator', 'screen', 
                           'location', 'localStorage', 'sessionStorage', 'setTimeout', 
                           'setInterval', 'clearTimeout', 'clearInterval', 'alert', 
                           'confirm', 'prompt', 'atob', 'btoa'];
          var allKeys = Object.keys(globalThis);
          for (var i = 0; i < allKeys.length; i++) {
            var key = allKeys[i];
            if (keysToKeep.indexOf(key) === -1 && !key.startsWith('__')) {
              try {
                delete globalThis[key];
              } catch(e) {}
            }
          }
        })();
      ''';
      _runtime!.evaluate(clearScript);
      _log.fine('JavaScript globals cleared');
      _initializeGlobals(_runtime!);
    } catch (e) {
      _log.warning('Error clearing globals: $e');
    }
  }

  /// Check if runtime is healthy by running a simple test
  bool _isRuntimeHealthy() {
    if (_runtime == null) return false;
    try {
      final result = _runtime!.evaluate('1 + 1');
      return !result.isError && result.stringResult == '2';
    } catch (e) {
      _log.warning('Runtime health check failed: $e');
      return false;
    }
  }

  void _initializeGlobals(JavascriptRuntime runtime) {
    // Set up common browser globals
    const initScript = '''
      // Create window object as alias to globalThis
      var window = globalThis;
      
      // Add event listener mocks
      window.addEventListener = function(event, handler, options) {};
      window.removeEventListener = function(event, handler, options) {};
      
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
      
      // Create screen mock
      var screen = {
        width: 1920,
        height: 1080,
        availWidth: 1920,
        availHeight: 1080,
        colorDepth: 24,
        pixelDepth: 24
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
      
      // Create atob/btoa for base64 encoding/decoding
      var atob = function(str) { return str; };
      var btoa = function(str) { return str; };
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
    var processedScript = script;
    try {
      // Handle large scripts
      if (processedScript.length > maxScriptSize) {
        if (truncateLargeScripts) {
          _log.warning(
              'JavaScript script truncated from ${processedScript.length} to $maxScriptSize bytes');
          processedScript = processedScript.substring(0, maxScriptSize);
        } else {
          _log.warning(
              'JavaScript script too large: ${processedScript.length} bytes (max: $maxScriptSize)');
          return null;
        }
      }

      // Use existing runtime (reset should be called once per QueryString.execute())
      final runtime = _getRuntime();

      JsEvalResult result;
      try {
        result = runtime.evaluate(processedScript);
      } catch (e) {
        _log.warning('Runtime evaluation crashed: $e');
        // Reset runtime on crash
        _resetRuntime();
        return null;
      }

      if (result.isError) {
        _log.warning('JavaScript execution error: ${result.stringResult}');
        return null;
      }
      return result.stringResult;
    } catch (e) {
      _log.warning('Failed to execute JavaScript: $e');
      // Reset runtime on any error
      _resetRuntime();
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> extractVariables(String script,
      {List<String>? variableNames}) async {
    final result = extractVariablesSync(script, variableNames);
    if (result == null) return null;
    return (result is Map<String, dynamic> && result.isNotEmpty)
        ? result
        : null;
  }

  @override
  dynamic extractVariablesSync(String script, List<String>? variableNames) {
    var processedScript = script;
    try {
      // Stop if too many consecutive errors
      if (_consecutiveErrors >= _maxConsecutiveErrors) {
        _log.severe(
            'Too many consecutive errors ($_consecutiveErrors), stopping execution');
        return null;
      }

      // Handle large scripts
      if (processedScript.length > maxScriptSize) {
        if (truncateLargeScripts) {
          _log.warning(
              'JavaScript script truncated from ${processedScript.length} to $maxScriptSize bytes');
          processedScript = processedScript.substring(0, maxScriptSize);
        } else {
          _log.warning(
              'JavaScript script too large: ${processedScript.length} bytes (max: $maxScriptSize)');
          _consecutiveErrors++;
          return null;
        }
      }

      // Use existing runtime (reset should be called once per QueryString.execute())
      // Check runtime health first
      if (_runtime != null && !_isRuntimeHealthy()) {
        _log.warning('Runtime unhealthy, resetting');
        _resetRuntime();
      }

      final runtime = _getRuntime();

      // Build the capture script
      final captureScript = _buildCaptureScript(processedScript, variableNames);

      // Check total script size after wrapping (allow 5x for wrapper code)
      const maxWrappedSize = 5 * 1024 * 1024; // 5MB max for wrapped script
      if (captureScript.length > maxWrappedSize) {
        _log.warning(
            'Wrapped script too large: ${captureScript.length} bytes (max: $maxWrappedSize)');
        return null;
      }

      // Execute the script with error handling
      JsEvalResult result;
      try {
        result = runtime.evaluate(captureScript);
      } catch (e) {
        _log.warning('Runtime evaluation crashed: $e');
        _consecutiveErrors++;
        // Reset runtime on crash
        _resetRuntime();
        return null;
      }

      if (result.isError) {
        _consecutiveErrors++;
        // Only log first few errors to avoid spam
        if (_consecutiveErrors <= 3) {
          _log.warning(
              'JavaScript variable extraction error: ${result.stringResult}');
        }
        return null;
      }

      // Success - reset error counter
      _consecutiveErrors = 0;

      // Get the JSON string result
      final jsonResult = result.stringResult;

      if (jsonResult.isEmpty ||
          jsonResult == 'undefined' ||
          jsonResult == 'null') {
        return null;
      }

      // Check result size limit
      if (jsonResult.length > maxResultSize) {
        _log.warning(
            'JavaScript result too large: ${jsonResult.length} bytes (max: $maxResultSize)');
        return null;
      }

      // Parse the JSON string
      try {
        final updatedJsonResult = jsonResult.replaceAll("undefined", '""');
        final parsed = jsonDecode(updatedJsonResult);

        // If result is empty map, return null (no variables found)
        if (parsed is Map && parsed.isEmpty) {
          return null;
        }

        // If only one variable requested (and not a wildcard), return its value directly
        if (variableNames != null &&
            variableNames.length == 1 &&
            !variableNames.first.contains('*') &&
            !variableNames.first.contains('?') &&
            parsed is Map) {
          return parsed[variableNames.first];
        }

        return parsed;
      } catch (e) {
        _log.warning('Failed to parse JSON result: $jsonResult, error: $e');
        return null;
      }
    } catch (e) {
      _log.warning('Failed to extract variables: $e');
      // Reset runtime on any error
      _resetRuntime();
      return null;
    }
  }

  @override
  void reset() {
    _resetRuntime();
    _consecutiveErrors = 0;
  }

  /// Dispose the JavaScript runtime
  void dispose() {
    // Don't dispose - it causes crashes
    // Just clear the reference
    _runtime = null;
  }

  String _buildCaptureScript(String script, List<String>? variableNames) {
    if (variableNames != null && variableNames.isNotEmpty) {
      // Check if any variable name contains wildcard
      final hasWildcard = variableNames.any((name) => name.contains('*'));

      if (hasWildcard) {
        // Use wildcard matching
        final patterns = variableNames.map((name) {
          // Convert wildcard pattern to regex
          final regexPattern = name.replaceAll('*', '.*').replaceAll('?', '.');
          return '"$regexPattern"';
        }).join(', ');

        return '''
(function() {
  // Use indirect eval to execute in global scope
  (1, eval)(${_escapeScript(script)});
  
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
  
  // Wildcard matching
  var patterns = [$patterns];
  var __captured__ = {};
  var allKeys = Object.keys(globalThis);
  
  for (var i = 0; i < allKeys.length; i++) {
    var key = allKeys[i];
    for (var j = 0; j < patterns.length; j++) {
      var regex = new RegExp('^' + patterns[j] + '\$');
      if (regex.test(key)) {
        try {
          __captured__[key] = globalThis[key];
        } catch(e) {}
        break;
      }
    }
  }
  
  return safeStringify(__captured__);
})();
''';
      }

      // Capture specific variables (no wildcard)
      final captures = variableNames
          .map((name) =>
              '"$name": (typeof $name !== "undefined" ? $name : null)')
          .join(',\n    ');

      return '''
(function() {
  // Use indirect eval to execute in global scope
  (1, eval)(${_escapeScript(script)});
  
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
      // Use indirect eval to execute in global scope
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
  
  // Capture before state
  var __before__ = Object.keys(globalThis);
  
  // Execute the script in global scope using indirect eval
  (1, eval)(${_escapeScript(script)});
  
  // Capture after state
  var __after__ = Object.keys(globalThis);
  var __captured__ = {};
  
  // Find new variables
  for (var i = 0; i < __after__.length; i++) {
    var key = __after__[i];
    if (__before__.indexOf(key) === -1) {
      try {
        __captured__[key] = globalThis[key];
      } catch(e) {}
    }
  }
  
  // Also check window object for common patterns
  if (typeof window !== 'undefined') {
    var commonPatterns = ['__INITIAL_STATE__', '__NEXT_DATA__', '__NUXT__', 'pageData', 'appData', 'config'];
    for (var j = 0; j < commonPatterns.length; j++) {
      var pattern = commonPatterns[j];
      if (typeof window[pattern] !== 'undefined' && !__captured__[pattern]) {
        try {
          __captured__[pattern] = window[pattern];
        } catch(e) {}
      }
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
  static JavaScriptExecutor? instance;

  /// Check if an executor is configured
  static bool get isConfigured => instance != null;

  /// Get or create default executor
  static JavaScriptExecutor getOrCreateDefault() {
    instance ??= FlutterJsExecutor();
    return instance!;
  }
}
