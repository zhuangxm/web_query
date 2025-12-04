/// Transform Pipeline - Orchestrates sequential application of transforms
///
/// This module coordinates the execution of transforms in a well-defined order,
/// ensuring consistent data flow through the transformation pipeline.
///
/// ## Pipeline Order
///
/// Transforms are applied in the following sequence:
/// 1. **transform** - Text and data transformations (upper, lower, json, jseval, regexp)
/// 2. **update** - JSON object updates and merging
/// 3. **filter** - Include/exclude pattern filtering
/// 4. **index** - Array element selection
/// 5. **save** - Variable storage (saves unwrapped values)
/// 6. **discard** - Result omission marking (wraps in DiscardMarker)
///
/// ## Key Components
///
/// ### TransformContext
/// Provides page data and variables to transforms that need context:
/// - `pageUrl` - Full page URL for regexp replacements
/// - `rootUrl` - Origin (scheme + authority) for regexp replacements
/// - `variables` - Shared variable map for save operations
///
/// ### DiscardMarker
/// Wrapper class indicating a value should be omitted from final results.
/// Used when `?save=varName` is specified without `&keep` parameter.
///
/// ## Usage Examples
///
/// ### Basic Pipeline
/// ```dart
/// final transforms = {
///   'transform': ['upper'],
///   'filter': ['HELLO'],
/// };
/// final result = applyAllTransforms(node, 'hello world', transforms, {});
/// // Returns: 'HELLO WORLD'
/// ```
///
/// ### Save and Discard
/// ```dart
/// final variables = <String, dynamic>{};
/// final transforms = {
///   'save': ['myVar'],
///   'discard': ['true'],
/// };
/// final result = applyAllTransforms(node, 'value', transforms, variables);
/// // variables['myVar'] == 'value'
/// // result == DiscardMarker('value')
/// ```
///
/// ### Multiple Transforms
/// ```dart
/// final transforms = {
///   'transform': ['lower', 'json'],
///   'filter': ['apple'],
///   'index': ['0'],
/// };
/// final result = applyAllTransforms(node, data, transforms, {});
/// // Applies: lower → json → filter → index
/// ```
///
/// ## Transform Chaining
///
/// Each transform receives the output of the previous transform as input,
/// creating a data flow pipeline. Null values propagate through the pipeline,
/// with most transforms returning null when given null input.
///
/// ## Error Handling
///
/// The pipeline is resilient to errors:
/// - Invalid transform names are ignored
/// - Null values propagate safely
/// - Transform-specific errors are logged but don't break the pipeline
library;

import '../page_data.dart';
import 'data_transforms.dart';
import 'pattern_transforms.dart';
import 'selection_transforms.dart';
import 'text_transforms.dart';

/// Context object for passing page data and variables through transform pipeline
///
/// Provides access to page context information needed by transforms that
/// reference page data (e.g., regexp replacements with ${pageUrl}).
///
/// ## Properties
///
/// - [node] - The PageNode containing page data and metadata
/// - [variables] - Shared variable map for save/load operations
/// - [pageUrl] - Convenience getter for full page URL
/// - [rootUrl] - Convenience getter for page origin (scheme + authority)
///
/// ## Usage
///
/// ```dart
/// final context = TransformContext(pageNode, variables);
/// print(context.pageUrl);  // 'https://example.com/page'
/// print(context.rootUrl);  // 'https://example.com'
/// ```
class TransformContext {
  final PageNode node;
  final Map<String, dynamic> variables;

  TransformContext(this.node, this.variables);

  /// Get the full page URL
  String get pageUrl => node.pageData.url;

  /// Get the root URL (origin) of the page
  String get rootUrl {
    try {
      return Uri.parse(node.pageData.url).origin;
    } catch (e) {
      return '';
    }
  }
}

/// Marker class to indicate a value should be discarded from final results
///
/// Used to implement the `?save=varName` behavior without `&keep` parameter.
/// When a value is wrapped in DiscardMarker, it indicates the value should be:
/// 1. Saved to the variables map (if save transform is present)
/// 2. Omitted from the final query results
///
/// ## Usage
///
/// ```dart
/// // Wrap a value for discard
/// final marked = DiscardMarker('value');
///
/// // Check if a value is marked for discard
/// if (result is DiscardMarker) {
///   print('Value will be discarded: ${result.value}');
/// }
/// ```
///
/// ## Pipeline Behavior
///
/// The discard transform is applied AFTER save, ensuring that:
/// - Variables receive the unwrapped value
/// - The final result is wrapped in DiscardMarker
/// - QueryResult processing can filter out discarded values
class DiscardMarker {
  final dynamic value;
  DiscardMarker(this.value);

