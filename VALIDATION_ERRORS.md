# Query Validation Error Reference

Quick reference guide for common query validation errors and how to fix them.

## Error Types

### 1. Invalid Scheme

**Error Message:**
```
Invalid scheme 'jsn'
Did you mean 'json'? Valid schemes are: html, json, url, template
```

**Common Causes:**
- Typo in scheme name: `jsn` instead of `json`
- Misspelling: `htm` instead of `html`
- Incomplete: `templ` instead of `template`

**How to Fix:**
```dart
// ❌ Wrong
'jsn:items'
'htm:div'
'templ:${x}'

// ✓ Correct
'json:items'
'html:div'
'template:${x}'
```

---

### 2. Missing Scheme Separator

**Error Message:**
```
Missing ":" after scheme "json"
Use: json:items
```

**Common Causes:**
- Forgot the colon after scheme
- Used space instead of colon

**How to Fix:**
```dart
// ❌ Wrong
'json items'
'html div'
'url host'

// ✓ Correct
'json:items'
'html:div'
'url:host'
```

---

### 3. Parameter Syntax Error

**Error Message:**
```
Multiple "?" found in parameters. Use "&" to separate parameters
Example: ?param1=value&param2=value
```

**Common Causes:**
- Used `?` for additional parameters instead of `&`
- Forgot that only the first parameter uses `?`

**How to Fix:**
```dart
// ❌ Wrong
'json:items?save=x?keep'
'div/@text?transform=upper?filter=test'

// ✓ Correct
'json:items?save=x&keep'
'div/@text?transform=upper&filter=test'
```

**Remember:** First parameter uses `?`, additional parameters use `&`

---

### 4. Unmatched Variable Syntax

**Error Message:**
```
Unmatched "${" in variable syntax
Variables should be: ${varName}
```

**Common Causes:**
- Forgot closing `}`
- Typo in variable syntax

**How to Fix:**
```dart
// ❌ Wrong
'template:Hello ${name'
'json:items/${id'
'template:${user/name'

// ✓ Correct
'template:Hello ${name}'
'json:items/${id}'
'template:${user}'
```

**Remember:** Always close `${` with `}`

---

### 5. Invalid Operator

**Error Message:**
```
Invalid operator "+"
Valid operators are: ++, ||, >>, >>>
```

**Common Causes:**
- Used single character instead of double
- Used wrong operator symbol

**How to Fix:**
```dart
// ❌ Wrong
'json:a + json:b'   // Single +
'json:a | json:b'   // Single |
'json:a > json:b'   // Single >
'json:a & json:b'   // Wrong symbol

// ✓ Correct
'json:a ++ json:b'  // Required (AND)
'json:a || json:b'  // Fallback (OR)
'json:a >> json:b'  // Pipe
'json:a >>> json:b' // Pipe with flatten
```

**Operator Guide:**
- `++` = Required (execute both, combine results)
- `||` = Fallback (try first, use second if empty)
- `>>` = Pipe (pass result to next query)
- `>>>` = Pipe with flatten (pass and flatten arrays)

---

## Quick Fixes

### Scheme Typos

| Wrong | Correct |
|-------|---------|
| `jsn:` | `json:` |
| `htm:` | `html:` |
| `templ:` | `template:` |
| `jason:` | `json:` |

### Parameter Separators

| Wrong | Correct |
|-------|---------|
| `?a=1?b=2` | `?a=1&b=2` |
| `?save=x?keep` | `?save=x&keep` |
| `?transform=upper?filter=test` | `?transform=upper&filter=test` |

### Operators

| Wrong | Correct | Meaning |
|-------|---------|---------|
| `+` | `++` | Required (AND) |
| `\|` | `\|\|` | Fallback (OR) |
| `>` | `>>` | Pipe |
| `&` | `++` | Required (AND) |

### Variable Syntax

| Wrong | Correct |
|-------|---------|
| `${name` | `${name}` |
| `$name` | `${name}` |
| `{name}` | `${name}` |

---

## Validation Checklist

Before executing a query, check:

- [ ] Scheme is one of: `html`, `json`, `url`, `template`
- [ ] Scheme is followed by `:` (e.g., `json:`)
- [ ] First parameter uses `?`, additional use `&`
- [ ] All `${` have matching `}`
- [ ] Operators are: `++`, `||`, `>>`, or `>>>`
- [ ] No typos in scheme names

---

## Testing Your Query

```dart
// Always validate complex queries
final query = QueryString(yourQueryString);
final result = query.validate();

if (!result.isValid) {
  print('Errors found:');
  for (var error in result.errors) {
    print('- ${error.message}');
  }
  return;
}

// Query is valid, execute it
final data = query.execute(node);
```

---

## Common Patterns

### Valid Query Examples

```dart
// Simple queries
'json:items'
'html:div/@text'
'url:host'
'template:${name}'

// With parameters
'json:items?save=x&keep'
'div/@text?transform=upper&filter=test'

// With operators
'json:title ++ json:description'
'json:title || h1/@text'
'json:data >> json:items/*'

// Complex queries
'json:firstName?save=fn ++ json:lastName?save=ln ++ template:${fn} ${ln}'
'html:script/@text?transform=json >> json:config/apiKey'
'json:items/* >> json:tags/* >>> json:name'
```

### Invalid Query Examples

```dart
// ❌ These will fail validation
'jsn:items'                    // Invalid scheme
'json items'                   // Missing colon
'json:items?save=x?keep'       // Wrong parameter separator
'template:${name'              // Unclosed variable
'json:a + json:b'              // Invalid operator
```

---

## Getting Help

1. **Read the error message** - It includes suggestions and examples
2. **Check this reference** - Common errors and fixes
3. **Use validation** - Call `validate()` to see all errors
4. **Read the docs** - See [VALIDATION_GUIDE.md](VALIDATION_GUIDE.md) for detailed information
5. **Check examples** - See [README.md](README.md) for working examples

---

## Summary

Most validation errors fall into these categories:

1. **Typos** - Misspelled scheme names (use suggestions)
2. **Missing separators** - Forgot `:` or used wrong parameter separator
3. **Unclosed syntax** - Forgot to close `${}`
4. **Wrong operators** - Used single character instead of double

The validator provides helpful suggestions for all these cases. Always read the error message carefully - it includes the fix!
