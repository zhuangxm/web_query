# Implementation Plan

- [x] 1. Create transforms directory structure and state management module
  - Create `lib/src/transforms/` directory
  - Implement `state_transforms.dart` with DiscardMarker, save, and discard operations
  - Move DiscardMarker class from original file
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 1.1 Write property test for save before discard ordering
  - **Property 11: Save before discard ordering**
  - **Validates: Requirements 7.1**

- [x] 2. Implement selection transforms module
  - Create `selection_transforms.dart` with filter and index operations
  - Move `applyFilter()` function with pattern parsing logic
  - Move `applyIndex()` function with positive/negative index support
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [x] 2.1 Write property test for filter include and exclude patterns
  - **Property 8: Filter include and exclude patterns**
  - **Validates: Requirements 6.1**

- [x] 2.2 Write property test for filter special character escaping
  - **Property 9: Filter special character escaping**
  - **Validates: Requirements 6.2**

- [x] 2.3 Write property test for index positive and negative support
  - **Property 10: Index positive and negative support**
  - **Validates: Requirements 6.3**

- [x] 3. Implement text transforms module
  - Create `text_transforms.dart` with case conversion operations
  - Implement `applyTextTransform()` dispatcher
  - Implement `toUpperCase()` and `toLowerCase()` functions
  - _Requirements: 3.2, 3.3_

- [x] 3.1 Write property test for single value and list consistency
  - **Property 3: Single value and list consistency**
  - **Validates: Requirements 3.2**

- [x] 3.2 Write property test for null handling
  - **Property 4: Null handling gracefully**
  - **Validates: Requirements 3.3**

- [x] 4. Implement pattern transforms module
  - Create `pattern_transforms.dart` with regexp operations
  - Move `applyRegexpTransform()` function
  - Move `prepareReplacement()` helper function
  - Implement `parseRegexpPattern()` for pattern/replacement extraction
  - _Requirements: 4.2, 4.3_

- [x] 4.1 Write property test for regexp page context substitution
  - **Property 5: Regexp page context substitution**
  - **Validates: Requirements 4.3**

- [x] 5. Implement data transforms module with JS executor registry
  - Create `data_transforms.dart` with JSON, jseval, and update operations
  - Implement `JsExecutorRegistry` class to replace global executor management
  - Move `applyJsonTransform()` function
  - Move `applyJsEvalTransform()` function
  - Move `applyUpdate()` function
  - _Requirements: 5.2, 5.4, 8.1, 8.2, 8.3_

- [x] 5.1 Write property test for JSON wildcard variable extraction
  - **Property 6: JSON wildcard variable extraction**
  - **Validates: Requirements 5.2**

- [x] 5.2 Write property test for JSON type support
  - **Property 7: JSON type support**
  - **Validates: Requirements 5.4**

- [x] 5.3 Write property test for JavaScript multi-variable extraction
  - **Property 12: JavaScript multi-variable extraction**
  - **Validates: Requirements 8.3**

- [x] 6. Implement transform pipeline orchestrator
  - Create `transform_pipeline.dart` with orchestration logic
  - Implement `TransformContext` class for passing page context
  - Move `applyAllTransforms()` function
  - Update to use new modular transform functions
  - Maintain transform order: transform → update → filter → index → save → discard
  - _Requirements: 2.1, 2.2_

- [x] 6.1 Write property test for transform pipeline order preservation
  - **Property 1: Transform pipeline order preservation**
  - **Validates: Requirements 2.1**

- [x] 6.2 Write property test for transform chaining consistency
  - **Property 2: Transform chaining consistency**
  - **Validates: Requirements 2.2**

- [x] 7. Create barrel export and update imports
  - Update `lib/src/transforms.dart` to re-export all public APIs from new modules
  - Export: `applyAllTransforms`, `DiscardMarker`, `JsExecutorRegistry`
  - Maintain backward compatibility with existing API
  - _Requirements: 1.1, 1.2_

- [x] 8. Update existing code to use new modules
  - Update `query_part.dart` imports if needed
  - Update any other files that import transforms
  - Ensure backward compatibility maintained
  - _Requirements: 1.1_

- [x] 9. Add backward compatibility shim for old JS executor API
  - Implement `setJsExecutorInstance()` function that calls `JsExecutorRegistry.register()`
  - Add deprecation notice in documentation
  - Ensure existing code continues to work
  - _Requirements: 8.1_

- [x] 10. Write integration tests for full pipeline
  - Test complete transform pipeline with all transform types
  - Test cross-module interactions
  - Verify backward compatibility with existing query strings
  - _Requirements: 2.1, 2.2_

- [x] 11. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Run existing test suite against new implementation
  - Execute all existing transform tests
  - Verify no regressions
  - Confirm backward compatibility
  - _Requirements: 1.1_

- [x] 13. Update documentation and add module-level comments
  - Add comprehensive documentation to each module
  - Document TransformContext usage
  - Document JsExecutorRegistry migration path
  - Add examples for each transform type
  - _Requirements: 1.2, 1.4_
