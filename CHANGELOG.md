## 0.8.1

- **New Text Transforms**: Added 4 new text transformation functions:
  - `base64` - Encode text to Base64
  - `base64decode` - Decode Base64 to text  
  - `reverse` - Reverse string characters
  - `md5` - Generate MD5 hash (32-character lowercase hex)
- **Comprehensive Documentation**: Added extensive module-level documentation to all transform modules
- **Migration Guide**: Added detailed migration documentation for JsExecutorRegistry
- **Usage Examples**: Added comprehensive examples for all transform types
- **Example App Enhancement**: Added comprehensive sample JSON data to example app
  - Realistic blog structure with articles, authors, categories, and configuration
  - Demonstrates JSON querying capabilities alongside HTML examples
  - Enables testing of deep search and JSON path features

### Changed
- **Transform Pipeline Architecture**: Refactored to enforce correct execution order regardless of parameter order in query string
- **Documentation Structure**: Reorganized and enhanced all transform module documentation with usage examples
- **Query Validation**: Fixed path formatting in query info extraction (removed leading slashes)
- **Error Messages**: Improved query validation error formatting

### Fixed
- **Critical Transform Pipeline Bug**: Transform execution order now guaranteed to be: transform → update → filter → index → save
  - Previously, execution order depended on map iteration order, causing unpredictable behavior
  - Now uses LinkedHashMap with explicit ordering to ensure deterministic execution
- **UI Enhancement**: DataQueryWidget HTML tree view now always shows children count
  - Children count visible in both collapsed and expanded states
  - Proper formatting: "(3 children)" instead of just "3"
  - Better visual hierarchy and user experience
- **Dead Code Removal**: Removed unused `discard` transform from pipeline (actual discard behavior handled at query level)
- **Test Failures**: Fixed 3 failing tests in query info extraction
- **Path Formatting**: Query info now shows paths without leading slashes for consistency

### Technical Details
- Added `crypto: ^3.0.3` dependency for MD5 hashing
- Centralized transform validation with `validTextTransforms` constant for easier maintenance

## 0.8.0

### Added
- **JSON Deep Search**: New `..` operator for recursive JSON key searching
  - `json:..keyName` - Find all occurrences of a key anywhere in the JSON structure
  - `json:path/..keyName` - Deep search within a specific path
  - `json:..*pattern` - Deep search with wildcard patterns (e.g., `..*_id` finds all keys ending in `_id`)
  - Automatically flattens list values when multiple matches are found

### Backward Compatibility
- ✅ 100% backward compatible - all existing code continues to work
- ✅ All existing APIs unchanged
- ✅ Deprecated functions still work with migration warnings
- ✅ Transform behavior identical except for guaranteed execution order

### Migration Notes
- **Recommended**: Use `JsExecutorRegistry.register()` instead of deprecated `setJsExecutorInstance()`
- **No Breaking Changes**: Existing code works without modification
- **Enhanced Reliability**: Transform pipeline now guarantees correct execution order

### Examples

```dart
// JSON Deep Search
'json:..id'                    // Find all 'id' keys anywhere
'json:wrapper/..target'        // Find 'target' only inside 'wrapper'
'json:..*_id'                  // Find all keys ending with '_id'

// Text Transforms
'json:message?transform=base64'     // Encode to Base64
'json:encoded?transform=base64decode' // Decode from Base64
'json:text?transform=reverse'       // Reverse string
'json:password?transform=md5'       // Generate MD5 hash
```

## 0.7.2

### Js Executor Improvements

- Increased max consecutive errors to 100
- improve js runtime mock environment setup, adding jwplay, jquery etc..
- to decrease error count

## 0.7.1

### UI Improvements

- **DataQueryWidget Enhancements**:
  - **Monospaced Font**: Added robust monospaced font stack (`Menlo`, `Monaco`, `Courier New`) for better code readability
  - **Larger Font Sizes**: Increased default font sizes for query results (Single Value: 15px, Collection: 14px, Validation: 13px)
  - **Adjustable Font Size**: Added +/- controls in header to adjust font size (50% to 200%)
  - **Result View Toggles**: Added checkboxes to independently show/hide single value and collection results
  - **Refactored Architecture**: Extracted UI components into `_DataReaderHeader`, `_QueryInput`, and `_FilterResultsView` for better maintainability

## 0.7.0

### New Features