  @override
  String toString() => 'DiscardMarker($value)';
}

/// Apply all transforms to a value in the correct pipeline order
///
/// Orchestrates the sequential application of transforms, ensuring they execute
/// in the defined order and data flows correctly through the pipeline.
///
/// ## Parameters
///
/// - [node] - PageNode containing page data and metadata for context
/// - [value] - The input value to transform
/// - [transforms] - Map of transform types to lists of transform parameters
/// - [variables] - Shared variable map for save/load operations
///
/// ## Transform Order
///
/// 1. **transform** - Text/data transformations (upper, lower, json, jseval, regexp)
/// 2. **update** - JSON object updates
/// 3. **filter** - Include/exclude filtering
/// 4. **index** - Array indexing
/// 5. **save** - Variable storage (before discard wrapping)
/// 6. **discard** - Result omission marking
///
/// ## Returns
///
/// The transformed value, potentially wrapped in [DiscardMarker] if discard
/// transform is present. Returns null if input is null or transforms produce null.
///
/// ## Examples
///
/// ### Single Transform
/// ```dart
/// final transforms = {'transform': ['upper']};
/// final result = applyAllTransforms(node, 'hello', transforms, {});
/// // Returns: 'HELLO'
/// ```
///
/// ### Multiple Transforms
/// ```dart
/// final transforms = {
///   'transform': ['lower'],
///   'filter': ['apple'],
///   'index': ['0'],
/// };
/// final result = applyAllTransforms(node, ['APPLE', 'BANANA'], transforms, {});
/// // Returns: 'apple'
/// ```
///
/// ### Save and Discard
/// ```dart
/// final variables = <String, dynamic>{};
/// final transforms = {
///   'save': ['fruit'],
///   'discard': ['true'],
/// };
/// final result = applyAllTransforms(node, 'apple', transforms, variables);
/// // variables['fruit'] == 'apple'
/// // result == DiscardMarker('apple')
/// ```
dynamic applyAllTransforms(PageNode node, dynamic value,
    Map<String, List<String>> transforms, Map<String, dynamic> variables) {
  if (value == null) return null;

  final context = TransformContext(node, variables);

  return transforms.entries.fold(value, (result, entry) {
    switch (entry.key) {
      case 'transform':
        return entry.value.fold(result,
            (v, transform) => _applyTransformValues(context, v, transform));
      case 'update':
        return entry.value.fold(result, (v, update) => applyUpdate(v, update));
      case 'filter':
        return entry.value.fold(result, (v, filter) => applyFilter(v, filter));
      case 'index':
        return entry.value
            .fold(result, (v, indexStr) => applyIndex(v, indexStr));
      case 'save':
        // Save BEFORE discard so we save the unwrapped value
        entry.value.fold(result, (v, varName) {
          if (v != null) {
            variables[varName] = v;
          }
          return v;
        });
        return result;
      case 'discard':
        // Mark value for discard by wrapping in a special marker
        return entry.value.isEmpty ? result : DiscardMarker(result);
      default:
        return result;
    }
  });
}

/// Apply transform to values, handling both single values and lists
dynamic _applyTransformValues(
    TransformContext context, dynamic value, String transform) {
  return (value is List)
      ? value.map((v) => _applyTransform(context, v, transform)).toList()
      : _applyTransform(context, value, transform);
}

/// Apply a single transform to a value
dynamic _applyTransform(
    TransformContext context, dynamic value, String transform) {
  if (value == null) return null;

  if (transform.startsWith('regexp:')) {
    return applyRegexpTransform(context.node, value, transform.substring(7));
  }

  if (transform.startsWith('json:')) {
    return applyJsonTransform(value, transform.substring(5));
  }

  if (transform.startsWith('jseval:')) {
    return applyJsEvalTransform(value, transform.substring(7));
  }

  switch (transform) {
    case 'upper':
    case 'lower':
      return applyTextTransform(value, transform);
    case 'json':
      return applyJsonTransform(value, null);
    case 'jseval':
      return applyJsEvalTransform(value, null);
    default:
      return value;
  }
}
