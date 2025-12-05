/// Transform System - Data transformation and processing pipeline
///
/// This library provides a modular transform system for processing query results.
/// Transforms are organized into focused modules by responsibility:
///
/// ## Transform Modules
///
/// ### Transform Pipeline ([transform_pipeline.dart])
/// Orchestrates the sequential application of transforms in a well-defined order:
/// 1. `transform` - Text and data transformations
/// 2. `update` - JSON object updates
/// 3. `filter` - Include/exclude filtering
/// 4. `index` - Array indexing
/// 5. `save` - Variable storage
///
/// Note: Result omission (discard) is handled at the query level, not in the transform pipeline.
///
/// ### Text Transforms ([text_transforms.dart])
/// Text manipulation, encoding, and hashing:
/// - `upper` - Convert to uppercase
/// - `lower` - Convert to lowercase
/// - `base64` - Encode to Base64
/// - `base64decode` - Decode from Base64
/// - `reverse` - Reverse string
/// - `md5` - Generate MD5 hash
///
/// ### Data Transforms ([data_transforms.dart])
/// Complex data processing:
/// - `json` - Parse JSON strings and extract JavaScript variables
/// - `jseval` - Execute JavaScript code and extract variables
/// - `update` - Merge JSON objects
///
/// ### Pattern Transforms ([pattern_transforms.dart])
/// Regular expression operations:
/// - Pattern extraction: `/pattern/`
/// - Pattern replacement: `/pattern/replacement/`
/// - Special keywords: `\ALL` for multiline matching
/// - Page context variables: `${pageUrl}`, `${rootUrl}`
///
/// ### Selection Transforms ([selection_transforms.dart])
/// Data filtering and indexing:
/// - `filter` - Include/exclude patterns with special character escaping
/// - `index` - Positive and negative array indexing
///
/// ## Usage Examples
///
/// ### Basic Text Transform
/// ```dart
/// final result = applyTextTransform('hello', 'upper');
/// // Returns: 'HELLO'
/// ```
///
/// ### JSON Parsing with Variable Extraction
/// ```dart
/// final js = 'var config = {"key": "value"};';
/// final result = applyJsonTransform(js, 'config');
/// // Returns: {'key': 'value'}
/// ```
///
/// ### Regexp with Page Context
/// ```dart
/// final context = TransformContext(pageNode, {});
/// final result = applyRegexpTransform(
///   pageNode,
///   'Visit us',
///   r'/Visit us/Visit ${pageUrl}/'
/// );
/// // Returns: 'Visit https://example.com'
/// ```
///
/// ### Filter with Multiple Patterns
/// ```dart
/// final list = ['Apple', 'Banana', 'Cherry'];
/// final result = applyFilter(list, 'a !Banana');
/// // Returns: ['Apple', 'Cherry']
/// ```
///
/// ### Full Pipeline
/// ```dart
/// final transforms = {
///   'transform': ['upper'],
///   'filter': ['HELLO'],
///   'index': ['0'],
/// };
/// final result = applyAllTransforms(node, 'hello world', transforms, {});
/// // Returns: 'HELLO WORLD'
/// ```
///
/// ## Migration Guide
///
/// ### JavaScript Executor Registration
///
/// The old global JS executor pattern has been replaced with [JsExecutorRegistry]:
///
/// ```dart
/// // Old (deprecated, but still works)
/// setJsExecutorInstance(FlutterJsExecutor());
///
/// // New (preferred)
/// JsExecutorRegistry.register(FlutterJsExecutor());
/// ```
///
/// ### TransformContext Usage
///
/// Transforms that need page context now receive a [TransformContext] object:
///
/// ```dart
/// final context = TransformContext(pageNode, variables);
/// final pageUrl = context.pageUrl;  // Full page URL
/// final rootUrl = context.rootUrl;  // Origin (scheme + authority)
/// ```
///
/// ## Backward Compatibility
///
/// This reorganization maintains 100% backward compatibility:
/// - All public APIs remain unchanged
/// - Existing code continues to work without modification
/// - Deprecated functions provide migration path
///
/// ## Architecture
///
/// The transform system follows a modular architecture with clear separation of concerns:
/// - **Orchestration** - Pipeline coordination and transform ordering
/// - **Implementation** - Focused modules for each transform type
/// - **Context** - Shared context for page data and variables
/// - **Registry** - Centralized JS executor management
library;

// Re-export data transforms for backward compatibility
import 'transforms/data_transforms.dart' show JsExecutorRegistry;

export 'transforms/data_transforms.dart'
    show
        applyJsonTransform,
        applyJsEvalTransform,
        applyUpdate,
        JsExecutorRegistry;
// Re-export pattern transforms for backward compatibility
export 'transforms/pattern_transforms.dart'
    show applyRegexpTransform, parseRegexpPattern, prepareReplacement;
// Re-export selection transforms for backward compatibility
export 'transforms/selection_transforms.dart' show applyFilter, applyIndex;
// Re-export text transforms for backward compatibility
export 'transforms/text_transforms.dart'
    show
        applyTextTransform,
        toUpperCase,
        toLowerCase,
        base64Encode,
        base64Decode,
        reverseString,
        md5Hash;
// Re-export transform pipeline for backward compatibility
export 'transforms/transform_pipeline.dart'
    show
        applyAllTransforms,
        TransformContext,
        DiscardMarker,
        validTextTransforms;

/// Backward compatibility shim for old JS executor API
///
/// **Deprecated:** Use [JsExecutorRegistry.register] instead.
///
/// This function provides backward compatibility for code using the old
/// global JS executor pattern. New code should use the registry directly:
///
/// ```dart
/// // Old (deprecated, but still works)
/// setJsExecutorInstance(FlutterJsExecutor());
///
/// // New (preferred)
/// JsExecutorRegistry.register(FlutterJsExecutor());
/// ```
///
/// This function will be removed in a future major version.
@Deprecated('Use JsExecutorRegistry.register() instead')
void setJsExecutorInstance(dynamic instance) {
  JsExecutorRegistry.register(instance);
}
