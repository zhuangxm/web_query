# Web Query

A Flutter library for querying HTML and JSON data using a simple syntax.

## Features

- Simple query syntax for HTML and JSON data
- CSS-like selectors for HTML elements
- JSON path navigation
- Element navigation operators
- Transform operations
- Class name checking
- Chaining and fallback queries

## Getting started

Add to your pubspec.yaml:

```yaml
dependencies:
  web_query: ^0.1.0
```

## Usage

### Basic HTML Query

```dart
const html = '''
<div class="videos">
  <a href="a1">a1 text</a>
  <a href="a2">a2 text</a>
</div>
''';

final pageData = PageData("https://example.com", html);
// new protocol
final query = QueryString('div a/@text');
// compatible with old protocol
final queryOld = QueryString('div a@text', newProtocol = false);
final executeResult = query.execute(pageData.getRootElement()); // "a1 text"
final valueResult = query.getValue(pageData.getRootElement()); // "a1 text"
final listResult = query.getCollection(pageData.getRootElement()); // ["a1 text"]
```

### JSON Query

```dart
const jsonData = {
  "meta": {
    "title": "Page Title",
    "tags": ["one", "two"]
  }
};

final pageData = PageData("https://example.com", "<html></html>",
    jsonData: jsonEncode(jsonData));
final query = QueryString('json:meta/title');
final result = query.execute(pageData.getRootElement()); // "Page Title"
```

## Query Syntax

### Schemes

- `json:path` - Query JSON data
- `html:path` - Query HTML elements (optional, default)
- Just `path` - Defaults to HTML query

### HTML Queries

```dart
// Basic selectors
'div p'              // Find paragraphs in divs
'*p'                // Find all paragraphs (force all)
'p'                // Find first paragraph (force one)
'.content/*div'     // All divs in content
'.content/?div'     // First div in content

// Navigation
'div/^'             // Parent
'div/>'             // First child
'div/+>'            // Next sibling
'div/-'             // Previous sibling

// Attributes
'a/@href'           // Get href attribute
'div/@text'         // Get text content
'div/@html'         // Get inner HTML
'div/@.class'       // Check if class exists
'div/@.prefix*'     // Match class with prefix
'div/@.*suffix'     // Match class with suffix
```

### JSON Queries

```dart
// Basic paths
'json:meta/title'           // Get value
'json:items/0/name'         // Array index
'json:items/*'             // All array items
'json:items/1-3'           // Array range

// Multiple paths
'json:title,description'    // Get multiple values
'json:meta/title,tags/*'   // Mix paths and arrays
```

### Query Parameters

```dart
// Operations
'div/p?op=all'                    // Get all matches
'div/p?required=false'            // Optional in chain

// Transforms
'@text?transform=upper'           // Uppercase
'@text?transform=lower'           // Lowercase
'@src?transform=regexp:/pat/rep/' // RegExp replace
```

### Chaining Queries

```dart
// Fallback chain
'json:meta/title||h1/@text'

// Multiple required
'json:meta/title||json:content/body'

// Mixed with transforms
'json:title?transform=upper||div/p?transform=lower'
```

## Additional Features

### Class Name Matching

```dart
// Check exact class
'div/@.featured'          // true/false

// Wildcard matching
'div/@.prefix*'          // Matches prefix-anything
'div/@.*suffix'          // Matches anything-suffix
'div/@.*part*'          // Matches containing part
```

### RegExp Transforms

```dart
// Match only
'@text?transform=regexp:/pattern/'

// Replace
'@text?transform=regexp:/pattern/replacement/'

// With variables
'@src?transform=regexp:/^\/(.+)/${rootUrl}$1/'
```

## Legacy Api

Selectors is still supported but deprecated
[QueryString] [webValue] [webCollection] support both new and old protocol.
but default using new protocol.
new protocol document refer query.dart
old protocol document refer src/selector.dar

## Legacy Protocol

The old protocol is still supported but deprecated:
newProtocol default is true, if using oldProtocol must specify named parameter [newProtocol] = false

```dart
webValue(element, "div a", newProtocol = false)               // Get first value
webCollection(element, "div a", newProtocol = false)          // Get all matches
webValue(element, "any#div a", newProtocol = false)          // Get one
webCollection(element, "any#div a", newProtocol = false)      // Get one as list
```

## Contributing

Feel free to file feature requests and bug reports at the [issue tracker](link-to-issues).
