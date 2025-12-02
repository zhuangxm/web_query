# Design Document

## Overview

This design addresses a bug in the QueryString class where saved variables are not preserved across the `>>>` (array pipe) operator. The root cause is that the `>>>` operator creates a new PageData context and recursively calls `execute()` without passing the accumulated variables from the current execution context.

The fix involves modifying the `execute()` method to pass the current variable scope when handling the `>>>` operator, ensuring variables saved before the operator remain accessible in queries after it.

## Architecture

The QueryString execution flow follows this pattern:

1. **Query Parsing**: The query string is split by operators (`||`, `++`, `>>`, `>>>`) into QueryPart objects
2. **Query Execution**: Each QueryPart is executed sequentially, with results accumulated in a QueryResult
3. **Variable Management**: Variables are saved during transform application and stored in a Map<String, dynamic>
4. **Operator Handling**: Different operators have different behaviors:
   - `||` - Fallback (skip if previous succeeded)
   - `++` - Required (always execute)
   - `>>` - Pipe (execute on each item from previous result)
   - `>>>` - Array pipe (convert to JSON array, execute on array)

Currently, the `>>>` operator creates a new execution context without preserving variables.

## Components and Interfaces

### Modified Components

#### QueryString.execute()

The main entry point that needs modification. Currently handles `>>>` specially:

```dart
dynamic execute(PageNode node,
    {bool simplify = true, Map<String, dynamic>? initialVariables}) {
  // Check if query contains >>> operator
  if (query?.contains('>>>') ?? false) {
    // Split at >>> and handle specially
    final parts = query!.split('>>>');
    if (parts.length == 2) {
      // Execute first part
      final firstResult = QueryString(parts[0].trim())
          .execute(node, simplify: false, initialVariables: initialVariables);
      
      // ... convert to JSON array ...
      
      // Execute second part on the JSON array
      // BUG: variables from first execution are lost here
      return QueryString(parts[1].trim()).execute(arrayNode,
          simplify: simplify, initialVariables: initialVariables);
    }
  }
  // ...
}
```

**Issue**: The second `execute()` call only receives `initialVariables`, not the variables accumulated during the first part's execution.

#### QueryString._executeQueries()

This private method manages variable scope during normal query execution:

```dart
dynamic _executeQueries(PageNode node,
    {bool simplify = true, Map<String, dynamic>? initialVariables}) {
  final variables = <String, dynamic>{...?initialVariables};
  // ... executes queries and accumulates variables ...
}
```

The `variables` map is populated as queries execute, but this map is not accessible to the `>>>` operator handler in `execute()`.

### Data Models

#### Variable Scope

Variables are stored in a `Map<String, dynamic>` that is:
- Initialized from `initialVariables` parameter
- Populated during query execution via `?save=varName` transforms
- Used for variable substitution in paths, templates, and transforms

## Data Flow

### Current Flow (Buggy)

```
execute(node, initialVariables: {})
  ├─ Split query at ">>>"
  ├─ Execute part 1: QueryString(part1).execute(node, initialVariables: {})
  │   └─ _executeQueries(node, initialVariables: {})
  │       └─ variables = {fn: "Alice", ln: "Smith"}  // Lost!
  └─ Execute part 2: QueryString(part2).execute(arrayNode, initialVariables: {})
      └─ _executeQueries(arrayNode, initialVariables: {})
          └─ variables = {}  // Empty! Can't resolve ${fn} or ${ln}
```

### Fixed Flow

