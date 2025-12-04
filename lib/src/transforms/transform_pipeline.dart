/// Transform Pipeline - Orchestrates sequential application of transforms
///
/// This module coordinates the execution of transforms in a well-defined order,
/// ensuring consistent data flow through the transformation pipeline.
///
/// ## Pipeline Order
///
/// Transforms are applied in the following sequence:
/// 1. **transform** - Text and data transformations (upper, lower, base64, reverse, md5, json, jseval, regexp)
/// 2. **update** - JSON object updates and merging
/// 3. **filter** - Include/exclude pattern filtering
/// 4. **index** - Array element selection
/// 5. **save** - Variable storage
///
/// **Note**: The `discard` behavior (when `?save=` is used without `&keep`) is handled
/// at a higher level in `query.dart`, not in this transform pipeline.
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
/// Created in `query.dart` when `?save=varName` is used without `&keep` parameter.
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
/// ### Save Variable
/// ```dart
/// final variables = <String, dynamic>{};
/// final transforms = {
///   'save': ['myVar'],
/// };
/// final result = applyAllTransforms(node, 'value', transforms, variables);
/// // variables['myVar'] == 'value'
/// // result == 'value' (unchanged)
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
/// The save operation stores values without modifying the result.
/// The actual discard behavior (wrapping in DiscardMarker) happens at a higher
/// level in `query.dart` when `?save=` is used without `&keep`.
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
/// 1. **transform** - Text/data transformations (upper, lower, base64, reverse, md5, json, jseval, regexp)
/// 2. **update** - JSON object updates
/// 3. **filter** - Include/exclude filtering
/// 4. **index** - Array indexing
/// 5. **save** - Variable storage
///
/// ## Returns
///
/// The transformed value. Returns null if input is null or transforms produce null.
/// Note: [DiscardMarker] wrapping is handled at a higher level in `query.dart`.
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
/// ### Save Variable
/// ```dart
/// final variables = <String, dynamic>{};
/// final transforms = {
///   'save': ['fruit'],
/// };
/// final result = applyAllTransforms(node, 'apple', transforms, variables);
/// // variables['fruit'] == 'apple'
/// // result == 'apple' (unchanged)
/// ```
dynamic applyAllTransforms(PageNode node, dynamic value,
    Map<String, List<String>> transforms, Map<String, dynamic> variables) {
  if (value == null) return null;

  final context = TransformContext(node, variables);

  // Define the correct order of transform execution
  const transformOrder = [
    'transform',
    'update',
    'filter',
    'index',
    'save',
  ];

  // Apply transforms in the defined order, not map iteration order
  var result = value;
  for (final transformType in transformOrder) {
    if (!transforms.containsKey(transformType)) continue;

    final transformValues = transforms[transformType]!;

    switch (transformType) {
      case 'transform':
        result = transformValues.fold(result,
            (v, transform) => _applyTransformValues(context, v, transform));
        break;
      case 'update':
        result =
            transformValues.fold(result, (v, update) => applyUpdate(v, update));
        break;
      case 'filter':
        result =
            transformValues.fold(result, (v, filter) => applyFilter(v, filter));
        break;
      case 'index':
        result = transformValues.fold(
            result, (v, indexStr) => applyIndex(v, indexStr));
        break;
      case 'save':
        // Save the value to variables without modifying the result
        transformValues.fold(result, (v, varName) {
          if (v != null) {
            variables[varName] = v;
          }
          return v;
        });
        // Don't modify result, just save to variables
        break;
    }
  }

  return result;
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
