# Requirements Document

## Introduction

This specification addresses a bug in the QueryString library where saved variables are not available in subsequent query chains when using the `>>>` (array pipe) operator. Currently, variables saved with `?save=varName` before a `>>>` operator cannot be referenced in queries after the `>>>` operator, breaking the expected variable scoping behavior.

## Glossary

- **QueryString**: The main query execution class that parses and executes query strings against HTML/JSON data
- **Array Pipe Operator (`>>>`)**: A special operator that converts the result of the previous query into a JSON array and executes the next query on that array
- **Variable**: A named value saved during query execution using the `?save=varName` parameter
- **Query Chain**: A sequence of queries connected by operators (`++`, `||`, `>>`, `>>>`)
- **PageNode**: A wrapper object representing either an HTML element or JSON data that queries operate on

## Requirements

### Requirement 1

**User Story:** As a developer using QueryString, I want to save variables before an array pipe operator and use them in queries after the array pipe, so that I can reference earlier query results in subsequent array operations.

#### Acceptance Criteria

1. WHEN a variable is saved using `?save=varName` before a `>>>` operator, THEN the QueryString SHALL preserve that variable for use in queries after the `>>>` operator
2. WHEN a template or path references a saved variable after a `>>>` operator, THEN the QueryString SHALL resolve the variable to its saved value
3. WHEN multiple variables are saved before a `>>>` operator, THEN the QueryString SHALL preserve all variables for use after the `>>>` operator
4. WHEN the `>>>` operator creates a new PageData context, THEN the QueryString SHALL pass the current variable scope to the new execution context
5. WHEN variables are used in regexp transforms after a `>>>` operator, THEN the QueryString SHALL resolve the variables correctly

### Requirement 2

**User Story:** As a developer, I want consistent variable scoping across all query operators, so that I can predict how variables will behave regardless of which operators I use.

#### Acceptance Criteria

1. WHEN variables are saved before any operator (`++`, `||`, `>>`, `>>>`), THEN the QueryString SHALL maintain the same variable scoping behavior across all operators
2. WHEN the `execute` method is called with `initialVariables`, THEN the QueryString SHALL preserve those variables throughout the entire query chain including after `>>>` operators
3. WHEN a query chain contains nested `>>>` operators, THEN the QueryString SHALL maintain variable scope across all nesting levels

### Requirement 3

**User Story:** As a developer, I want to combine array pipe operations with variable substitution, so that I can perform complex data transformations that reference earlier query results.

#### Acceptance Criteria

1. WHEN a query uses `?save=varName` before `>>>` and then uses `template:${varName}` after `>>>`, THEN the QueryString SHALL correctly substitute the saved variable value
2. WHEN a query uses `?save=varName` before `>>>` and then uses the variable in a path like `json:items/${varName}`, THEN the QueryString SHALL correctly resolve the path
3. WHEN a query uses `?save=varName` before `>>>` and then uses the variable in a regexp like `regexp:/${varName}/replacement/`, THEN the QueryString SHALL correctly apply the regexp transform
