# Code Conventions

## QueryString Variable and Template Handling

### Keep vs Discard Pattern

When using `?save=` to set variables in QueryString, results are **automatically omitted** from the final output unless explicitly marked with `&keep`.

**Default behavior (without `&keep`):**
```dart
// Variables are saved but NOT included in final result
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
// Result: "Alice Smith" (only the template result)
```

**Explicit keep:**
```dart
// Use &keep to include intermediate results
'json:firstName?save=fn&keep ++ json:lastName?save=ln&keep ++ template:${fn} ${ln}'
// Result: ["Alice", "Smith", "Alice Smith"]
```

### Key Rules

1. **`?save=varName`** - Automatically omits the result from final output
2. **`?save=varName&keep`** - Saves variable AND includes result in output
3. This behavior applies regardless of the `simplify` parameter value
4. The `template:` scheme typically doesn't need `&keep` as it's usually the final result

### Examples

```dart
// Extract and combine data (only show template)
'json:user/id?save=id ++ json:user/name?save=name ++ template:User ${id}: ${name}'
// Returns: "User 123: Alice"

// Keep intermediate values
'json:price?save=p&keep ++ json:tax?save=t&keep ++ template:Price: ${p}, Tax: ${t}'
// Returns: [19.99, 2.00, "Price: 19.99, Tax: 2.00"]

// Multiple variables, selective keeping
'json:a?save=x ++ json:b?save=y&keep ++ template:${x}+${y}'
// Returns: [<value of b>, "<value of a>+<value of b>"]
```

### Migration Note

The old `&discard` parameter is deprecated. Use the inverse logic:
- Old: `?save=x&discard` (explicitly discard)
- New: `?save=x` (automatically omitted, no tag needed)
- Old: `?save=x` (kept by default)
- New: `?save=x&keep` (explicitly keep)
