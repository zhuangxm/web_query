# Design Document

## Overview

This design reorganizes the transform processing system in `lib/src/transforms.dart` to improve code clarity, maintainability, and testability. The current monolithic file will be split into focused modules with clear responsibilities:

1. **Transform Orchestration** - Coordinates the application of transforms in sequence
2. **Core Transforms** - Basic text transformations (upper, lower)
3. **Data Transforms** - Complex data processing (JSON, JavaScript evaluation)
4. **Pattern Transforms** - Regular expression operations
5. **Selection Transforms** - Filtering and indexing operations
6. **State Management** - Variable saving and discard marking

The reorganization maintains backward compatibility while establishing a cleaner architecture for future enhancements.

## Architecture

### Current Architecture

```
transforms.dart (single file)
├── applyAllTransforms() - orchestration
├── applyTransform() - dispatch
├── applyRegexpTransform() - regexp logic
├── applyJsonTransform() - json logic
├── applyJsEvalTransform() - jseval logic
├── applyFilter() - filter logic
├── applyIndex() - index logic
├── applyUpdate() - update logic
├── prepareReplacement() - helper
├── JS executor management - global state
└── DiscardMarker - marker class
```

### Proposed Architecture

```
lib/src/transforms/
├── transform_pipeline.dart - Orchestration
│   ├── applyAllTransforms()
│   └── TransformContext (new)
│
├── text_transforms.dart - Text operations
│   ├── applyTextTransform()
│   ├── toUpperCase()
│   └── toLowerCase()
│
├── data_transforms.dart - Data processing
│   ├── applyJsonTransform()
│   ├── applyJsEvalTransform()
│   ├── applyUpdate()
│   └── JsExecutorRegistry (new)
│
├── pattern_transforms.dart - Regexp operations
│   ├── applyRegexpTransform()
│   ├── parseRegexpPattern()
│   └── prepareReplacement()
│
├── selection_transforms.dart - Filtering/indexing
│   ├── applyFilter()
│   ├── applyIndex()
│   └── parseFilterPattern()
│
└── state_transforms.dart - Variable management
    ├── applySave()
    ├── applyDiscard()
    └── DiscardMarker
```

The main `transforms.dart` file will become a barrel export that re-exports all public APIs, maintaining backward compatibility.

## Components and Interfaces

### 1. Transform Pipeline (`transform_pipeline.dart`)

**Purpose:** Orchestrates the sequential application of transforms.

**Key Functions:**
- `applyAllTransforms(PageNode node, dynamic value, Map<String, List<String>> transforms, Map<String, dynamic> variables) → dynamic`

**Transform Context:**
```dart
class TransformContext {
  final PageNode node;
  final Map<String, dynamic> variables;
  
  TransformContext(this.node, this.variables);
  
  String get pageUrl => node.pageData.url;
  String get rootUrl => Uri.parse(node.pageData.url).origin;
}
```

**Pipeline Order:**
1. `transform` - Text and data transformations
2. `update` - JSON object updates
3. `filter` - Include/exclude filtering
4. `index` - Array indexing
5. `save` - Variable storage
6. `discard` - Result omission marking

### 2. Text Transforms (`text_transforms.dart`)

**Purpose:** Simple text case transformations.

**Functions:**
```dart
dynamic applyTextTransform(dynamic value, String transform)
String toUpperCase(String value)
String toLowerCase(String value)
```

**Supported Transforms:**
- `upper` - Convert to uppercase
- `lower` - Convert to lowercase

### 3. Data Transforms (`data_transforms.dart`)

**Purpose:** Complex data processing including JSON parsing and JavaScript execution.

**Functions:**
```dart
dynamic applyJsonTransform(dynamic value, String? varName)
dynamic applyJsEvalTransform(dynamic value, String? variableNames)
dynamic applyUpdate(dynamic value, String updates)
```

**JS Executor Registry:**
```dart
class JsExecutorRegistry {
  static dynamic _instance;
  
  static void register(dynamic executor) {
    _instance = executor;
  }
  
  static dynamic get instance => _instance;
  
  static bool get isConfigured => _instance != null;
}
```

**JSON Transform Features:**
- Parse JSON strings
- Extract JavaScript variables with wildcard patterns
- Support objects, arrays, primitives, booleans, null

**JS Eval Features:**
- Execute JavaScript code
- Extract multiple variables
- Synchronous execution via flutter_js

