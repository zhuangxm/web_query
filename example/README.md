# DataQueryWidget Example

This example demonstrates how to use the `DataQueryWidget` to visually query and explore HTML and JSON data.

## Features

- Load HTML pages from URLs
- View HTML structure in an interactive tree
- Query data using QueryString syntax
- See real-time query results
- Switch between HTML and JSON views

## Running the Example

```bash
cd example
flutter pub get
flutter run
```

## Usage

1. **Load Sample Data**: Click "Load Sample" to load a sample HTML page with embedded JSON
2. **Enter Queries**: Type QueryString queries in the filter panel
3. **View Results**: See matching results highlighted in the results panel
4. **Explore HTML**: Navigate the HTML tree structure in the left panel

## Query Examples

### HTML Queries
- `h1@text` - Get h1 text content
- `.intro@text` - Get intro paragraph
- `*li@text` - Get all list items
- `a@href` - Get first link href

### JSON Queries
- `json:title` - Get title from JSON
- `json:items/*` - Get all items
- `json:items/0/name` - Get first item name

### With Transforms
- `h1@text?transform=upper` - Uppercase title
- `*li@text?filter=JSON` - Filter items containing "JSON"
- `a@href?regexp=/https:\\/\\/([^\\/]+).*$/\$1/` - Extract domain

### URL Queries
- `url:` - Get full URL
- `url:host` - Get hostname
- `url:?page=2` - Modify query parameter

## Learn More

See the [main README](../README.md) for complete QueryString syntax documentation.