- **Query Validation API**: Added comprehensive query validation with detailed error detection and suggestions
  - `QueryString.validate()` - Validate query syntax without executing
  - Detects invalid schemes with typo suggestions (e.g., "jsn" → "json")
  - Validates parameter syntax and suggests corrections
  - Warns about common regexp pattern mistakes (unescaped special characters)
  - Warns about template variable issues (missing `$`, empty variables, whitespace)
  - Returns `ValidationResult` with errors, warnings, and query structure information
  - Position tracking for all errors and warnings
  - Query part indexing to identify which part contains issues

- **Index Parameter**: Added `?index=` parameter to select the nth element from query results
  - Static index: `*div@?index=2` - Get 3rd element (0-indexed)
  - Variable index: `.link@href?regexp=/\d+/&save=idx ++ *div@?index=${idx}` - Use saved variable as index
  - Negative index: `*div@?index=-1` - Get last element
  - Works with any list result from queries
  - Can be combined with other transforms: `*div@?index=1&transform=upper`
  - Supports variable arithmetic: `?index=${i + 1}` for dynamic indexing

- **Array Pipe Operator (`>>>`)**: Added `>>>` operator to treat previous results as a whole JSON array
  - Enables JSON range operations: `*div@ >>> json:0-2` - Get first 3 elements
  - Multi-index selection: `*div@ >>> json:1,3,5` - Get elements at specific indices
  - Can be combined with regular pipe: `*div@ >>> json:0-4 >> json:name` - Get first 5, then extract name from each
  - **Key Difference from `>>`**: 
    - `>>` pipes each element individually (one at a time)
    - `>>>` treats the entire result as one JSON array (all at once)
  - Example: `*div@text >> json:length` gets length of each text vs `*div@text >>> json:length` gets count of all divs

- **Variable Arithmetic**: Added support for arithmetic expressions in variables
  - Use `${expression}` syntax for calculations (e.g., `${index + 1}`, `${count * 2}`)
  - Works in paths, index parameters, and templates
  - Powered by `function_tree` package for expression evaluation

- **Enhanced DataQueryWidget UI**:
  - Integrated validation feedback panel showing errors, warnings, and query structure
  - Real-time validation as you type (debounced)
  - Color-coded feedback (red for errors, orange for warnings, green for valid)
  - Scrollable filter area with proper layout
  - Displays results in order: getValue() → getCollectionValue() → Validation feedback
  - Each section takes only the space it needs

### Improvements

- **Smart Regex Validation**: Improved regex pattern validation to avoid false positives
  - Correctly recognizes valid patterns like `\d+`, `\w+`, `[a-z]+`, `(abc)+`
  - Only warns about genuinely suspicious patterns like `test.com` (unescaped dot)
  - Context-aware checking for quantifiers (`*`, `+`, `?`)

- **Better Error Messages**: All validation errors include:
  - Exact position in query string
  - Visual pointer to error location
  - Helpful suggestions for fixes
  - Example of correct syntax
  - Query part index for multi-part queries

### Bug Fixes

- Fixed `>>>` operator to correctly handle JSON array piping
- Fixed `jseval` regression where JS runtime wasn't being reset
- Fixed validation warnings not showing when query is valid
- Fixed false positive warnings for valid regex quantifiers

### API Examples

```dart
// Validate a query
final query = QueryString('jsn:items?save=x?keep');
final result = query.validate();

if (!result.isValid) {
  print('Errors: ${result.errors.length}');
  for (var error in result.errors) {
    print(error.format(query.query));
  }
}

// Index parameter
'*div@?index=2'                    // Get 3rd element
'*div@?index=-1'                   // Get last element
'*div@?index=${idx}'               // Use variable
'*div@?index=${i + 1}'             // Arithmetic

// Array pipe vs regular pipe
'*div@text >> json:length'         // Length of each text
'*div@text >>> json:length'        // Count of all divs
'*div@ >>> json:0-2'               // First 3 elements as array
'*div@ >> json:name'               // Extract name from each
```

### Technical Details

- Added `paramIndex` constant to `query_part.dart`
- Implemented `applyIndex` function in `transforms.dart`
- Index transform is applied to the result list after other transforms
- Supports negative indexing (e.g., -1 for last element)
- Returns null for out-of-bounds indices or empty lists
- `>>>` operator splits query at `>>>`, executes first part, converts result to JSON, then executes second part
- Added `function_tree` dependency for expression evaluation

### Documentation

- Added `VALIDATION_GUIDE.md` with comprehensive validation documentation
- Added `VALIDATION_ERRORS.md` with examples of all error types
- Updated README with validation examples and operator differences

## 0.6.4


### Bug Fixes

- **Template Scheme URL Parsing**: Fixed issue where template URLs containing query parameters were incorrectly parsed as QueryPart parameters.
  - Template content like `template:https://example.com/api?param=value` now works correctly
  - The `?` and `&` characters in template URLs are no longer treated as QueryPart parameter delimiters
  - Example: `template:https://www.example.com/api/${username}/query?timezoneOffset=-780&triggerRequest=load&primaryTag=${tag}` now works as expected

