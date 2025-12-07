# Web Query

A powerful Flutter library for querying HTML and JSON data using a simple, intuitive syntax. Extract data from web pages and JSON responses with CSS-like selectors, JSONPath-style navigation, and advanced filtering capabilities.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Complete Syntax Reference](#complete-syntax-reference)
  - [Query Schemes](#query-schemes)
  - [HTML Selectors](#html-selectors)
  - [JSON Path Navigation](#json-path-navigation)
  - [Attribute Accessors](#attribute-accessors)
  - [Navigation Operators](#navigation-operators)
  - [Query Parameters](#query-parameters)
  - [Transforms](#transforms)
  - [Query Piping](#query-piping)
  - [Filters](#filters)
  - [Query Chaining](#query-chaining)
  - [Query Validation](#query-validation)
- [Advanced Usage](#advanced-usage)
- [API Reference](#api-reference)
- [Migration Guide](#migration-guide)

## Features

✨ **Simple & Intuitive Syntax**

- CSS-like selectors for HTML elements
- JSONPath-style navigation for JSON data
- Unified query interface for both HTML and JSON

🔍 **Powerful Querying**

- Element navigation (parent, child, siblings)
- Class name matching with wildcards
- Multiple attribute accessors
- Array indexing and range selection

🔧 **Data Transformation**

- Text transformations (uppercase, lowercase)
- RegExp pattern matching and replacement
- Variable substitution (pageUrl, rootUrl)
- Chainable transforms

🎯 **Advanced Filtering**

- Include/exclude filters
- Combined filter conditions
- Support for special characters

🔗 **Query Composition**

- Fallback queries with `||`
- Required queries with `++`
- Per-query transformations

✅ **Query Validation**

- Optional syntax validation with detailed error messages
- Smart typo suggestions and corrections
- Position-based error reporting
- Query information extraction
- JSON output for logging and APIs

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  web_query: ^0.8.7
```

Then run:

```bash
flutter pub get
```

## Quick Start

### HTML Query Example

```dart
import 'package:web_query/query.dart';

const html = '''
<div class="article">
  <h1>Article Title</h1>
  <p class="author">John Doe</p>
  <div class="content">
    <p>First paragraph</p>
    <p>Second paragraph</p>
  </div>
</div>
''';

final pageData = PageData("https://example.com", html);
final node = pageData.getRootElement();

// Get article title
final title = QueryString('h1/@text').getValue(node);
// Result: "Article Title"

// Get all paragraphs
final paragraphs = QueryString('*p/@text').getCollectionValue(node);
// Result: ["John Doe", "First paragraph", "Second paragraph"]

// Get content paragraphs only
final content = QueryString('.content/*p/@text').getCollectionValue(node);
// Result: ["First paragraph", "Second paragraph"]
```

### JSON Query Example

```dart
import 'dart:convert';
import 'package:web_query/query.dart';

const jsonData = {
  "user": {
    "name": "Alice",
    "email": "alice@example.com",
    "posts": [
      {"title": "First Post", "likes": 10},
      {"title": "Second Post", "likes": 25}
    ]
  }
};

final pageData = PageData(
  "https://api.example.com",
  "<html></html>",
  jsonData: jsonEncode(jsonData)
);
final node = pageData.getRootElement();

// Get user name
final name = QueryString('json:user/name').getValue(node);
// Result: "Alice"

// Get all post titles
final titles = QueryString('json:user/posts/*/title').getCollectionValue(node);
// Result: ["First Post", "Second Post"]

// Get first post
final firstPost = QueryString('json:user/posts/0/title').getValue(node);
// Result: "First Post"
```

## Complete Syntax Reference

### Query Schemes

Queries can target HTML, JSON, or URL data:

| Scheme  | Description                             | Example                   |
| ------- | --------------------------------------- | ------------------------- |
| `html:` | Query HTML elements (optional, default) | `html:div/p/@text`        |
| `json:` | Query JSON data                         | `json:user/name`          |
| `url:`  | Query and modify URLs                   | `url:host`, `url:?page=2` |
| (none)  | Defaults to HTML                        | `div/p/@text`             |

### HTML Selectors

#### Basic Selectors

```dart
// CSS selectors
'div'                    // First div element
'div.classname'          // Div with specific class
'#id'                    // Element by ID
'div > p'                // Direct child
'div p'                  // Descendant

// Selector prefixes
'*p'                     // ALL paragraphs (querySelectorAll)
'p'                      // FIRST paragraph (querySelector)
'.content/*div'          // All divs in .content
'.content/div'           // First div in .content
```

#### Complex Selectors

```dart
// Attribute selectors
'a[href]'                // Links with href attribute
'input[type="text"]'     // Text inputs
'div[data-id="123"]'     // Custom data attributes

// Pseudo-classes
'li:first-child'         // First list item
'tr:nth-child(2)'        // Second table row
'p:not(.excluded)'       // Paragraphs without class
```

### JSON Path Navigation

#### Basic Paths

```dart
'json:user/name'              // Object property
'json:users/0'                // Array index (first item)
'json:users/1'                // Array index (second item)
'json:users/*'                // All array items
'json:users/0-2'              // Array range (items 0, 1, 2)
```

#### Nested Paths

```dart
'json:data/users/0/profile/name'     // Deep nesting
'json:response/items/*/title'        // All titles from array
'json:config/settings/api/endpoint'  // Multi-level objects
```

#### Multiple Paths

```dart
// Comma-separated (all required)
'json:user/name,user/email'          // Get both name and email
'json:meta/title,meta/description'   // Multiple meta fields

// Pipe-separated (optional fallback)
'json:title|meta/title'              // Try title, fallback to meta/title
```

#### Deep Search (New in 0.8.0)

Use the `..` operator to recursively search for keys anywhere in the JSON structure:

```dart
// Find all occurrences of a key
'json:..id'                          // Find all 'id' keys at any depth
'json:..title'                       // Find all 'title' keys anywhere

// Deep search within a specific path
'json:wrapper/..target'              // Find 'target' only inside 'wrapper'
'json:users/..email'                 // Find all emails within users

// Deep search with wildcards
'json:..*_id'                        // Find all keys ending with '_id'
'json:..user_*'                      // Find all keys starting with 'user_'

// Example with nested data
const data = {
  'id': 1,
  'items': [
    {'id': 2, 'name': 'item2'},
    {'id': 3, 'nested': {'id': 4}}
  ],
  'other': {'id': 5}
};

'json:..id'                          // Returns: [1, 2, 3, 4, 5]
'json:items/..id'                    // Returns: [2, 3, 4]
```

**Note**: Deep search automatically flattens list values when multiple matches are found.

### Attribute Accessors

Attribute accessors extract data from HTML elements:

| Accessor                | Description               | Example                                |
| ----------------------- | ------------------------- | -------------------------------------- |
| `@` or `@text`          | Text content              | `div/@text`                            |
| `@html` or `@innerHtml` | Inner HTML                | `div/@html`                            |
| `@outerHtml`            | Outer HTML                | `div/@outerHtml`                       |
| `@href`, `@src`, etc.   | Specific attribute        | `a/@href`, `img/@src`                  |
| `@.classname`           | Check class existence     | `div/@.active` → "true" or null        |
| `@.prefix*`             | Class with prefix         | `div/@.btn*` → matches "btn-primary"   |
| `@.*suffix`             | Class with suffix         | `div/@.*-lg` → matches "btn-lg"        |
| `@.*part*`              | Class containing text     | `div/@.*active*` → matches "is-active" |
| `@attr1\|attr2`         | First available attribute | `img/@src\|data-src`                   |

#### Class Matching Examples

```dart
// Exact class check
'div/@.featured'              // Returns "true" if class exists, null otherwise

// Wildcard patterns
'button/@.btn*'               // Matches: btn-primary, btn-secondary, btn-large
'div/@.*-active'              // Matches: is-active, user-active
'span/@.*icon*'               // Matches: icon-home, fa-icon, icon

// Multiple class check (OR logic)
'div/@.primary|.secondary'    // Has either primary OR secondary class
```

### Navigation Operators

Navigate the DOM tree from a selected element:

| Operator | Description           | Example  |
| -------- | --------------------- | -------- |
| `^`      | Parent element        | `p/^`    |
| `^^`     | Root element          | `p/^^`   |
| `>`      | First child           | `div/>`  |
| `+`      | Next sibling          | `div/+`  |
| `*+`     | All next siblings     | `div/*+` |
| `-`      | Previous sibling      | `div/-`  |
| `*-`     | All previous siblings | `div/*-` |

#### Navigation Examples

```dart
// Parent navigation
'.content/p/^'                // Parent of paragraph in .content
'.nested/div/^/^'             // Grandparent

// Sibling navigation
'h1/+'                        // Element after h1
'h1/*+'                       // All elements after h1
'.item/+/+'                   // Skip one, get next

// Child navigation
'.container/>'                // First child of container
'.container/>/p'              // First p in first child
```

### Query Parameters

Parameters modify query behavior and transform results:

```dart
// Basic syntax
'selector/@attr?param1=value1&param2=value2'

// Multiple parameters
'div/@text?transform=upper&filter=important'
```

#### Index Parameter

Select a specific element from query results using `?index=`:

```dart
// Static index (0-based)
'*div@?index=0'                    // Get first element
'*div@?index=2'                    // Get 3rd element
'*div@text?index=1'                // Get 2nd div's text

// Negative index (from end)
'*div@?index=-1'                   // Get last element
'*div@?index=-2'                   // Get second-to-last element

// Variable index
'.link@href?regexp=/\d+/&save=idx ++ *div@?index=${idx}'
// Extract number from link, use it as index

// With arithmetic
'json:page?save=p ++ *div@?index=${p * 10}'
// Calculate index from variable

// Combined with transforms
'*div@text?index=1&transform=upper'
// Get 2nd div's text and uppercase it
```

**Notes:**

- Returns `null` for out-of-bounds indices
- Works with any list result (HTML elements, JSON arrays, etc.)
- Applied after other transforms
- Supports variable substitution and arithmetic expressions

### Transforms

Transforms modify the extracted data:

#### Text Transforms

```dart
// Case conversion
'@text?transform=upper'                    // UPPERCASE
'@text?transform=lower'                    // lowercase

// Base64 encoding/decoding (New in 0.8.1)
'@text?transform=base64'                   // Encode to Base64
'@text?transform=base64decode'             // Decode from Base64

// String manipulation (New in 0.8.1)
'@text?transform=reverse'                  // Reverse string characters

// Hashing (New in 0.8.1)
'@text?transform=md5'                      // Generate MD5 hash

// Chained transforms
'@text?transform=upper;lower'              // Apply multiple
'@text?transform=upper;base64'             // Uppercase then encode
```

#### Simplified Regexp Syntax

Use `?regexp=` as a shorthand for `?transform=regexp:`:

```dart
// Pattern matching
'@text?regexp=/\d+/'                       // Extract numbers

// Pattern replacement
'@text?regexp=/old/new/'                   // Replace text

// Multiple regexp transforms
'@text?regexp=/a/b/&regexp=/c/d/'          // Chain multiple
```

#### RegExp Transforms

```dart
// Pattern matching (returns matched text or null)
'@text?transform=regexp:/\d+/'            // Extract numbers
'@text?transform=regexp:/[A-Z][a-z]+/'    // Extract capitalized words

// Pattern replacement
'@text?transform=regexp:/old/new/'        // Replace text
'@href?transform=regexp:/^\/(.+)/${rootUrl}$1/'  // Make absolute URL

// With capture groups
'@text?transform=regexp:/(\\d{4})-(\\d{2})-(\\d{2})/$2\\/$3\\/$1/'  // Reformat date

// Multiline support (enabled by default)
'div@text?regexp=/^Line 2/Matched/'       // Match start of line
'div@text?regexp=/\\ALL/Replaced/'         // Match entire content
```

#### Special RegExp Keywords

| Keyword | Description          | Expands To  |
| ------- | -------------------- | ----------- |
| `\ALL`  | Match entire content | `^[\s\S]*$` |

#### RegExp Variables

| Variable        | Description            | Example                    |
| --------------- | ---------------------- | -------------------------- |
| `${pageUrl}`    | Full page URL          | `https://example.com/page` |
| `${rootUrl}`    | Origin (scheme + host) | `https://example.com`      |
| `$1`, `$2`, ... | Capture groups         | From regex pattern         |
| `$0`            | Full match             | Entire matched text        |

#### Transform Examples

```dart
// URL manipulation
'img/@src?transform=regexp:/^\/(.+)/${rootUrl}$1/'
// "/image.jpg" → "https://example.com/image.jpg"

// Text extraction
'@text?transform=regexp:/Price: \$(\d+\.\d{2})/$1/'
// "Price: $19.99" → "19.99"

// Base64 encoding (New in 0.8.1)
'json:apiKey?transform=base64'
// "secret123" → "c2VjcmV0MTIz"

// Base64 decoding (New in 0.8.1)
'json:encoded?transform=base64decode'
// "SGVsbG8gV29ybGQ=" → "Hello World"

// String reversal (New in 0.8.1)
'json:text?transform=reverse'
// "Hello" → "olleH"

// MD5 hashing (New in 0.8.1)
'json:password?transform=md5'
// "test" → "098f6bcd4621d373cade4e832627b4f6"

// Multiple transforms
'@text?transform=regexp:/\s+/ /;upper;regexp:/HELLO/HI/'
// "hello  world" → "HI WORLD"

// Chain new transforms
'json:text?transform=upper;base64'
// "hello" → "HELLO" → "SEVMTE8="
```

#### JSON Transform

Extract JSON data from `<script>` tags or JavaScript variables:

```dart
// Extract from <script type="application/json">
'script#data/@text?transform=json'

// Extract from JavaScript variable
'script/@text?transform=json:config'          // var config = {...}
'script/@text?transform=json:window.__DATA__' // window.__DATA__ = {...}

// Chain with JSON query
'script#data/@text?transform=json >> json:items/0/title'

// Wildcard variable matching (supports objects, arrays, and primitives)
'script/@text?transform=json:*Config*'        // Matches var myConfig = {...}
'script/@text?transform=json:count'           // Matches var count = 42;
```

### Query Piping

Pass the output of one query as the input to the next:

**Regular Pipe (`>>`)** - Processes each element individually:

```dart
// Get container -> Get paragraphs -> Get text
'.container >> *p >> @text'

// Get JSON items -> Get tags -> Flatten all tags
'json:items/* >> json:tags/*'

// Each element is processed separately
'*div@text >> json:length'
// Gets length of each div's text individually
```

**Array Pipe (`>>>`)** - Treats all results as one JSON array:

```dart
// Get first 3 elements
'*div@ >>> json:0-2'

// Get specific indices
'*div@ >>> json:1,3,5'
// Returns elements at positions 1, 3, and 5

// Get count of all elements
'*div@text >>> json:length'
// Returns total number of divs (not length of each text)

// Combine with regular pipe
'*div@ >>> json:0-4 >> json:name'
// Get first 5 elements, then extract name from each
```

**Key Differences:**

| Feature    | `>>` (Regular Pipe)   | `>>>` (Array Pipe)    |
| ---------- | --------------------- | --------------------- |
| Processing | One element at a time | All elements as array |
| Use case   | Transform each item   | Array operations      |
| Example    | `*div >> json:name`   | `*div >>> json:0-2`   |
| Result     | Flattened list        | Array subset          |

**When to use `>>`:**

- Extracting properties from each element
- Transforming each item individually
- Nested parsing (HTML in JSON)

**When to use `>>>`:**

- Array slicing and indexing
- Getting array length/count
- Range selection
- Multi-index selection

#### Special Selectors

- **`@keys`**: Get keys of a JSON object

  ```dart
  'json:users/@keys' // Returns ["alice", "bob"]
  ```

#### Nested Parsing (HTML in JSON)

Use `>>` to parse HTML strings embedded in JSON:

```dart
// JSON: { "comments": ["<div class='user'>Alice</div>", ...] }
'json:comments/* >> html:.user/@text'
// Result: ["Alice", ...]
```

**Piping vs Transform:**

Both can extract JSON from HTML, but they work differently:

```dart
// Using transform (parses JSON but returns the whole object)
'script#data/@text?transform=json'
// Result: {"user": "Alice", "id": 123}

// Using pipe (parses JSON AND queries it)
'script#data/@text >> json:user'
// Result: "Alice"

// To make transform equivalent, chain with pipe:
'script#data/@text?transform=json >> json:user'
// Result: "Alice"
```

**When to use `>>`:**

- Processing collections (e.g., list of HTML/JSON strings)
- Switching context between schemes (HTML ↔ JSON)
- Cleaner syntax for multi-step parsing

**When to use `transform=json`:**

- Extracting JavaScript variables from script tags (e.g., `transform=json:*Config*`)
- Getting the full JSON object without further querying

#### JavaScript Execution (jseval)

Execute JavaScript code to extract variables from obfuscated or eval-based scripts:

```dart
import 'package:web_query/js.dart';

// Configure the JavaScript executor (once at app startup)
configureJsExecutor(FlutterJsExecutor());

// Extract variables from JavaScript
'script/@text?transform=jseval:config'
// Executes the script and extracts the 'config' variable

// Extract multiple variables
'script/@text?transform=jseval:userId,userName,isActive'
// Returns: {"userId": 123, "userName": "Alice", "isActive": true}

// Works with eval() and obfuscated code
'script/@text?transform=jseval:secret'
// Handles: eval('var secret = "hidden_value";')

// Chain with other transforms
'script/@text?transform=jseval:title;upper'
// Extract and uppercase
```

**Requirements:**

- Import `package:web_query/js.dart`
- Call `configureJsExecutor(FlutterJsExecutor())` before using jseval
- Uses `flutter_js` package for JavaScript execution

**Browser Globals:**
The JavaScript runtime automatically provides common browser globals:

- `window` - Alias to globalThis
- `document` - Mock document object with common properties
- `console` - Mock console (log, warn, error, etc.)
- `navigator` - Mock navigator with userAgent, language, etc.
- `location` - Mock location object
- `localStorage` / `sessionStorage` - Mock storage APIs
- `setTimeout` / `setInterval` - Mock timer functions

**Use cases:**

- Extracting data from obfuscated JavaScript
- Handling eval()-based variable assignments
- Processing dynamically generated JavaScript code
- Extracting configuration from inline scripts
- Working with scripts that reference window/document objects

#### Variables and Templates

Save intermediate results and combine them using templates:

```dart
// Save variable
'json:title?save=t'

// Use variable in path, regex, or template
'json:items/${id}'
'regexp:/${pattern}/replacement/'
'template:Title: ${t}'

// Combine results (save auto-discards intermediate values)
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
// Result: "Alice Smith" (intermediate values auto-discarded)

// Keep intermediate results with &keep
'json:firstName?save=fn&keep ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
// Result: ["Alice", "Smith", "Alice Smith"]

// Selective keeping
'json:firstName?save=fn ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
// Result: ["Smith", "Alice Smith"] (only lastName and template kept)
```

**Note:** When using `?save=`, results are automatically omitted from the final output unless you add `&keep`. This makes templates cleaner by default.

### Filters

Filters remove unwanted results based on content:

#### Basic Filters

```dart
// Include filter (must contain)
'*li/@text?filter=apple'              // Only items containing "apple"

// Exclude filter (must NOT contain)
'*li/@text?filter=!banana'            // Exclude items with "banana"

// Combined filters (AND logic)
'*li/@text?filter=fruit !bad'         // Contains "fruit" AND NOT "bad"
```

#### Escaped Characters

```dart
// Escaped space (literal space in filter term)
'*li/@text?filter=Date\ Fruit'        // Match "Date Fruit"

// Escaped semicolon
'*li/@text?filter=A\;B'               // Match "A;B"

// Escaped ampersand
'*li/@text?filter=\&'                 // Match items with "&"
```

#### Filter Examples

```dart
// Product filtering
'*div.product/@text?filter=available !sold'
// Products that are available but not sold

// Multi-word matching
'*p/@text?filter=important urgent'
// Paragraphs containing both "important" AND "urgent"

// Complex filtering with transforms
'*a/@href?transform=lower&filter=.pdf !draft'
// PDF links that aren't drafts
```

### Query Chaining

Combine multiple queries for fallback or required data:

#### Fallback Queries (`||`)

```dart
// Try first, fallback to second if empty
'json:meta/title||h1/@text'
// Use JSON title if available, otherwise h1 text

// Multiple fallbacks
'json:image||img/@src||@data-image'
// Try JSON, then src attribute, then data-image
```

#### Required Queries (`++`)

```dart
// Execute all queries (combine results)
'json:meta/title++json:meta/description'
// Get both title AND description

// Mixed HTML and JSON
'h1/@text++json:meta/keywords++.author/@text'
// Get title, keywords, and author
```

#### Combined Chaining

```dart
// Fallback with required parts
'json:title||h1/@text++json:description||.content/@text'
// (title OR h1) AND (description OR content)

// Per-query transforms
'json:title?transform=upper||h1/@text?transform=lower'
// Uppercase JSON title, or lowercase h1
```

### Query Validation

The library provides comprehensive query validation to help you catch syntax errors and understand your queries better. Validation is **optional** and separate from query execution, so validation bugs won't prevent your queries from running.

#### Basic Validation

Call `validate()` on any QueryString to check for syntax errors:

```dart
final query = QueryString('json:items?save=x&keep ++ template:${x}');
final result = query.validate();

if (result.isValid) {
  print('Query is valid!');
  print(result); // Shows detailed query information
} else {
  print('Query has errors:');
  print(result); // Shows all errors with helpful messages
}
```

#### Validation Features

✅ **Comprehensive Error Detection**

- Invalid scheme names (e.g., `jsn:` instead of `json:`)
- Missing separators (e.g., `json items` instead of `json:items`)
- Malformed parameters (e.g., `?save=x?keep` instead of `?save=x&keep`)
- Unmatched variable syntax (e.g., `${var` without closing `}`)
- Invalid operators (e.g., `+` instead of `++`)

✅ **Smart Suggestions**

- Typo correction for scheme names
- Example corrections for common mistakes
- Position indicators showing exactly where errors occur

✅ **Query Information**

- Detailed breakdown of query parts
- List of operators used
- Variables extracted
- Parameters and transforms per part

#### ValidationResult API

The `validate()` method returns a `ValidationResult` object:

```dart
class ValidationResult {
  bool get isValid;              // True if no errors
  bool get hasWarnings;          // True if warnings exist
  List<ValidationError> errors;  // All errors found
  List<ValidationWarning> warnings; // Potential issues
  QueryInfo? info;               // Detailed query info (when valid)

  String toString();             // Human-readable format
  String toJson();               // JSON format for logging/APIs
}
```

#### Common Validation Errors

##### Invalid Scheme

```dart
// ❌ Error: Invalid scheme
final query = QueryString('jsn:items');
final result = query.validate();

// Output:
// Error at position 0: Invalid scheme 'jsn'
//
// Query: jsn:items
//        ^^^
//
// Did you mean 'json'? Valid schemes are: html, json, url, template
```

##### Missing Scheme Separator

```dart
// ❌ Error: Missing colon after scheme
final query = QueryString('json items');
final result = query.validate();

// Output:
// Error at position 4: Missing ":" after scheme "json"
//
// Query: json items
//            ^
//
// Use: json:items
```

##### Parameter Syntax Error

```dart
// ❌ Error: Multiple ? without &
final query = QueryString('json:items?save=x?keep');
final result = query.validate();

// Output:
// Error at position 20: Multiple "?" found in parameters
//
// Query: json:items?save=x?keep
//                         ^
//
// Example: ?param1=value&param2=value
```

##### Unmatched Variable Syntax

```dart
// ❌ Error: Unclosed variable
final query = QueryString('template:Hello ${name');
final result = query.validate();

// Output:
// Error at position 22: Unmatched "${" in variable syntax
//
// Query: template:Hello ${name
//                       ^^
//
// Variables should be: ${varName}
```

##### Invalid Operator

```dart
// ❌ Error: Invalid operator
final query = QueryString('json:a + json:b');
final result = query.validate();

// Output:
// Error at position 7: Invalid operator "+"
//
// Query: json:a + json:b
//               ^
//
// Valid operators are: ++, ||, >>, >>>
```

#### Query Information (Valid Queries)

When a query is valid, `ValidationResult` provides detailed information:

```dart
final query = QueryString('json:items?save=x&keep ++ template:${x}');
final result = query.validate();

print(result);

// Output:
// Query Information:
//   Total parts: 2
//   Operators: ++
//   Variables: x
//   Parts:
//     1. json:items [params: save, keep]
//     2. template:${x}
```

#### JSON Output

Get validation results as JSON for logging or API integration:

```dart
final query = QueryString('jsn:items');
final result = query.validate();

print(result.toJson());

// Output:
// {
//   "query": "jsn:items",
//   "isValid": false,
//   "errors": [
//     {
//       "message": "Invalid scheme 'jsn'",
//       "position": 0,
//       "suggestion": "Did you mean 'json'?",
//       "example": "Valid schemes are: html, json, url, template"
//     }
//   ],
//   "warnings": [],
//   "info": null
// }
```

#### Multiple Errors

Validation reports **all** errors found, not just the first one:

```dart
final query = QueryString('jsn:items?save=x?keep ++ template:${name');
final result = query.validate();

print(result);

// Output:
// Errors (3):
// Error at position 0: Invalid scheme 'jsn'
// ...
// Error at position 18: Multiple "?" found in parameters
// ...
// Error at position 41: Unmatched "${" in variable syntax
// ...
```

#### Validation Best Practices

**Development & Testing:**

```dart
test('query syntax is valid', () {
  final query = QueryString(myQueryString);
  final result = query.validate();

  expect(result.isValid, isTrue);
  expect(result.info!.totalParts, equals(2));
  expect(result.info!.operators, contains('++'));
});
```

**Debugging:**

```dart
// Validate during development to catch issues early
final query = QueryString(complexQueryString);
final result = query.validate();

if (!result.isValid) {
  print('Fix these errors:');
  print(result);
  return;
}

// Execute only if valid
final data = query.execute(node);
```

**Production (Optional):**

```dart
// Validation is optional - queries execute normally without it
final query = QueryString(userInput);

// Optionally validate in debug mode
if (kDebugMode) {
  final result = query.validate();
  if (result.hasWarnings) {
    logger.warn('Query warnings: ${result.toJson()}');
  }
}

// Execute regardless of validation
final data = query.execute(node);
```

**API/Logging:**

```dart
// Send validation results to monitoring/logging systems
final query = QueryString(userQuery);
final result = query.validate();

await analytics.logEvent('query_validation', {
  'query': result.query,
  'isValid': result.isValid,
  'errorCount': result.errors.length,
  'details': result.toJson(),
});
```

#### Validation Error Reference

| Error Type            | Cause                    | Solution                                      |
| --------------------- | ------------------------ | --------------------------------------------- |
| **Invalid scheme**    | Scheme not in valid list | Use: `html:`, `json:`, `url:`, or `template:` |
| **Missing separator** | Scheme without `:`       | Add `:` after scheme: `json:path`             |
| **Parameter syntax**  | Multiple `?` without `&` | Use `&` for additional params: `?a=1&b=2`     |
| **Variable syntax**   | Unmatched `${` or `}`    | Ensure variables are: `${varName}`            |
| **Invalid operator**  | Unknown operator         | Use: `++`, `\|\|`, `>>`, or `>>>`             |

#### Why Validation is Separate

Validation is **opt-in** and doesn't run automatically because:

1. **Performance**: Validation adds minimal overhead, but skipping it makes queries slightly faster
2. **Safety**: Bugs in validation logic won't prevent queries from executing
3. **Flexibility**: You can validate in development/testing but skip in production
4. **Debugging**: You can debug validation issues independently from query execution

#### Additional Resources

- **[Validation Guide](VALIDATION_GUIDE.md)** - Comprehensive guide with examples and best practices
- **[Error Reference](VALIDATION_ERRORS.md)** - Quick reference for common errors and fixes
- **[Migration Guide](#migration-guide)** - Information about adopting validation in existing projects

## Advanced Usage

### Complete Example: Web Scraping

```dart
import 'package:web_query/query.dart';
import 'package:http/http.dart' as http;

Future<void> scrapeArticle(String url) async {
  // Fetch HTML
  final response = await http.get(Uri.parse(url));
  final pageData = PageData(url, response.body);
  final node = pageData.getRootElement();

  // Extract article data
  final title = QueryString('h1.title/@text').getValue(node);
  final author = QueryString('.author/@text||.byline/@text').getValue(node);
  final date = QueryString('.date/@text?transform=regexp:/(\d{4}-\d{2}-\d{2})/$1/').getValue(node);
  final content = QueryString('.article-body/*p/@text').getCollectionValue(node);
  final images = QueryString('.article-body/*img/@src?transform=regexp:/^\/(.+)/${rootUrl}$1/').getCollectionValue(node);

  print('Title: $title');
  print('Author: $author');
  print('Date: $date');
  print('Paragraphs: ${content.length}');
  print('Images: $images');
}
```

### Working with JSON APIs

```dart
import 'dart:convert';
import 'package:web_query/query.dart';
import 'package:http/http.dart' as http;

Future<void> fetchUserData(String userId) async {
  final response = await http.get(
    Uri.parse('https://api.example.com/users/$userId')
  );

  final pageData = PageData(
    response.request!.url.toString(),
    '<html></html>',
    jsonData: response.body
  );
  final node = pageData.getRootElement();

  // Extract user data
  final name = QueryString('json:data/user/name').getValue(node);
  final email = QueryString('json:data/user/email').getValue(node);
  final posts = QueryString('json:data/user/posts/*/title').getCollectionValue(node);

  print('Name: $name');
  print('Email: $email');
  print('Posts: $posts');
}
```

### Filtering and Transforming Lists

```dart
// Get all product names that are in stock and on sale
final products = QueryString(
  '*div.product/*span.name/@text?filter=!Out\ of\ Stock sale'
).getCollectionValue(node);

// Get all links, make them absolute, filter PDFs
final pdfLinks = QueryString(
  '*a/@href?transform=regexp:/^\/(.+)/${rootUrl}$1/&filter=.pdf'
).getCollectionValue(node);

// Extract prices and format them
final prices = QueryString(
  '*span.price/@text?transform=regexp:/\$(\d+\.\d{2})/$1/'
).getCollectionValue(node);
```

### Global Variables and Initial Variables

- Built-in variables: `pageUrl`, `rootUrl`, and `time` are automatically available during `execute()`.
- Global variables: set persistent defaults via `VariableResolver.defaultVariable` (shared across queries).
- Initial variables: pass per-call values via the optional `initialVariables` on `execute`, `getValue`, `getCollection`, `getCollectionValue`.

Example:

```dart
import 'package:web_query/query.dart';
import 'package:web_query/src/resolver/variable.dart';

// Define global variables available to all queries
VariableResolver.defaultVariable = {
  'env': 'prod',
  'apiKey': 'XYZ-123',
};

final pageData = PageData('https://example.com/articles/42', '<html></html>');
final node = pageData.getRootElement();

// Per-call variables
final sessionVars = {
  'id': 42,
  'prefix': 'post',
};

// Use variables in templates; built-ins include pageUrl, rootUrl, time
final summary = QueryString(
  'template:${prefix}-${id} at ${time} from ${rootUrl}'
).getValue(node, initialVariables: sessionVars);

// Use variables in paths and transforms
final absLinks = QueryString(
  '*a/@href?transform=regexp:/^\\/(.+)/${rootUrl}$1/'
).getCollectionValue(node, initialVariables: sessionVars);
```

Notes:

- `time` is injected as `DateTime.now().millisecondsSinceEpoch`.
- `pageUrl` and `rootUrl` come from `PageData.url`.
- Per-call `initialVariables` override `VariableResolver.defaultVariable` for the duration of that call.

### Custom Transform Functions

You can register your own transform functions and call them via `?transform=<name>`.

- Register functions globally using `FunctionResolver.defaultFunctions`.
- Each entry maps a function name to a factory that receives params and returns the transform.
- Use optional JSON params in the query: `?transform=<name>:{"key":"value"}`.

Example (slugify):

```dart
import 'package:web_query/src/resolver/function.dart';

// Register a custom transform
FunctionResolver.defaultFunctions['slugify'] = (params) => (value) {
  if (value == null) return null;
  final s = value.toString();
  final sep = (params['sep'] as String?) ?? '-';
  final cleaned = s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), sep)
      .replaceAll(RegExp('${RegExp.escape(sep)}+'), sep)
      .replaceAll(RegExp('^${RegExp.escape(sep)}|${RegExp.escape(sep)}\$'), '');
  return cleaned;
};

// Usage in a query (with optional params)
final slug = QueryString(
  'json:title?transform=slugify:{"sep":"_"}'
).getValue(node);
```

Tips:

- Custom functions participate in the `transform` pipeline and can be chained (`?transform=slugify;upper`).
- If your function needs structured params, supply them as JSON after `:`.
- Logging and error handling are recommended inside function bodies.

### URL Queries

Query and modify URLs using the `url:` scheme:

#### Query URL Components

Extract individual parts of the current page URL:

```dart
// Given URL: https://example.com:8080/path/to/resource?page=1&sort=desc#section1

final fullUrl = QueryString('url:').getValue(node);
// "https://example.com:8080/path/to/resource?page=1&sort=desc#section1"

final scheme = QueryString('url:scheme').getValue(node);
// "https"

final host = QueryString('url:host').getValue(node);
// "example.com"

final port = QueryString('url:port').getValue(node);
// "8080"

final path = QueryString('url:path').getValue(node);
// "/path/to/resource"

final query = QueryString('url:query').getValue(node);
// "page=1&sort=desc"

final fragment = QueryString('url:fragment').getValue(node);
// "section1"

final userInfo = QueryString('url:userInfo').getValue(node);
// "" (if present in URL)

final origin = QueryString('url:origin').getValue(node);
// "https://example.com:8080"
```

#### Query URL Parameters

Access query parameters as a map or individual values:

```dart
// Get all query parameters as a map
final params = QueryString('url:queryParameters').execute(node);
// {"page": "1", "sort": "desc"}

// Get specific parameter
final page = QueryString('url:queryParameters/page').getValue(node);
// "1"

final sort = QueryString('url:queryParameters/sort').getValue(node);
// "desc"

// Non-existent parameter returns null
final missing = QueryString('url:queryParameters/missing').getValue(node);
// null
```

#### Modify URLs

Modify URL components using query parameters:

##### Update Query Parameters

```dart
// Add new query parameter
final newUrl = QueryString('url:?newParam=value').getValue(node);
// "https://example.com:8080/path/to/resource?page=1&sort=desc&newParam=value#section1"

// Update existing parameter
final updated = QueryString('url:?page=2').getValue(node);
// "https://example.com:8080/path/to/resource?page=2&sort=desc#section1"

// Multiple parameter updates
final multi = QueryString('url:?page=2&status=active').getValue(node);
// "https://example.com:8080/path/to/resource?page=2&sort=desc&status=active#section1"

// Remove parameters
final removed = QueryString('url:?_remove=sort').getValue(node);
// "https://example.com:8080/path/to/resource?page=1#section1"

// Remove multiple parameters
final removedMulti = QueryString('url:?_remove=page,sort').getValue(node);
// "https://example.com:8080/path/to/resource#section1"
```

##### Replace URL Components

Use special `_` prefixed parameters to replace URL components:

```dart
// Change scheme
final httpUrl = QueryString('url:?_scheme=http').getValue(node);
// "http://example.com:8080/path/to/resource?page=1&sort=desc#section1"

// Change host
final newHost = QueryString('url:?_host=new.com').getValue(node);
// "https://new.com:8080/path/to/resource?page=1&sort=desc#section1"

// Change port
final newPort = QueryString('url:?_port=9000').getValue(node);
// "https://example.com:9000/path/to/resource?page=1&sort=desc#section1"

// Change path
final newPath = QueryString('url:?_path=/new/path').getValue(node);
// "https://example.com:8080/new/path?page=1&sort=desc#section1"

// Change fragment
final newFragment = QueryString('url:?_fragment=section2').getValue(node);
// "https://example.com:8080/path/to/resource?page=1&sort=desc#section2"

// Change userInfo
final withAuth = QueryString('url:?_userInfo=user:pass').getValue(node);
// "https://user:pass@example.com:8080/path/to/resource?page=1&sort=desc#section1"

// Combine multiple changes
final combined = QueryString('url:?_scheme=http&_host=api.example.com&page=2').getValue(node);
// "http://api.example.com:8080/path/to/resource?page=2&sort=desc#section1"
```

#### URL with Transforms

Apply transforms to URLs or extracted components:

```dart
// Extract domain using regexp
final domain = QueryString('url:?regexp=/https:\\/\\/([^\\/]+).*/$1/').getValue(node);
// "example.com:8080"

// Extract just hostname
final hostname = QueryString('url:host?regexp=/([^:]+).*/$1/').getValue(node);
// "example.com"

// Transform scheme
final transformed = QueryString('url:scheme?transform=upper').getValue(node);
// "HTTPS"

// Modify and extract
final modifiedHost = QueryString('url:host?_host=changed.com').getValue(node);
// "changed.com"

// Complex transformation
final apiUrl = QueryString('url:?_scheme=https&_host=api.example.com&_path=/v1/users&regexp=/(.*)\\?.*/$1/').getValue(node);
// "https://api.example.com/v1/users"
```

#### Practical URL Examples

```dart
// Build API endpoint from current URL
final apiEndpoint = QueryString('url:origin?regexp=/(.*)/$1\\/api\\/v1/').getValue(node);
// "https://example.com:8080/api/v1"

// Get base URL without query params
final baseUrl = QueryString('url:?regexp=/([^?]+).*/\$1/').getValue(node);
// "https://example.com:8080/path/to/resource"

// Change to different environment
final stagingUrl = QueryString('url:?_host=staging.example.com&_scheme=https').getValue(node);
```

### DataQueryWidget

Visual component for interactive data querying:

```dart
import 'package:web_query/ui.dart';

DataQueryWidget(
  pageData: pageData,
  title: 'Query Data',
  onToggleExpand: () => setState(() => expanded = !expanded),
)
```

Features:

- Interactive HTML tree view
- Real-time QueryString filtering
- Switch between HTML and JSON views
- Visual query results panel

See the [example project](example/) for a complete demonstration.

````

## API Reference

### QueryString Class

Main class for creating and executing queries.

```dart
// Constructor
QueryString(String query)

// Methods
dynamic execute(PageNode node, {bool simplify = true})
String getValue(PageNode node, {String separator = '\n'})
Iterable<PageNode> getCollection(PageNode node)
Iterable getCollectionValue(PageNode node)
````

#### Which Method to Use?

Choose the appropriate method based on your needs:

| Method                 | Use When                                                 | Returns              |
| ---------------------- | -------------------------------------------------------- | -------------------- |
| `getValue()`           | You want a single string value or concatenated text      | `String`             |
| `getCollectionValue()` | You want multiple raw values (strings, Elements, JSON)   | `Iterable<dynamic>`  |
| `getCollection()`      | You need PageNode objects for further querying           | `Iterable<PageNode>` |
| `execute()`            | You want automatic simplification (single value or list) | `dynamic`            |

**Recommended:** Use `getValue()` for single values and `getCollectionValue()` for lists of raw values and `getCollection()` for lists of PageNode objects. Use `execute()` only when you need dynamic behavior.

```dart
// ✅ Preferred: Explicit methods
final title = QueryString('h1/@text').getValue(node);
final nodes = QueryString('*li').getCollection(node);
final items = QueryString('*li/@text').getCollectionValue(node);

// ⚠️ Less clear: Generic execute
final title = QueryString('h1/@text').execute(node);
final items = QueryString('*li/@text').execute(node);
```

#### execute()

Executes the query and returns results.

```dart
final result = QueryString('div/@text').execute(node);
// Returns: String (single result) or List (multiple results)

final result = QueryString('div/@text').execute(node, simplify: false);
// Returns: List<PageNode> (always a list)
```

#### getValue()

Returns results as a concatenated string.

```dart
final text = QueryString('*p/@text').getValue(node);
// Returns: "Para 1\nPara 2\nPara 3"

final text = QueryString('*p/@text').getValue(node, separator: ' | ');
// Returns: "Para 1 | Para 2 | Para 3"
```

#### getCollection()

Returns results as PageNode objects.

```dart
final nodes = QueryString('*div').getCollection(node);
// Returns: Iterable<PageNode>

for (var node in nodes) {
  print(node.element?.text);
}
```

#### getCollectionValue()

Returns raw values (Elements or JSON data).

```dart
final elements = QueryString('*div').getCollectionValue(node);
// Returns: Iterable<Element>

final jsonData = QueryString('json:items/*').getCollectionValue(node);
// Returns: Iterable<dynamic> (JSON objects)
```

### PageData Class

Represents a web page with HTML and optional JSON data.

```dart
// Constructor
PageData(String url, String html, {String? jsonData})

// Methods
PageNode getRootElement()
```

### PageNode Class

Represents a node in the query result (HTML element or JSON data).

```dart
// Properties
Element? element      // HTML element (if HTML query)
dynamic jsonData      // JSON data (if JSON query)
PageData pageData     // Reference to page data
```

## UI Components

The package includes interactive UI components for data visualization:

### DataQueryWidget

Complete data reader with HTML/JSON views and query filtering:

```dart
import 'package:web_query/ui.dart';

DataQueryWidget(
  pageData: pageData,
  title: 'Query Data',
  onToggleExpand: () => setState(() => expanded = !expanded),
)
```

### JsonTreeView

Collapsible JSON tree viewer:

```dart
import 'package:web_query/ui.dart';

JsonTreeView(json: jsonData)
```

### HtmlTreeView

Collapsible HTML tree viewer:

```dart
import 'package:web_query/ui.dart';

HtmlTreeView(document: parsedDocument)
```

## Migration Guide

### Query Validation (New Feature)

The query validation feature is **completely additive** and requires no migration. It's an opt-in feature that doesn't affect existing code.

**What's New:**

- New `validate()` method on `QueryString` class
- Returns `ValidationResult` with errors, warnings, and query information
- Validation is optional and separate from query execution

**No Breaking Changes:**

- All existing queries continue to work exactly as before
- Validation is opt-in (call `validate()` explicitly)
- Query execution is unchanged

**How to Use:**

```dart
// Your existing code works unchanged
final query = QueryString('json:items');
final data = query.execute(node);

// Optionally add validation
final result = query.validate();
if (!result.isValid) {
  print('Query has errors: ${result}');
}
```

See the [Query Validation](#query-validation) section for detailed usage examples and the [Validation Guide](VALIDATION_GUIDE.md) for comprehensive documentation.

### Variable Discard Behavior

The `?save=` parameter now automatically omits results from final output unless `&keep` is specified.

**Old Behavior:**

```dart
// Results were kept by default
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
// Returned: ["Alice", "Smith", "Alice Smith"]
```

**New Behavior:**

```dart
// Results are omitted by default (cleaner templates)
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
// Returns: "Alice Smith"

// Use &keep to include intermediate results
'json:firstName?save=fn&keep ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
// Returns: ["Alice", "Smith", "Alice Smith"]
```

**Migration:**

- If you want the old behavior, add `&keep` to your `?save=` parameters
- If you prefer cleaner output (recommended), no changes needed

See the [Variables and Templates](#variables-and-templates) section for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Links

- [Package on pub.dev](https://pub.dev/packages/web_query)
- [GitHub Repository](https://github.com/zhuangxm/web_query)
- [Issue Tracker](https://github.com/zhuangxm/web_query/issues)