### 4. Pattern Transforms (`pattern_transforms.dart`)

**Purpose:** Regular expression matching and replacement.

**Functions:**
```dart
dynamic applyRegexpTransform(TransformContext context, dynamic value, String pattern)
({String pattern, String replacement}) parseRegexpPattern(String pattern)
String prepareReplacement(TransformContext context, String replacement)
```

**Features:**
- Pattern-only mode (extraction)
- Replace mode with capture groups
- Special keyword support (`\ALL`)
- Page context variables (`${pageUrl}`, `${rootUrl}`)
- Multiline matching

### 5. Selection Transforms (`selection_transforms.dart`)

**Purpose:** Filter and index operations for data selection.

**Functions:**
```dart
dynamic applyFilter(dynamic value, String filter)
dynamic applyIndex(dynamic value, String indexStr)
List<String> parseFilterPattern(String filter)
```

**Filter Features:**
- Include patterns (must contain)
- Exclude patterns (must not contain, prefix with `!`)
- Multiple patterns with space separation
- Escaped special characters (`\ `, `\;`, `\&`)
- Works on both single values and lists

**Index Features:**
- Positive indices (0-based)
- Negative indices (from end)
- Bounds checking
- Single value extraction from lists

### 6. State Transforms (`state_transforms.dart`)

**Purpose:** Variable management and result omission.

**Classes:**
```dart
class DiscardMarker {
  final dynamic value;
  DiscardMarker(this.value);
}
```

**Functions:**
```dart
void applySave(dynamic value, String varName, Map<String, dynamic> variables)
dynamic applyDiscard(dynamic value)
bool isDiscarded(dynamic value)
dynamic unwrapDiscard(dynamic value)
```

**Save Behavior:**
- Store values in variables map
- Handle null values gracefully
- Execute before discard marking

**Discard Behavior:**
- Wrap values in DiscardMarker
- Indicate omission from final results
- Used with `?save=` without `&keep`

## Data Models

### TransformContext

```dart
class TransformContext {
  final PageNode node;
  final Map<String, dynamic> variables;
  
  TransformContext(this.node, this.variables);
  
  String get pageUrl => node.pageData.url;
  String get rootUrl {
    try {
      return Uri.parse(node.pageData.url).origin;
    } catch (e) {
      return '';
    }
  }
}
```

**Purpose:** Provides context information to transforms that need page data.

**Usage:** Passed to regexp transforms for replacement variable substitution.

### JsExecutorRegistry

```dart
class JsExecutorRegistry {
  static dynamic _instance;
  
  static void register(dynamic executor) {
    _instance = executor;
  }
  
  static dynamic get instance => _instance;
  
  static bool get isConfigured => _instance != null;
  
  static void clear() {
    _instance = null;
  }
}
```

**Purpose:** Manages JavaScript executor instance registration.

**Migration:** Replaces global `_jsExecutorInstance` and `setJsExecutorInstance()`.

### DiscardMarker

```dart
class DiscardMarker {
  final dynamic value;
  DiscardMarker(this.value);
  
  @override
  String toString() => 'DiscardMarker($value)';
}
```

**Purpose:** Marks values for omission from final query results.

**Usage:** Applied when `?save=` is used without `&keep` parameter.

## Co
rrectness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Transform pipeline order preservation

*For any* value and any sequence of transforms from different categories (transform, update, filter, index, save, discard), applying them through the pipeline should process them in the defined order: transform → update → filter → index → save → discard.

**Validates: Requirements 2.1**

### Property 2: Transform chaining consistency

*For any* value and any sequence of transforms, the output of each transform should become the input to the next transform, maintaining data flow through the pipeline.

**Validates: Requirements 2.2**

### Property 3: Single value and list consistency

*For any* transform and any value, applying the transform to a single value should produce the same result as applying it to a list containing only that value and extracting the first element (when the transform preserves structure).

**Validates: Requirements 3.2**

### Property 4: Null handling gracefully

*For any* transform type, passing null as input should return null without throwing exceptions.

**Validates: Requirements 3.3**

### Property 5: Regexp page context substitution

*For any* regexp replacement pattern containing `${pageUrl}` or `${rootUrl}`, and any PageNode with a valid URL, the replacement should substitute these variables with the correct page URL and root URL respectively.

**Validates: Requirements 4.3**

### Property 6: JSON wildcard variable extraction

