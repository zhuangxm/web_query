## 0.1.0

- Added new QueryString API for more powerful querying
  - Simplified scheme syntax (`json:` and `html:` prefixes)
  - Default HTML scheme when no prefix provided
  - Class name existence checking with `@.class`
  - Wildcard class name matching (`@.prefix*`, `@.*suffix`)
  - Transform operations (upper, lower, regexp)
  - Query chaining with `||`
  - Operation modes (`?op=all`)
  - Required/optional queries
  - RegExp transforms with pattern matching and replacement
  - JSON path improvements
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
