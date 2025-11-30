# Technology Stack

## Language & Framework

- **Dart** (SDK: >=3.2.5 <4.0.0)
- **Flutter** (>=1.17.0)

## Key Dependencies

- `html` (^0.15.4) - HTML parsing
- `xml2json` (^6.2.7) - XML/JSON conversion
- `flutter_hooks` (^0.21.3+1) - React-style hooks for Flutter
- `collection` (^1.18.0) - Collection utilities
- `logging` (^1.3.0) - Logging framework

## Development Dependencies

- `flutter_lints` (^2.0.0) - Linting rules
- `flutter_test` - Testing framework

## Common Commands

### Package Management
```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/query_test.dart

# Run tests with coverage
flutter test --coverage
```

### Building
```bash
# Analyze code
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated
```

### Example App
```bash
# Run example app (macOS)
cd example
flutter run -d macos

# Build example app
cd example
flutter build macos
```

## Linting

The project uses `flutter_lints` package for code quality. Configuration is in `analysis_options.yaml`.
