# Implementation Plan

## ✅ Completed Implementation

All core validation functionality has been successfully implemented and tested:

- [x] 1. Create QueryValidator class structure
  - Created `lib/src/query_validator.dart` with all required classes
  - ValidationResult, ValidationError, ValidationWarning, QueryInfo, QueryPartInfo
  - QueryValidator with static validation methods
  - ValidationRules constants
  - _Requirements: 4.1, 4.3, 4.5, 4.6, 4.7_

- [x] 2. Implement scheme validation
  - [x] 2.1 Implement scheme extraction and validation logic
    - Extract scheme prefix from query part
    - Check if scheme is in valid schemes list
    - Detect missing `:` separator after scheme
    - _Requirements: 1.1, 1.5_
  
  - [x] 2.4 Unit tests for scheme validation (test/scheme_validation_test.dart)
    - Test valid schemes pass validation
    - Test invalid schemes are detected with suggestions
    - Test missing `:` separator is detected
    - Test scheme-less queries (default to html)
    - Test error position reporting
    - Test toString and toJson formatting
    - _Requirements: 1.1, 1.5_

- [x] 3. Implement parameter syntax validation
  - [x] 3.1 Implement parameter validation logic
    - Detect multiple `?` characters in query part
    - Verify proper use of `&` separators
    - _Requirements: 1.2_
  
  - [x] 3.3 Unit tests for parameter validation (test/parameter_validation_test.dart)
    - Test single `?` passes validation
    - Test multiple `?` without `&` is detected
    - Test proper `?` and `&` usage passes validation
    - Test error message includes correction example
    - Test error position is correct
    - _Requirements: 1.2, 3.2_

- [x] 4. Implement variable syntax validation
  - [x] 4.1 Implement variable bracket matching logic
    - Track `${` and `}` matching
    - Detect unmatched brackets
    - Report position of unmatched bracket
    - _Requirements: 1.3_
  
  - [x] 4.3 Unit tests for variable validation (test/variable_validation_test.dart)
    - Test valid `${var}` syntax passes
    - Test unmatched `${` is detected
    - Test unmatched `}` is ignored (not part of variable)
    - Test nested variables are handled correctly
    - Test position reporting is accurate
    - _Requirements: 1.3, 2.1_

- [x] 5. Implement operator validation
  - [x] 5.1 Implement operator detection and validation
    - Extract operators from query string
    - Verify operators are in valid operators list
    - Handle edge cases (e.g., `>` vs `>>` vs `>>>`)
    - _Requirements: 1.4_
  
  - [x] 5.3 Unit tests for operator validation (test/operator_validation_test.dart)
    - Test all valid operators pass validation
    - Test invalid operators are detected with suggestions
    - Test operator-like sequences in strings don't trigger errors
    - Test operators without spaces are not treated as operators
    - _Requirements: 1.4_

- [x] 6. Implement typo suggestion system
  - [x] 6.1 Implement Levenshtein distance algorithm
    - Create helper method for edit distance calculation
    - Implement suggestion logic with threshold
    - _Requirements: 3.1_
  
  - [x] 6.2 Integrate suggestions into error messages
    - Add suggestion field to ValidationError
    - Format suggestions in error messages
    - _Requirements: 3.1, 5.2_

- [x] 7. Implement error formatting and position reporting
  - [x] 7.1 Implement error message formatting
    - Create method to format error with context
    - Include query snippet with position pointer
    - Include suggestion or example
    - _Requirements: 2.1, 2.2, 2.3, 5.1, 5.2_
  
  - [x] 7.2 Implement position tracking
    - Track character positions during validation
    - Track query part indices for multi-part queries
    - _Requirements: 2.1, 2.2_

- [x] 8. Add validate() method to QueryString class
  - [x] 8.1 Add validate() method to QueryString
    - Add public validate() method that returns ValidationResult
    - Call QueryValidator.validate() internally
    - Extract query information when validation succeeds
    - Ensure validation doesn't affect query execution
    - _Requirements: 4.1, 4.2, 4.5, 6.1, 6.3, 6.4_
  
  - [x] 8.2 Implement query information extraction
    - Extract operators from query string
    - Extract variables from query string
    - Extract query parts information (scheme, path, parameters, transforms)
    - Build QueryInfo object with all details
    - _Requirements: 4.5_

- [x] 9. Comprehensive unit tests
  - test/scheme_validation_test.dart - Scheme validation tests
  - test/parameter_validation_test.dart - Parameter syntax tests
  - test/variable_validation_test.dart - Variable syntax tests
  - test/operator_validation_test.dart - Operator validation tests
  - test/query_info_extraction_test.dart - Query information extraction tests
  - test/manual_validation_test.dart - Manual validation and integration tests
  - test/query_validation_test.dart - Runtime validation tests
  - All tests passing ✅

- [x] 10. Add validation for common edge cases
  - [x] 10.1 Add validation for regexp patterns
    - Detect common escaping issues
    - Warn about unescaped special characters
    - _Requirements: 3.3_
  
  - [x] 10.2 Add validation for template syntax
    - Verify template variables are properly formatted
    - Check for common template mistakes (missing $, empty variables, whitespace)
    - _Requirements: 5.1, 5.2_
  
  - [x] 10.3 Unit tests for edge case validation (test/manual_validation_test.dart)
    - Test regexp pattern warnings
    - Test template syntax warnings
    - Test valid patterns don't warn
    - _Requirements: 3.3, 5.1, 5.2_

- [x] 11. Update documentation and examples
  - Updated README.md with comprehensive validation section
  - Created VALIDATION_GUIDE.md with detailed examples and best practices
  - Added validation error reference guide
  - Documented all validation features and API
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 12. Final checkpoint - All tests passing ✅
  - All 150+ tests passing including validation tests
  - Core functionality complete and working
  - Documentation complete

## 🎯 Feature Complete

The query validation feature is **fully implemented and tested**. All requirements from the design document have been met:

✅ **Syntax Validation** - Invalid schemes, parameters, variables, operators  
✅ **Error Reporting** - Position tracking, multi-part queries, formatted messages  
✅ **Typo Suggestions** - Levenshtein distance for scheme suggestions  
✅ **Query Information** - Detailed extraction for valid queries  
✅ **Warnings** - Regexp patterns, template syntax issues  
✅ **Independence** - Validation doesn't affect query execution  
✅ **Complete Error Reporting** - All errors reported, not just first  
✅ **Documentation** - README and comprehensive validation guide  
✅ **Testing** - Extensive unit tests covering all functionality