### Technical Details

- Modified `QueryPart.parse()` to add special handling for `template` scheme
- Template scheme now skips query parameter parsing entirely, treating the entire content as the template path

## 0.6.3


### Bug Fixes

- **Variable Resolution in QueryPart Parameters**: Fixed issue where saved variables were not being resolved in QueryPart parameters (e.g., URL query parameters, URL modification parameters).
  - Variables like `${vod}` are now properly resolved in all parameter contexts
  - Example: `json:vod_id?save=vod ++ url:?ac=videolist&ids=${vod}` now correctly produces `?ac=videolist&ids=12345` instead of `?ac=videolist&ids=%24%7Bvod%7D`
  - Affects all QueryPart parameters including `_host`, `_path`, filter values, etc.

### Technical Details

- Modified `_executeSingleQuery` in `query.dart` to resolve variables in both path and parameters before execution
- Created new `QueryPart` with resolved values to ensure proper variable substitution across all query schemes

## 0.6.2


### Fix bugs

- Fixed PageData.auto html not initialized.

## 0.6.1

### Improvements

- **Refactored Query Parsing**: Significant refactoring of `QueryPart.parse` for better maintainability and performance.
- **Robust Parameter Parsing**:
  - Fixed issue where reserved parameters without values (like `&keep`) were incorrectly consumed by preceding parameters.
  - Improved regex patterns to correctly identify parameter boundaries.
  - Added detailed comments to regex patterns for better developer experience.
- **Code Quality**:
  - Converted hardcoded scheme and parameter strings to constants.
  - Simplified transform splitting logic.

## 0.6.0

### New Features

- **JSON Path Wildcards**: Added wildcard support for JSON paths in queries

  - `json:flashvars_*` - Match all keys starting with "flashvars\_"
  - `json:*_config` - Match all keys ending with "\_config"
  - Works with piping: `jseval >> json:flashvars_*`
  - Returns Map with all matching keys

- **jseval Wildcard Matching**: JavaScript variable extraction now supports wildcards

  - `transform=jseval:flashvars_*` - Extract all matching variables
  - `transform=jseval:*_data,*_config` - Multiple patterns
  - Same wildcard syntax as JSON transform

- **Improved jseval Scope Handling**:
  - Fixed: `jseval:varName` now works correctly (uses indirect eval for global scope)
  - Auto-detect properly captures `var` declarations
  - Both specific and auto-detect modes use global scope execution

### Improvements

- **Better Error Handling**: jseval returns `null` instead of `{}` on errors

  - Consistent with other transforms
  - Empty results also return `null`
  - Easier to detect failures

- **Enhanced Browser Globals**: Added more mock objects

  - `window.addEventListener` and `removeEventListener`
  - `screen` object with width/height properties
  - `atob`/`btoa` for base64 encoding

- **Crash Prevention**: Improved JavaScript runtime stability
  - No runtime disposal (prevents crashes)
  - Smart variable clearing between queries
  - Runtime health checks
  - Better error recovery

### Bug Fixes

- Fixed: `jseval:varName` now extracts variables correctly (was returning null)
- Fixed: Empty variable results now return `null` instead of empty map
- Fixed: Runtime crashes from disposal operations

### Examples

```dart
// JSON path wildcards
'script/@text?transform=jseval >> json:flashvars_*'
// Returns: {flashvars_123: {...}, flashvars_456: {...}}

// jseval wildcards
'script/@text?transform=jseval:*_config,*_data'
// Returns: {app_config: {...}, user_data: {...}}

// Specific variable extraction (now works!)
'script/@text?transform=jseval:flashvars_343205161'
// Returns: {video_id: "343205161", ...}
```

## 0.5.0

### New Features

- **Keep Parameter**: Added `&keep` parameter to preserve intermediate values when using `?save=`

  - `?save=varName` - Save and auto-discard (cleaner templates)
  - `?save=varName&keep` - Save and keep in output
  - Selective keeping: Mix saved-only and saved-kept values in same query

- **Enhanced JSON Extraction**: Improved `transform=json` to extract JavaScript variables from `<script>` tags

  - Extract objects: `transform=json:config` matches `var config = {...}`
  - Extract arrays: `transform=json:items` matches `var items = [...]`
  - Extract primitives: `transform=json:count` matches `var count = 42`
  - Wildcard matching: `transform=json:*Config*` matches `var myConfig = {...}`
  - Supports multiple formats: `window.__DATA__`, `var data`, etc.

