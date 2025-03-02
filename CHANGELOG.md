## 0.2.0

- breaking change:
  - after || part mean optional (previous version is required)
  - , default is requried. (previous version is optional)
  - adding ++ & mean requried.
  - adding | meain optional.
  - remove required?= parameter
  - remove !suffix in json path part.
- adding ++ and || separator to query satatement. (part after ++ mean required)
- adding | and , to seperator multi path (part after | mean optional , after `,` mean required)
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
