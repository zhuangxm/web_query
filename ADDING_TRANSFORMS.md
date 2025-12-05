# Adding New Transforms

This guide explains how to add new text transforms to the Web Query library.

## Overview

The transform system is designed to be easy to extend. All text transforms are centralized in a single location, making maintenance simple.

## Steps to Add a New Text Transform

### 1. Implement the Transform Function

Add your transform function to `lib/src/transforms/text_transforms.dart`:

```dart
/// Your transform description
///
/// Explain what the transform does, parameters, return values, and examples.
String? myNewTransform(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  
  // Your transformation logic here
  return transformedString;
}
```

### 2. Add to the Switch Statement

In the same file (`text_transforms.dart`), add a case to `_applyTextTransformSingle()`:

```dart
dynamic _applyTextTransformSingle(dynamic value, String transform) {
  if (value == null) return null;

  switch (transform) {
    case 'upper':
      return toUpperCase(value);
    case 'lower':
      return toLowerCase(value);
    // ... existing cases ...
    case 'mynew':  // ✅ Add your transform here
      return myNewTransform(value);
    default:
      _log.warning('Unknown text transform: $transform');
      return value;
  }
}
```

### 3. Register the Transform Name

Add the transform name to the `validTextTransforms` list in `lib/src/transforms/transform_pipeline.dart`:

```dart
const validTextTransforms = [
  'upper',
  'lower',
  'base64',
  'base64decode',
  'reverse',
  'md5',
  'mynew',  // ✅ Add your transform name here
];
```

**That's it!** The transform will automatically be:
- ✅ Available in query strings: `?transform=mynew`
- ✅ Validated during query parsing
- ✅ Included in error messages
- ✅ Integrated into the transform pipeline

## Example: Adding a ROT13 Transform

Here's a complete example of adding a ROT13 cipher transform:

### Step 1: Implement in `text_transforms.dart`

```dart
/// Apply ROT13 cipher to text
///
/// Rotates each letter by 13 positions in the alphabet.
/// Non-alphabetic characters are unchanged.
///
/// ## Examples
///
/// ```dart
/// rot13('Hello');  // 'Uryyb'
/// rot13('Uryyb');  // 'Hello' (reversible)
/// ```
String? rot13(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  
  return str.split('').map((char) {
    final code = char.codeUnitAt(0);
    if (code >= 65 && code <= 90) {
      // Uppercase A-Z
      return String.fromCharCode(((code - 65 + 13) % 26) + 65);
    } else if (code >= 97 && code <= 122) {
      // Lowercase a-z
      return String.fromCharCode(((code - 97 + 13) % 26) + 97);
    }
    return char;
  }).join('');
}
```

### Step 2: Add to Switch

```dart
dynamic _applyTextTransformSingle(dynamic value, String transform) {
  if (value == null) return null;

  switch (transform) {
    case 'upper':
      return toUpperCase(value);
    case 'lower':
      return toLowerCase(value);
    case 'base64':
      return base64Encode(value);
    case 'base64decode':
      return base64Decode(value);
    case 'reverse':
      return reverseString(value);
    case 'md5':
      return md5Hash(value);
    case 'rot13':  // ✅ Added
      return rot13(value);
    default:
      _log.warning('Unknown text transform: $transform');
      return value;
  }
}
```

### Step 3: Register Name

```dart
const validTextTransforms = [
  'upper',
  'lower',
  'base64',
  'base64decode',
  'reverse',
  'md5',
  'rot13',  // ✅ Added
];
```

### Usage

```dart
QueryString('json:message?transform=rot13').execute(node);
// "Hello" → "Uryyb"
```

## Testing Your Transform

Add tests to `test/text_transforms_extended_test.dart`:

```dart
test('rot13 encoding', () {
  final result = applyTextTransform('Hello', 'rot13');
  expect(result, 'Uryyb');
});

test('rot13 is reversible', () {
  final encoded = applyTextTransform('Hello', 'rot13');
  final decoded = applyTextTransform(encoded, 'rot13');
  expect(decoded, 'Hello');
});
```

## Best Practices

1. **Null Safety**: Always handle null input by returning null
2. **Type Conversion**: Convert input to string with `toString()`
3. **Documentation**: Add comprehensive doc comments with examples
4. **Error Handling**: Use try-catch for operations that might fail
5. **Logging**: Log warnings for invalid input using `_log.warning()`
6. **Testing**: Add unit tests for normal cases, edge cases, and error cases

## Architecture Benefits

This centralized approach provides:

- **Single Source of Truth**: `validTextTransforms` list defines all valid transforms
- **Automatic Integration**: No need to update multiple files
- **Consistent Validation**: Error messages automatically include new transforms
- **Easy Maintenance**: Adding transforms requires minimal code changes
- **Type Safety**: Compile-time checking ensures consistency

## Files Modified When Adding a Transform

1. `lib/src/transforms/text_transforms.dart` - Implementation (2 places)
2. `lib/src/transforms/transform_pipeline.dart` - Registration (1 place)
3. `test/text_transforms_extended_test.dart` - Tests (optional but recommended)

That's only **3 locations** to update, and the system handles the rest automatically!
