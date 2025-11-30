/// JavaScript execution support for web_query
///
/// This library provides JavaScript execution capabilities for extracting
/// variables from obfuscated or eval-based JavaScript code.
///
/// The JavaScript runtime is reset only when a query uses jseval transforms,
/// and only once per QueryString.execute() call. This prevents variable
/// pollution between queries while maximizing efficiency.
///
/// Usage:
/// ```dart
/// import 'package:web_query/js.dart';
///
/// // Basic configuration
/// configureJsExecutor(FlutterJsExecutor());
///
/// // Configure with custom limits
/// configureJsExecutor(FlutterJsExecutor(
///   maxScriptSize: 2 * 1024 * 1024,  // 2MB script limit
///   maxResultSize: 20 * 1024 * 1024, // 20MB result limit
///   truncateLargeScripts: true,       // Truncate instead of reject
/// ));
///
/// // Use in queries
/// final result = QueryString('script/@text?transform=jseval:config,data')
///     .getValue(node);
/// ```
library web_query_js;

export 'src/js_executor.dart';

import 'src/js_executor.dart';
import 'src/transforms.dart' as transforms;

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
