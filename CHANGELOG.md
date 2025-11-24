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
