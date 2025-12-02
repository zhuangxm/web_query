# Requirements Document

## Introduction

This specification addresses the need for better syntax validation and error reporting in QueryString parsing. Currently, when users write long or complex query strings, syntax errors (such as scheme typos, missing separators, malformed parameters) can result in cryptic error messages or silent failures that are difficult to debug. This feature will provide clear, actionable error messages that help users quickly identify and fix syntax issues in their query strings.

## Glossary

- **QueryString**: The main query execution class that parses and executes query strings against HTML/JSON data
- **Scheme**: The query type prefix (html, json, url, template) that determines how the path is interpreted
- **Parameter**: A key-value pair in the query string (e.g., `?save=varName`, `&keep`)
- **Operator**: A symbol that connects query parts (`++`, `||`, `>>`, `>>>`)
- **Path**: The selector or navigation expression after the scheme (e.g., `json:items/name`)
- **Validation**: The process of checking query string syntax for common errors before execution
- **Syntax Error**: A malformed query string that violates the expected grammar

## Requirements

### Requirement 1

**User Story:** As a developer writing query strings, I want to receive clear error messages when I make syntax mistakes, so that I can quickly identify and fix issues without trial and error.

#### Acceptance Criteria

1. WHEN a query string contains an invalid scheme name, THEN the QueryString SHALL throw a FormatException with a message listing valid schemes
2. WHEN a query string has multiple `?` characters without `&` separators, THEN the QueryString SHALL throw a FormatException indicating the parameter syntax error
3. WHEN a query string contains unmatched `${}` variable syntax, THEN the QueryString SHALL throw a FormatException indicating the variable syntax error
4. WHEN a query string contains an invalid operator, THEN the QueryString SHALL throw a FormatException listing valid operators
5. WHEN a query string is missing a `:` after a scheme prefix, THEN the QueryString SHALL throw a FormatException indicating the missing separator

### Requirement 2

**User Story:** As a developer debugging query strings, I want error messages to include the position of the error in the query string, so that I can quickly locate the problem in long queries.

#### Acceptance Criteria

1. WHEN a validation error occurs, THEN the QueryString SHALL include the character position or approximate location in the error message
2. WHEN a validation error occurs in a multi-part query (with operators), THEN the QueryString SHALL indicate which query part contains the error
3. WHEN a validation error occurs, THEN the QueryString SHALL include a snippet of the problematic section in the error message

### Requirement 3

**User Story:** As a developer, I want validation to catch common typos and mistakes, so that I don't waste time debugging issues that could be prevented.

#### Acceptance Criteria

1. WHEN a query string contains a scheme that is close to a valid scheme (e.g., "jsn" instead of "json"), THEN the QueryString SHALL suggest the correct scheme in the error message
2. WHEN a query string contains common parameter mistakes (e.g., `?save=x?keep` instead of `?save=x&keep`), THEN the QueryString SHALL provide a corrected example in the error message
3. WHEN a query string contains unescaped special characters in regexp patterns, THEN the QueryString SHALL warn about potential escaping issues

### Requirement 4

**User Story:** As a developer, I want to manually validate my query strings to get detailed information about syntax issues, warnings, and query structure, so that I can debug problems and understand my queries without affecting execution.

#### Acceptance Criteria

1. WHEN a user calls `QueryString.validate()`, THEN the QueryString SHALL return a ValidationResult containing errors, warnings, and query information
2. WHEN validation is not called, THEN the QueryString SHALL execute normally without automatic validation
3. WHEN validation finds errors, THEN the ValidationResult SHALL contain a list of all errors found (not just the first one)
4. WHEN validation finds potential issues, THEN the ValidationResult SHALL contain warnings that don't prevent execution
5. WHEN validation finds no issues, THEN the ValidationResult SHALL contain detailed query information including parts, operators, transforms, and variables
6. WHEN a user calls `toString()` on ValidationResult, THEN it SHALL return a human-readable format showing errors/warnings or query information
7. WHEN a user calls `toJson()` on ValidationResult, THEN it SHALL return a JSON string that can be logged or sent to APIs

### Requirement 5

**User Story:** As a developer, I want helpful error messages and warnings that guide me toward the solution, so that I can fix issues without consulting documentation.

#### Acceptance Criteria

1. WHEN a validation error occurs, THEN the error message SHALL include a brief explanation of the rule that was violated
2. WHEN a validation error occurs, THEN the error message SHALL include an example of correct syntax
3. WHEN multiple validation errors exist, THEN the ValidationResult SHALL report ALL errors found, not just the first one
4. WHEN validation detects potential issues that don't prevent execution, THEN the ValidationResult SHALL include warnings with suggestions

### Requirement 6

**User Story:** As a developer, I want validation to be separate from execution, so that bugs in the validation logic don't prevent my queries from running.

#### Acceptance Criteria

1. WHEN a QueryString is constructed or executed, THEN validation SHALL NOT be automatically invoked
2. WHEN validation has bugs or throws unexpected exceptions, THEN query execution SHALL continue to work normally
3. WHEN a user wants validation information, THEN they SHALL explicitly call the `validate()` method
4. WHEN validation is called, THEN it SHALL not modify the QueryString state or affect subsequent executions
