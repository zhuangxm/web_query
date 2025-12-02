# Release Notes - Version 0.7.0

## Summary

Version 0.7.0 introduces comprehensive query validation capabilities and enhances the DataQueryWidget UI with real-time validation feedback.

## What's New

### 1. Query Validation API

A complete validation system that helps catch syntax errors before execution:

```dart
final query = QueryString('json:items?save=x&keep ++ template:${x}');
final result = query.validate();

if (result.isValid) {
  print('✓ Query is valid');
  print(result.info); // Detailed query structure
} else {
  print('✗ Errors found:');
  for (var error in result.errors) {
    print(error.format(query.query));
  }
}
```

**Features:**
- Detects invalid schemes with smart typo suggestions
- Validates parameter syntax
- Warns about regexp pattern issues
- Warns about template variable problems
- Position-based error reporting
- Query structure extraction
- JSON output for logging/APIs

### 2. Enhanced DataQueryWidget

The UI component now includes integrated validation feedback:

- Real-time validation as you type (debounced)
- Color-coded feedback (red/orange/green)
- Scrollable filter area with proper layout
- Results displayed in logical order:
  1. getValue() result
  2. getCollectionValue() results
  3. Validation feedback (errors/warnings/structure)

### 3. Smart Regex Validation

Improved regex pattern validation to avoid false positives:

- Correctly recognizes valid patterns: `\d+`, `\w+`, `[a-z]+`, `(abc)+`
- Only warns about genuinely suspicious patterns: `test.com` (unescaped dot)
- Context-aware checking for quantifiers

## Breaking Changes

None. This release is fully backward compatible.

## Bug Fixes

- Fixed validation warnings not showing when query is valid
- Fixed false positive warnings for valid regex quantifiers
- Fixed position tracking in validation errors

## Files Updated

- `pubspec.yaml` - Version bumped to 0.7.0
- `CHANGELOG.md` - Added 0.7.0 release notes
- `README.md` - Updated version reference
- `lib/src/query_validator.dart` - Fixed warning display and regex validation
- `lib/src/ui/data_reader.dart` - Enhanced UI with scrollable layout

## Documentation

- `VALIDATION_GUIDE.md` - Comprehensive validation documentation
- `VALIDATION_ERRORS.md` - Error reference guide
- `README.md` - Validation examples and API reference

## Testing

All 278 tests pass, including:
- 15 validation-specific tests
- 7 regex pattern validation tests
- Integration tests for DataQueryWidget

## Migration

No migration needed. The validation feature is opt-in and doesn't affect existing code.

To use validation:
```dart
// Add validation to your queries
final result = queryString.validate();
if (!result.isValid) {
  // Handle errors
}
```

## Next Steps

Consider using validation in development/debug mode to catch query syntax errors early:

```dart
assert(() {
  final result = queryString.validate();
  if (!result.isValid) {
    print('Query validation failed: $result');
  }
  return true;
}());
```