```
execute(node, initialVariables: {})
  ├─ Split query at ">>>"
  ├─ Execute part 1 with variable capture
  │   └─ Returns (result, variables: {fn: "Alice", ln: "Smith"})
  └─ Execute part 2: QueryString(part2).execute(arrayNode, 
                      initialVariables: {fn: "Alice", ln: "Smith"})
      └─ _executeQueries(arrayNode, initialVariables: {fn: "Alice", ln: "Smith"})
          └─ variables = {fn: "Alice", ln: "Smith"}  // Available!
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing the acceptance criteria, several properties were identified as redundant:
- Properties 3.1 and 3.2 are specific examples already covered by Property 1.2 (variable resolution in templates and paths)
- Property 1.4 is an implementation detail covered by the behavior tested in Properties 1.1-1.3
- Property 1.5 and 3.3 are edge cases for regexp handling that will be covered by test generators

The following properties provide comprehensive, non-redundant coverage:

### Property 1: Variable preservation across array pipe

*For any* variable name and value saved before a `>>>` operator, that variable should be accessible and resolvable in queries after the `>>>` operator.

**Validates: Requirements 1.1**

### Property 2: Variable resolution after array pipe

*For any* saved variable used in a template or path after a `>>>` operator, the QueryString should resolve the variable to its originally saved value.

**Validates: Requirements 1.2**

### Property 3: Multiple variable preservation

*For any* set of variables (one or more) saved before a `>>>` operator, all variables should remain accessible after the `>>>` operator.

**Validates: Requirements 1.3**

### Property 4: Operator consistency for variable scoping

*For any* variable saved before any query operator (`++`, `||`, `>>`, `>>>`), the variable should be accessible in subsequent queries with consistent behavior across all operator types.

**Validates: Requirements 2.1**

### Property 5: Initial variables preservation

*For any* set of initial variables passed to the execute method, those variables should remain accessible throughout the entire query chain, including after `>>>` operators.

**Validates: Requirements 2.2**

### Property 6: Nested array pipe variable scope

*For any* query chain containing multiple `>>>` operators, variables saved at any point should remain accessible in all subsequent queries regardless of nesting level.

**Validates: Requirements 2.3**

## Error Handling

### Current Error Handling

The QueryString class currently handles errors in several ways:
- Invalid query syntax throws `FormatException`
- Missing variables in templates/paths are silently left unresolved (e.g., `${missing}` stays as literal text)
- Null values are handled gracefully throughout the execution pipeline

### Error Handling for This Fix

The fix should maintain existing error handling behavior:
- If a variable is referenced but not saved, it should behave the same as before (left unresolved)
- No new exceptions should be introduced
- The fix should be transparent to existing error handling logic

### Edge Cases

1. **Empty variable map**: If no variables are saved before `>>>`, the behavior should be unchanged
2. **Variable name conflicts**: If a variable is saved multiple times, the latest value should be used (existing behavior)
3. **Null variable values**: Null values should be preserved and passed through `>>>` operator
4. **Multiple >>> operators**: Variables should accumulate across multiple `>>>` operators

## Testing Strategy

### Unit Testing

Unit tests will verify specific scenarios:

1. **Basic variable passing**: Save one variable before `>>>`, use it after
2. **Multiple variables**: Save multiple variables before `>>>`, use them after
3. **Template substitution**: Verify templates correctly resolve variables after `>>>` 
4. **Path substitution**: Verify paths correctly resolve variables after `>>>` 
5. **Initial variables**: Verify initialVariables parameter works with `>>>`
6. **Nested >>>**: Verify variables work across multiple `>>>` operators
7. **Edge cases**: Empty variables, null values, variable overwriting

### Property-Based Testing

Property-based tests will verify universal properties using the **fast_check** library for Dart (or **test** package with custom generators if fast_check is not available).

Each property test should run a minimum of 100 iterations to ensure comprehensive coverage.

**Property test requirements:**
- Each property-based test must be tagged with a comment referencing the design document property
- Tag format: `// Feature: variable-scope-array-pipe, Property N: <property text>`
- Each correctness property must be implemented by a single property-based test
- Tests should use smart generators that constrain inputs to valid query strings and variable names

**Test generators needed:**
- Variable names (valid identifiers)
- Variable values (strings, numbers, null)
- Query strings with `>>>` operator
- HTML and JSON test data

