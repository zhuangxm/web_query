# Requirements Document

## Introduction

This specification addresses the reorganization of the transform processing system in the web_query library. The current implementation in `lib/src/transforms.dart` mixes multiple concerns including transform orchestration, specific transform implementations, and utility functions. This reorganization will improve code clarity, maintainability, and testability by separating concerns and establishing clear boundaries between different types of transforms.

## Glossary

- **Transform System**: The collection of components responsible for applying data transformations to query results
- **Transform Orchestrator**: The component that coordinates the application of multiple transforms in sequence
- **Transform Handler**: A component responsible for implementing a specific type of transform (e.g., regexp, json, filter)
- **Transform Pipeline**: The ordered sequence of transforms applied to a value
- **DiscardMarker**: A wrapper class that indicates a value should be omitted from final results
- **PageNode**: The context object containing page data and metadata available during transform execution

## Requirements

### Requirement 1

**User Story:** As a developer maintaining the web_query library, I want transforms organized by type and responsibility, so that I can easily locate and modify specific transform implementations.

#### Acceptance Criteria

1. WHEN the transform system is organized THEN the system SHALL separate transform orchestration from transform implementation
2. WHEN a developer needs to modify a specific transform type THEN the system SHALL provide dedicated files for each transform category
3. WHEN the codebase is analyzed THEN the system SHALL demonstrate clear separation between core transforms, text transforms, and data transforms
4. WHEN new transforms are added THEN the system SHALL provide a clear pattern for where to place the implementation

### Requirement 2

**User Story:** As a developer working with the transform system, I want a clear transform pipeline architecture, so that I can understand how transforms are applied in sequence.

#### Acceptance Criteria

1. WHEN multiple transforms are applied to a value THEN the system SHALL process them through a well-defined pipeline
2. WHEN a transform is executed THEN the system SHALL pass the result to the next transform in the sequence
3. WHEN the transform pipeline is examined THEN the system SHALL clearly show the order of operations (transform, update, filter, index, save, discard)
4. WHEN debugging transform issues THEN the system SHALL provide clear entry points for each stage of the pipeline

### Requirement 3

**User Story:** As a developer implementing new transform types, I want a consistent interface for transform handlers, so that all transforms follow the same pattern.

#### Acceptance Criteria

1. WHEN a new transform handler is created THEN the system SHALL require it to implement a standard interface
2. WHEN a transform is applied THEN the system SHALL handle both single values and lists consistently
3. WHEN a transform receives null input THEN the system SHALL handle it gracefully according to transform-specific rules
4. WHEN transforms are registered THEN the system SHALL provide a mechanism for the orchestrator to discover and invoke them

### Requirement 4

**User Story:** As a developer maintaining regexp transforms, I want regexp-specific logic isolated, so that I can modify regexp behavior without affecting other transforms.

#### Acceptance Criteria

1. WHEN regexp transforms are implemented THEN the system SHALL isolate pattern parsing, matching, and replacement logic
2. WHEN regexp patterns include special keywords like \\ALL THEN the system SHALL handle them in the regexp-specific module
3. WHEN regexp replacements reference page context THEN the system SHALL provide access to PageNode data
4. WHEN regexp errors occur THEN the system SHALL log warnings specific to regexp processing

### Requirement 5

**User Story:** As a developer working with JSON transforms, I want JSON extraction and parsing logic separated, so that I can enhance JSON handling independently.

#### Acceptance Criteria

1. WHEN JSON transforms are applied THEN the system SHALL isolate JavaScript variable extraction from JSON parsing
2. WHEN JSON transform extracts variables THEN the system SHALL support wildcard patterns in variable names
3. WHEN JSON parsing fails THEN the system SHALL log warnings specific to JSON processing
4. WHEN JSON transforms handle different value types THEN the system SHALL support objects, arrays, primitives, booleans, and null

### Requirement 6

**User Story:** As a developer implementing filter and index operations, I want these operations grouped together, so that I can understand data selection logic in one place.

#### Acceptance Criteria

1. WHEN filter operations are applied THEN the system SHALL support both include and exclude patterns
2. WHEN filter patterns contain special characters THEN the system SHALL properly escape and unescape them
3. WHEN index operations are applied THEN the system SHALL support both positive and negative indices
4. WHEN index operations receive out-of-bounds values THEN the system SHALL return null gracefully

### Requirement 7

**User Story:** As a developer working with variable management, I want save and discard operations clearly separated from data transforms, so that I can understand state management independently.

#### Acceptance Criteria

1. WHEN save operations are executed THEN the system SHALL store values in the variables map before any discard marking
2. WHEN discard operations are executed THEN the system SHALL wrap values in DiscardMarker instances
3. WHEN variables are saved THEN the system SHALL handle null values appropriately
4. WHEN the DiscardMarker class is used THEN the system SHALL provide clear documentation of its purpose

### Requirement 8

**User Story:** As a developer integrating JavaScript execution, I want JS executor management isolated, so that I can modify JavaScript integration without affecting other transforms.

#### Acceptance Criteria

1. WHEN JavaScript transforms are applied THEN the system SHALL use a registry pattern for executor instances
2. WHEN the JS executor is not configured THEN the system SHALL provide clear error messages
3. WHEN JavaScript variables are extracted THEN the system SHALL support comma-separated variable name lists
4. WHEN JavaScript execution fails THEN the system SHALL log warnings and return null gracefully