- **JavaScript Execution (jseval)**: Execute JavaScript code to extract variables from obfuscated scripts

  - Extract specific variables: `transform=jseval:var1,var2`
  - Wildcard matching: `transform=jseval:flashvars_*,*_config`
  - Auto-detect variables: `transform=jseval` (no variable names)
  - Browser globals support: `window`, `document`, `navigator`, `console`, `screen`, `atob`, `btoa`, `addEventListener`, etc.
  - Circular reference handling: Safely serializes objects with circular references
  - Error limiting: Stops after 10 consecutive errors to prevent crashes
  - Indirect eval: Uses global scope for proper `var` detection

- **Variable Substitution**: Use saved variables in query paths and regex patterns

  - Path substitution: `json:items/${id}` uses saved `id` variable
  - Regex substitution: `regexp:/${pattern}/replacement/` uses saved `pattern` variable
  - Template scheme: `template:${var1} ${var2}` combines multiple variables

- **Query Validation**: Added parameter validation with helpful error messages
  - Catches typos in parameter names
  - Validates transform formats
  - Suggests correct parameter names

### Improvements

- **Cleaner Template Syntax**: Templates no longer cluttered with intermediate values by default
- **More Intuitive**: Auto-discard matches common use case (extract data for templates)
- **JavaScript Safety**: Multiple layers of crash protection
  - Configurable size limits (default: 1MB script, 10MB result, 5MB wrapped)
  - Optional truncation for oversized scripts
  - Smart variable clearing: Clears globals between queries without disposing runtime
  - Only clears when query uses jseval (performance optimization)
  - Reuses runtime within same query for efficiency
  - Runtime health checks before execution
  - Consecutive error limiting (stops after 10 errors)
  - Automatic recovery on errors
  - Reduced error logging to prevent spam
  - No runtime disposal (prevents crashes)
- **Better Documentation**: Updated README, code docs, and added migration guide

### Examples

```dart
// Variable handling - After (0.5.0) - cleaner!
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
// Result: "Alice Smith"

// Keep intermediate values when needed
'json:firstName?save=fn&keep ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
// Result: ["Alice", "Smith", "Alice Smith"]

// Extract JavaScript variables from script tags
'script/@text?transform=json:window.__INITIAL_STATE__'
// Extracts: window.__INITIAL_STATE__ = {"user": {...}}

'script/@text?transform=json:*Config*'
// Matches: var myConfig = {...}, appConfig = {...}, etc.

// Use variables in paths
'json:selectedId?save=id ++ json:items/${id}/name'
// Gets item name using saved id

// Use variables in regex
'#pattern/@text?save=p ++ .content/@text?regexp:/${p}/replaced/'
// Replaces pattern found in first element
```

See [MIGRATION_KEEP.md](MIGRATION_KEEP.md) for detailed migration guide.

## 0.4.0

### Breaking Changes

- **Removed old protocol support**: The `newProtocol` parameter has been removed from `QueryString` and related functions. The library now exclusively uses the new protocol syntax.
- **Removed legacy files**: Deleted `selector.dart`, `expression.dart`, `separator.dart`, and `web_query.dart` (~20KB code reduction)

### New Features

- **UI Components** (exported via `package:web_query/ui.dart`):

  - `JsonTreeView`: Interactive collapsible JSON tree viewer with syntax highlighting
  - `HtmlTreeView`: Interactive collapsible HTML tree viewer
  - `DataQueryWidget`: Complete data reader widget with HTML/JSON views and query filtering
  - `filterHtmlOnly()` and `filterHtml()`: Utility functions with optional unwanted selectors
  - **JSON Transform**: Added `json` transform to extract JSON from `<script>` tags and JavaScript variables
    - Supports wildcard matching for variable names (e.g., `json:*Config*`)
  - **Query Piping**: Added `>>` operator to chain queries (output of one becomes input of next)
  - **New Selectors**:
    - `@keys`: Extract keys from JSON objects
  - **Variables & Templates**:
    - Save results with `?save=varName`
    - Use variables with `${varName}` in paths, regex, and templates
    - Combine results using `template:` scheme (e.g., `template:${a} ${b}`)

- **Modular Architecture**:
  - Extracted UI utilities into `html_utils.dart`, `html_tree_view.dart`, `json_tree_view.dart`
  - Better code organization and maintainability
  - Cleaner separation of concerns

### Improvements

- **Performance**: Tree views use lazy loading and show first 50 items with "Show more" functionality
- **Code Quality**: Removed ~20KB of legacy code
- **API Simplification**: Single protocol, cleaner API surface
- **Testing**: Added `PageData.auto` tests for automatic content type detection

