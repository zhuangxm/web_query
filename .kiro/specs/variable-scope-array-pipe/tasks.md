# Implementation Plan

- [x] 1. Refactor _executeQueries to return variables
  - Create new internal method `_executeQueriesWithVariables()` that returns both result and variables map
  - Return type should be a record: `({dynamic result, Map<String, dynamic> variables})`
  - Copy all logic from existing `_executeQueries()` method
  - Ensure the variables map is properly populated during query execution
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2. Modify execute() method to capture and pass variables for >>> operator
  - Update the `>>>` operator handling in `execute()` method
  - Call `_executeQueriesWithVariables()` instead of recursive `execute()` for first part
  - Capture the variables map from first part execution
  - Pass captured variables as `initialVariables` to second part execution
  - Ensure normal execution path (without `>>>`) still works correctly
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 3. Update _executeQueries wrapper method
  - Keep existing `_executeQueries()` method as a wrapper for backward compatibility
  - Have it call `_executeQueriesWithVariables()` and return only the result
  - Ensure all existing call sites continue to work
  - _Requirements: 1.1_

- [x] 4. Write unit tests for basic variable passing
  - [x] 4.1 Test single variable saved before >>> and used after
    - Create test with `?save=varName` before `>>>` and `template:${varName}` after
    - Verify variable is correctly resolved
    - _Requirements: 1.1, 1.2_
  
  - [x] 4.2 Test multiple variables saved before >>> and used after
    - Create test with multiple `?save=` before `>>>` and template using all variables
    - Verify all variables are correctly resolved
    - _Requirements: 1.3_
  
  - [x] 4.3 Test variable in path after >>>
    - Save variable before `>>>`, use in JSON path like `json:items/${varName}`
    - Verify path is correctly resolved
    - _Requirements: 1.2_
  
  - [x] 4.4 Test initialVariables parameter with >>>
    - Pass initialVariables to execute(), use them after `>>>`
    - Verify initial variables are preserved
    - _Requirements: 2.2_
  
  - [x] 4.5 Test nested >>> operators
    - Create query with multiple `>>>` operators in sequence
    - Save variables before first `>>>`, use after second `>>>`
    - Verify variables persist across all `>>>` boundaries
    - _Requirements: 2.3_
  
  - [x] 4.6 Test edge cases
    - Test with no variables saved (should work as before)
    - Test with null variable values
    - Test with variable name conflicts (later value should win)
    - Test with empty query results
    - _Requirements: 1.1, 1.2, 1.3_

- [ ]* 5. Write property-based tests for variable scoping
  - [ ]* 5.1 Property test for variable preservation across array pipe
    - **Property 1: Variable preservation across array pipe**
    - Generate random variable names and values
    - Save before `>>>`, verify accessible after
    - Run 100+ iterations
    - **Validates: Requirements 1.1**
  
  - [ ]* 5.2 Property test for variable resolution after array pipe
    - **Property 2: Variable resolution after array pipe**
    - Generate random variables and templates/paths
    - Verify correct resolution after `>>>`
    - Run 100+ iterations
    - **Validates: Requirements 1.2**
  
  - [ ]* 5.3 Property test for multiple variable preservation
    - **Property 3: Multiple variable preservation**
    - Generate random sets of 1-10 variables
    - Verify all preserved after `>>>`
    - Run 100+ iterations
    - **Validates: Requirements 1.3**
  
  - [ ]* 5.4 Property test for operator consistency
    - **Property 4: Operator consistency for variable scoping**
    - Generate queries with different operators (`++`, `||`, `>>`, `>>>`)
    - Verify consistent variable behavior across all operators
    - Run 100+ iterations
    - **Validates: Requirements 2.1**
  
  - [ ]* 5.5 Property test for initial variables preservation
    - **Property 5: Initial variables preservation**
    - Generate random initial variables
    - Verify preserved through `>>>` chains
    - Run 100+ iterations
    - **Validates: Requirements 2.2**
  
  - [ ]* 5.6 Property test for nested array pipe variable scope
    - **Property 6: Nested array pipe variable scope**
    - Generate queries with multiple `>>>` operators
    - Verify variables accessible at all levels
    - Run 100+ iterations
    - **Validates: Requirements 2.3**

- [ ] 6. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Update existing tests if needed
  - Review existing test files that use `>>>` operator
  - Ensure they still pass with the changes
  - Update any tests that may be affected by the fix
  - _Requirements: 1.1, 2.1_

- [ ] 8. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
