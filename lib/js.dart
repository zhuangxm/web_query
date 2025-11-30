/// JavaScript execution support for web_query
///
/// This library provides JavaScript execution capabilities for extracting
/// variables from obfuscated or eval-based JavaScript code.
///
/// Usage:
/// ```dart
/// import 'package:web_query/js.dart';
///
/// // Configure the executor
/// JsExecutorRegistry.instance = FlutterJsExecutor();
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