### Migration Guide

If you were using the old protocol:

```dart
// Before (0.3.0 and earlier)
QueryString(query, newProtocol: false)
webValue(node, selectors, newProtocol: false)

// After (0.4.0+)
QueryString(query)
```

The old `Selectors` class and related APIs have been removed. Use `QueryString` with the new protocol syntax instead.

## 0.3.0

### What's New

- **URL Scheme**: Added `url:` scheme for querying and modifying URLs

  - Query URL components: `url:host`, `url:path`, `url:query`, `url:fragment`, etc.
  - Query parameters: `url:queryParameters/key`
  - Modify URLs: `url:?page=2`, `url:?_host=new.com`
  - Supports all transforms including `regexp`

- **Simplified Regexp Syntax**: Added `?regexp=` as shorthand for `?transform=regexp:`

  - `?regexp=/pattern/` - Pattern-only mode
  - `?regexp=/pattern/replacement/` - Replace mode
  - Multiple regexp params are chained: `?regexp=/a/b/&regexp=/c/d/`

- **Multiline Regexp Support**:

  - `multiLine: true` enabled by default for all regexp operations
  - `\ALL` keyword matches entire content (expands to `^[\s\S]*$`)
  - Better handling of newlines in patterns

- **DataQueryWidget UI Component**:

  - Interactive HTML tree view with collapsible nodes
  - Real-time QueryString filtering
  - Switch between HTML and JSON views
  - Visual query results panel
  - Example project demonstrating usage

- **Examples**:

  ```dart
  // URL queries
  'url:host'                    // Get hostname
  'url:?page=2'                 // Modify query param
  'url:?regexp=/https/http/'    // Transform URL

  // Simplified regexp
  'h1@text?regexp=/Title/Header/'
  '*li@text?regexp=/\ALL/Replaced/'

  // Multiline matching
  'div@text?regexp=/^Line 2/Matched/'  // Match start of line
  'div@text?regexp=/\ALL/Replaced/'    // Match all content
  ```

## 0.2.8

### What's New

- **Filter Transform**: Added powerful `filter` parameter to filter query results
  - Include filters: `filter=word` matches items containing "word"
  - Exclude filters: `filter=!word` excludes items containing "word"
  - Combined filters: `filter=a !b` includes "a" AND excludes "b"
  - Escaped characters: Support for `\ ` (space), `\;` (semicolon), `\&` (ampersand)
- **Enhanced Parameter Parsing**:

  - Smart handling of `&` in `transform`, `filter`, and `update` parameters
  - Intelligent semicolon splitting for `regexp` transforms (preserves `;` within `/pattern/replacement/`)
  - Proper escaping/unescaping for special characters

- **Examples**:

  ```dart
  // Filter by inclusion
  '*li/@text?filter=Apple'

  // Filter by exclusion
  '*li/@text?filter=!Banana'

  // Combined filters
  '*li/@text?filter=fruit !bad'

  // With escaped characters
  '*li/@text?filter=Date\ Fruit'  // Matches "Date Fruit"
  '*li/@text?filter=\&'            // Matches items with "&"

  // Mixed with transforms
  '*li/@text?transform=regexp:/Fig/Big/&filter=&'
  ```

## 0.2.7

- adding filter transform to filter result.

## 0.2.6

- make / before @ optional
- fix transform regexp cannot have & bug.

## 0.2.5

- adding `*+` and `*-` to navigate siblings.

## 0.2.0

- breaking change:
  - after || part mean optional (previous version is required)
  - , default is required. (previous version is optional)
  - adding ++ & mean required.
  - adding | mean optional.
  - remove required?= parameter
  - remove !suffix in json path part.
- adding ++ and || separator to query statement. (part after ++ mean required)
- adding | and , to separate multi path (part after | mean optional , after `,` mean required)
- adding | to attribute to support multi attributes (part after | mean optional )

## 0.1.1

- Fixed bug with query paramters include ? and chinese.

## 0.1.0

- Added new QueryString API with features:
  - Simplified scheme syntax (`json:` and `html:` prefixes)
  - HTML selectors with `*` prefixes
  - Default HTML scheme
  - Class name checking with `@.class`
  - Wildcard class name matching
  - Transform operations
  - Query chaining
  - Required/optional queries
  - RegExp transforms
  - Better error handling

## 0.0.5

- Support for escape characters in selectors
- Fixed handling of + in query strings

## 0.0.4

- Initial version with basic web querying functionality
- HTML element selection
- JSON path navigation
- Basic attribute access

## 0.0.1

- initial release.