**Property tests to implement:**

1. **Property 1 test**: Generate random variable names/values, save before `>>>`, verify accessible after
2. **Property 2 test**: Generate random variables and templates/paths, verify correct resolution after `>>>`
3. **Property 3 test**: Generate random sets of variables (1-10), verify all preserved after `>>>`
4. **Property 4 test**: Generate queries with different operators, verify consistent variable behavior
5. **Property 5 test**: Generate random initial variables, verify preserved through `>>>` chains
6. **Property 6 test**: Generate queries with multiple `>>>`, verify variables accessible at all levels

### Integration Testing

Integration tests will verify the fix works with real-world query patterns:
- Complex queries combining multiple operators
- Queries with both HTML and JSON schemes
- Queries with transforms and filters
- Queries matching existing test patterns in the codebase

## Implementation Approach

### Solution Design

The fix requires modifying the `execute()` method to capture and pass variables across the `>>>` operator boundary.

**Option 1: Return variables from execute() (Rejected)**
- Modify execute() to return both result and variables
- Breaking change to public API
- Would require changes to all callers

**Option 2: Use internal method to capture variables (Selected)**
- Create an internal execution method that returns variables
- Keep public execute() API unchanged
- Minimal impact on existing code

### Detailed Implementation

1. **Refactor _executeQueries() to return variables**:
   ```dart
   ({dynamic result, Map<String, dynamic> variables}) _executeQueriesWithVariables(
       PageNode node,
       {bool simplify = true, Map<String, dynamic>? initialVariables}) {
     final variables = <String, dynamic>{...?initialVariables};
     // ... existing logic ...
     return (result: finalResult, variables: variables);
   }
   ```

2. **Modify execute() to use the new method for >>> handling**:
   ```dart
   dynamic execute(PageNode node,
       {bool simplify = true, Map<String, dynamic>? initialVariables}) {
     if (query?.contains('>>>') ?? false) {
       final parts = query!.split('>>>');
       if (parts.length == 2) {
         // Execute first part and capture variables
         final firstExecution = QueryString(parts[0].trim())
             ._executeQueriesWithVariables(node, 
                 simplify: false, 
                 initialVariables: initialVariables);
         
         // ... convert result to JSON array ...
         
         // Execute second part with captured variables
         return QueryString(parts[1].trim()).execute(arrayNode,
             simplify: simplify, 
             initialVariables: firstExecution.variables);  // Pass variables!
       }
     }
     
     // Normal execution
     return _executeQueriesWithVariables(node, 
         simplify: simplify, 
         initialVariables: initialVariables).result;
   }
   ```

3. **Keep _executeQueries() as a wrapper** (for backward compatibility if needed):
   ```dart
   dynamic _executeQueries(PageNode node,
       {bool simplify = true, Map<String, dynamic>? initialVariables}) {
     return _executeQueriesWithVariables(node, 
         simplify: simplify, 
         initialVariables: initialVariables).result;
   }
   ```

### Alternative Approaches Considered

1. **Global variable storage**: Use a class-level variable map
   - Rejected: Would cause issues with concurrent executions and testing
   
2. **Modify PageNode to carry variables**: Add variables to PageNode
   - Rejected: PageNode is a data model, not an execution context
   
3. **Use context object**: Create an ExecutionContext class
   - Rejected: Over-engineering for this fix, can be considered for future refactoring

## Dependencies

- No new external dependencies required
- Fix is contained within the QueryString class
- Existing test infrastructure (flutter_test) is sufficient

## Performance Considerations

- Minimal performance impact: only adds variable map copying at `>>>` boundaries
- Variable maps are typically small (< 10 entries)
- No impact on queries without `>>>` operator
- No impact on queries without saved variables

## Backward Compatibility

- Public API remains unchanged
- Existing queries continue to work as before
- Fix only affects queries using both `?save=` and `>>>` together
- No breaking changes
