/// JavaScript execution support for web_query
///
/// This library provides JavaScript execution capabilities for extracting
/// variables from obfuscated or eval-based JavaScript code.
///
/// The JavaScript runtime clears global variables only when a query uses
/// jseval transforms, and only once per QueryString.execute() call. This
/// prevents variable pollution between queries while maximizing efficiency.
/// The runtime is never disposed (which causes crashes), only cleared.
///
/// ## Variable Detection
///
/// Auto-detect (`jseval` without variable names) captures:
/// - Variables declared with `var` in global scope (e.g., `var COOKIE_DOMAIN = 'example.com'`)
/// - Variables added to `window` or `globalThis`
/// - Common patterns like `__INITIAL_STATE__`, `__NEXT_DATA__`, etc.
///
/// It CANNOT detect:
/// - Variables declared with `let` or `const` (block-scoped, inaccessible)
/// - Variables in function scope
///
/// **Example:**
/// ```javascript
/// var userId = 123;           // ✓ Auto-detected
/// window.config = {...};      // ✓ Auto-detected
/// let userName = "Alice";     // ✗ NOT detected (block-scoped)
/// const API_KEY = "secret";   // ✗ NOT detected (block-scoped)
/// ```
///
/// For `let`/`const` variables, you must use other extraction methods like
/// `transform=json:variableName` which uses regex pattern matching.
///
/// Usage:
/// ```dart
/// import 'package:web_query/js.dart';
///
/// // Basic configuration
/// configureJsExecutor(FlutterJsExecutor());
///
/// // Extract specific variables (recommended)
/// final result = QueryString('script/@text?transform=jseval:config,userData')
///     .getValue(node);
///
/// // Auto-detect (limited to global variables)
/// final all = QueryString('script/@text?transform=jseval')
///     .getValue(node);
///
/// // Configure with custom limits
/// configureJsExecutor(FlutterJsExecutor(
///   maxScriptSize: 2 * 1024 * 1024,  // 2MB script limit
///   maxResultSize: 20 * 1024 * 1024, // 20MB result limit
///   truncateLargeScripts: true,       // Truncate instead of reject
/// ));
/// ```
library web_query_js;

import 'src/js_executor.dart';
import 'src/transforms.dart' as transforms;

export 'src/js_executor.dart';

/// Initialize JavaScript execution support
void initializeJsSupport() {
  // Set up the executor instance for transforms
  if (JsExecutorRegistry.isConfigured) {
    transforms.setJsExecutorInstance(JsExecutorRegistry.instance);
  }
}

/// Configure JavaScript executor and initialize support
void configureJsExecutor(JavaScriptExecutor executor) {
  JsExecutorRegistry.instance = executor;
  initializeJsSupport();
}
