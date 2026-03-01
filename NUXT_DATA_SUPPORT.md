# Nuxt.js __NUXT_DATA__ Support

## Overview

Starting from version 0.9.2, the `json` transform automatically detects and decodes Nuxt.js `__NUXT_DATA__` format. This compact array-based serialization format is used by Nuxt.js for state hydration.

## What is __NUXT_DATA__?

Nuxt.js uses a special encoding format where data is stored in a compact array with references:

```json
[
  ["Reactive", 1],
  {"props": 2},
  {"pageProps": 3},
  {"locale": 4, "id": 5},
  "en-US",
  1234
]
```

This gets automatically decoded to:

```json
{
  "props": {
    "pageProps": {
      "locale": "en-US",
      "id": 1234
    }
  }
}
```

## How It Works

The decoder recognizes the Nuxt.js format by checking for:
- Array structure with at least 2 elements
- First element is `["Reactive", 1]` or `["ShallowReactive", 1]`
- Second element (index 1) is the root object

When detected, it automatically:
1. Resolves all index references to actual values
2. Handles special markers (`Ref`, `Set`, `null`, etc.)
3. Recursively decodes nested structures
4. Returns regular JSON that can be queried normally

## Usage

Simply use the `json` transform as usual - decoding happens automatically:

```dart
// Extract from script tag
'script#__NUXT_DATA__/@text?transform=json'

// Extract from JavaScript variable
'script/@text?transform=json:window.__NUXT__'

// Use with PageData defaultJsonId parameter
final pageData = PageData(
  'https://example.com',
  html,
  defaultJsonId: '__NUXT_DATA__'
);
// pageData.jsonData is automatically decoded

// Chain with JSON queries
'script#__NUXT_DATA__/@text?transform=json >> json:props/pageProps/locale'
```

## Supported Markers

The decoder handles these special Nuxt.js markers:

- **Reactive / ShallowReactive**: Root reactive object
- **Ref / EmptyRef / EmptyShallowRef**: References to other indices
- **Set**: Array representation of sets
- **null**: Dict-as-list format `["null", key1, val1, key2, val2, ...]`

## Examples

### Simple Object

```html
<script id="__NUXT_DATA__" type="application/json">
[
  ["Reactive", 1],
  {"name": 2, "age": 3},
  "Alice",
  30
]
</script>
```

Query: `script#__NUXT_DATA__/@text?transform=json`

Result: `{"name": "Alice", "age": 30}`

Or with PageData:
```dart
final pageData = PageData(url, html, defaultJsonId: '__NUXT_DATA__');
// pageData.jsonData = {"name": "Alice", "age": 30}
```

### Nested Objects

```html
<script id="__NUXT_DATA__" type="application/json">
[
  ["Reactive", 1],
  {"user": 2, "settings": 3},
  {"name": 4, "email": 5},
  {"theme": 6},
  "Alice",
  "alice@example.com",
  "dark"
]
</script>
```

Query: `script#__NUXT_DATA__/@text?transform=json >> json:user/name`

Result: `"Alice"`

### Arrays

```html
<script id="__NUXT_DATA__" type="application/json">
[
  ["Reactive", 1],
  {"items": 2},
  [3, 4, 5],
  "apple",
  "banana",
  "cherry"
]
</script>
```

Query: `script#__NUXT_DATA__/@text?transform=json >> json:items/*`

Result: `["apple", "banana", "cherry"]`

### Complex Nested Structure

```html
<script id="__NUXT_DATA__" type="application/json">
[
  ["Reactive", 1],
  {"posts": 2},
  [3, 4],
  {"id": 5, "title": 6, "author": 7},
  {"id": 8, "title": 9, "author": 10},
  1,
  "First Post",
  {"name": 11},
  2,
  "Second Post",
  {"name": 12},
  "Alice",
  "Bob"
]
</script>
```

Query: `script#__NUXT_DATA__/@text?transform=json >> json:posts/*/title`

Result: `["First Post", "Second Post"]`

## Backward Compatibility

- Regular JSON arrays are not affected
- Only arrays with valid Nuxt.js headers are decoded
- Invalid Nuxt.js format returns the original array
- No breaking changes to existing code

## Technical Details

The decoder is implemented in `lib/src/transforms/data_transforms.dart`:

- `_decodeNuxtData()`: Validates and initiates decoding
- `_decodeNuxtValue()`: Recursively decodes values and references

Based on the format described at:
https://developers.thequestionmark.org/2024/02/06/making-sense-of-nuxt-data

## Testing

Comprehensive tests are available in `test/nuxt_data_test.dart` covering:
- Simple and nested objects
- Arrays and primitives
- Special markers (Ref, Set, null)
- Complex nested structures
- Edge cases and invalid formats