*For any* JavaScript code containing variable assignments and any wildcard pattern, the JSON transform should extract variables whose names match the wildcard pattern.

**Validates: Requirements 5.2**

### Property 7: JSON type support

*For any* valid JSON string containing objects, arrays, primitives, booleans, or null, the JSON transform should successfully parse and return the corresponding Dart value.

**Validates: Requirements 5.4**

### Property 8: Filter include and exclude patterns

*For any* list of values and any filter pattern, include patterns (without `!`) should keep only values containing the pattern, while exclude patterns (with `!` prefix) should remove values containing the pattern.

**Validates: Requirements 6.1**

### Property 9: Filter special character escaping

*For any* filter pattern containing escaped special characters (`\ `, `\;`, `\&`), the filter should treat them as literal characters in the pattern match.

**Validates: Requirements 6.2**

### Property 10: Index positive and negative support

*For any* list and any valid index, positive indices should select from the start (0-based) and negative indices should select from the end (-1 for last element).

**Validates: Requirements 6.3**

### Property 11: Save before discard ordering

*For any* value with both save and discard transforms, the saved variable should contain the unwrapped value, not the DiscardMarker wrapper.

**Validates: Requirements 7.1**

### Property 12: JavaScript multi-variable extraction

*For any* JavaScript code and any comma-separated list of variable names, the jseval transform should extract all specified variables and return them as a structured result.

**Validates: Requirements 8.3**

## Error Handling

### Transform-Specific Error Handling

Each transform module handles errors independently:

**Text Transforms:**
- No special error handling needed (toString() always succeeds)

**Data Transforms:**
- JSON parsing failures: Log warning, return null
- JS executor not configured: Log warning with setup instructions, return null
- JS execution failures: Log warning, return null
- Update with invalid JSON: Log warning, return original value

**Pattern Transforms:**
- Invalid regexp pattern: Log warning with pattern details, return original value
- Regexp execution errors: Log warning, return original value
- URL parsing failures in replacement: Leave variables unsubstituted

**Selection Transforms:**
- Invalid index format: Log warning, return null
- Out-of-bounds index: Return null (no warning, expected behavior)
- Empty filter pattern: Return original value

**State Transforms:**
- Null values in save: Skip saving, continue pipeline
- Discard on null: Return null (no wrapping needed)

### Logging Strategy

All transforms use the `logging` package with module-specific loggers:

```dart
final _log = Logger('QueryString.Transforms.Text');
final _log = Logger('QueryString.Transforms.Data');
final _log = Logger('QueryString.Transforms.Pattern');
final _log = Logger('QueryString.Transforms.Selection');
final _log = Logger('QueryString.Transforms.State');
```

**Log Levels:**
- `warning`: Invalid input, parsing failures, configuration issues
- No `severe` or `info` logs in transform processing

### Null Propagation

The transform pipeline follows a null-safe propagation pattern:

1. If input is null, most transforms return null immediately
2. Exceptions: `save` (skips null), `discard` (returns null unwrapped)
3. Null results propagate through the pipeline
4. Final null results are handled by QueryResult simplification

## Testing Strategy

### Unit Testing

Unit tests verify specific examples and edge cases for each transform module:

**Text Transforms:**
- Upper/lower case conversion with ASCII and Unicode
- Empty strings
- Already uppercase/lowercase strings

**Data Transforms:**
- JSON parsing of each value type (object, array, primitive, boolean, null)
- JavaScript variable extraction with various patterns
- Update operations on nested objects
- Error cases (invalid JSON, missing JS executor)

**Pattern Transforms:**
- Regexp extraction mode (pattern only)
- Regexp replacement mode with capture groups
- Special keyword handling (`\ALL`)
- Page context variable substitution
- Invalid patterns

**Selection Transforms:**
- Filter with include patterns
- Filter with exclude patterns
- Filter with multiple patterns
- Index with positive values
- Index with negative values
- Index out of bounds
- Invalid index format

**State Transforms:**
- Save with various value types
- Save with null
- Discard wrapping
- Discard with null

### Property-Based Testing

Property-based tests verify universal properties across all inputs using the `test` package with custom generators. The Dart ecosystem doesn't have a mature PBT library like QuickCheck or Hypothesis, so we'll implement lightweight property testing using parameterized tests with generated inputs.

**Testing Approach:**
- Generate random inputs (strings, numbers, lists, maps)
- Run each property test with 100+ iterations
- Use seed-based randomization for reproducibility
- Tag each test with the property it validates

