# Project Structure

## Root Directory Layout

```
web_query/
├── lib/                    # Main library code
├── test/                   # Test files
├── example/                # Example Flutter app
├── .dart_tool/            # Dart tooling (generated)
├── build/                 # Build artifacts (generated)
└── pubspec.yaml           # Package configuration
```

## Library Organization (`lib/`)

### Public API
- `lib/query.dart` - Main entry point, exports core query functionality
- `lib/ui.dart` - UI components (DataQueryWidget, tree views)

### Internal Implementation (`lib/src/`)

**Core Query Engine:**
- `query_part.dart` - Query parsing and representation
- `query_result.dart` - Query result handling
- `page_data.dart` - Page data model (HTML + JSON)

**Query Implementations:**
- `html_query.dart` - HTML querying with CSS selectors and navigation
- `json_query.dart` - JSON path navigation and extraction
- `url_query.dart` - URL querying and manipulation

**Data Processing:**
- `transforms.dart` - Data transformations (regex, case conversion, etc.)

**UI Components (`lib/src/ui/`):**
- `data_reader.dart` - Main data query widget
- `html_tree_view.dart` - Interactive HTML tree viewer
- `json_tree_view.dart` - Interactive JSON tree viewer
- `html_utils.dart` - HTML rendering utilities

## Test Organization (`test/`)

Tests are organized by feature/functionality:
- `query_test.dart` - Basic query functionality
- `advanced_query_test.dart` - Complex query scenarios
- `json_*_test.dart` - JSON-specific tests
- `pipe_*_test.dart` - Query piping tests
- `regexp_*_test.dart` - Regex transform tests
- `url_*_test.dart` - URL query tests
- `variables_test.dart` - Variable substitution tests
- `query_filter_test.dart` - Filtering tests
- `discard_test.dart` - Discard marker tests

## Example App (`example/`)

Standard Flutter app structure:
- `example/lib/main.dart` - Example app demonstrating library usage
- `example/macos/` - macOS platform-specific code
- `example/pubspec.yaml` - Example app dependencies

## Code Organization Patterns

### Query System Architecture
1. **QueryString** - Main API class, parses query strings
2. **QueryPart** - Represents individual query components
3. **Scheme-specific handlers** - `applyHtmlPathFor()`, `applyJsonPathFor()`, `applyUrlPathFor()`
4. **Transforms** - Applied after data extraction
5. **QueryResult** - Wraps and combines results

### Naming Conventions
- Classes: PascalCase (e.g., `QueryString`, `PageData`)
- Files: snake_case (e.g., `html_query.dart`, `query_part.dart`)
- Private members: prefix with `_` (e.g., `_executeQueries`)
- Test files: `*_test.dart` suffix

### Import Organization
- Dart SDK imports first
- Package imports second
- Relative imports last
- Exports at the top of public API files