**Property Test Coverage:**

1. **Transform Pipeline Order** (Property 1)
   - Generate random values and transform sequences
   - Verify transforms execute in correct order
   - Check intermediate results match expected pipeline stages

2. **Transform Chaining** (Property 2)
   - Generate sequences of compatible transforms
   - Verify output of transform N equals input of transform N+1
   - Test with various value types

3. **Single Value/List Consistency** (Property 3)
   - Generate random values
   - Apply same transform to value and [value]
   - Verify results are equivalent

4. **Null Handling** (Property 3)
   - Test each transform type with null input
   - Verify no exceptions thrown
   - Verify null or appropriate default returned

5. **Regexp Context Substitution** (Property 5)
   - Generate random URLs and replacement patterns
   - Verify ${pageUrl} and ${rootUrl} substituted correctly
   - Test with various URL formats

6. **JSON Wildcard Extraction** (Property 6)
   - Generate JavaScript with random variable names
   - Generate wildcard patterns
   - Verify matching variables extracted

7. **JSON Type Support** (Property 7)
   - Generate random JSON of each type
   - Verify successful parsing
   - Verify type preservation

8. **Filter Patterns** (Property 8)
   - Generate random lists and filter patterns
   - Verify include patterns keep matching items
   - Verify exclude patterns remove matching items

9. **Filter Escaping** (Property 9)
   - Generate patterns with escaped characters
   - Verify literal character matching

10. **Index Operations** (Property 10)
    - Generate random lists and indices
    - Verify positive indices select correctly
    - Verify negative indices select from end

11. **Save/Discard Ordering** (Property 11)
    - Generate values with save and discard
    - Verify saved value is unwrapped

12. **Multi-Variable Extraction** (Property 12)
    - Generate JavaScript with multiple variables
    - Generate comma-separated variable lists
    - Verify all variables extracted

### Integration Testing

Integration tests verify the reorganized modules work together:

- Full pipeline execution with all transform types
- Backward compatibility with existing query strings
- Performance comparison with original implementation
- Cross-module interactions (e.g., regexp using context from pipeline)

### Migration Testing

Ensure the reorganization maintains backward compatibility:

- Run existing test suite against new implementation
- Verify all existing tests pass without modification
- Test that public API remains unchanged
- Verify barrel export (`transforms.dart`) works correctly

## Implementation Notes

### Backward Compatibility

The reorganization maintains 100% backward compatibility:

1. **Public API unchanged**: All existing functions remain accessible
2. **Barrel export**: Main `transforms.dart` re-exports all public APIs
3. **No breaking changes**: Existing code continues to work
4. **Internal only**: Reorganization is purely internal structure

### Migration Path

For code using the old global JS executor pattern:

```dart
// Old (still works)
setJsExecutorInstance(FlutterJsExecutor());

// New (preferred)
JsExecutorRegistry.register(FlutterJsExecutor());
```

Both patterns are supported during transition period.

### File Organization

```
lib/src/
├── transforms.dart (barrel export)
└── transforms/
    ├── transform_pipeline.dart
    ├── text_transforms.dart
    ├── data_transforms.dart
    ├── pattern_transforms.dart
    ├── selection_transforms.dart
    └── state_transforms.dart
```

### Dependencies

No new dependencies required. Existing dependencies:
- `logging` - Already used for logging
- `html` - For PageNode/PageData (existing)
- `dart:convert` - For JSON operations (existing)

### Performance Considerations

The reorganization should have minimal performance impact:

- No additional function call overhead (inlining possible)
- Same algorithmic complexity
- Potential for better tree-shaking with modular structure
- No additional memory allocations

### Future Enhancements

The new structure enables:

1. **Plugin system**: Easy to add new transform types
2. **Transform composition**: Combine transforms into reusable units
3. **Async transforms**: Support for async operations (future)
4. **Transform validation**: Pre-validate transform sequences
5. **Performance optimization**: Profile and optimize individual modules
6. **Better error messages**: Module-specific error context

## Summary

This reorganization transforms a 400+ line monolithic file into focused modules with clear responsibilities. The new structure improves:

- **Maintainability**: Each module has a single, clear purpose
- **Testability**: Isolated modules are easier to test
- **Discoverability**: Developers can quickly find relevant code
- **Extensibility**: New transforms follow established patterns

The design maintains complete backward compatibility while establishing a foundation for future enhancements.
