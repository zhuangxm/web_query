class QueryPart {
  // Scheme constants for query types
  static const String schemeHtml = 'html';
  static const String schemeJson = 'json';
  static const String schemeUrl = 'url';
  static const String schemeTemplate = 'template';

  // Parameter keyword constants
  static const String paramTransform = 'transform';
  static const String paramFilter = 'filter';
  static const String paramUpdate = 'update';
  static const String paramRegexp = 'regexp';
  static const String paramSave = 'save';
  static const String paramKeep = 'keep';
  static const String paramRequired = 'required';

  final String scheme;
  final String path;
  final bool required;
  final bool isPipe;
  final Map<String, List<String>> parameters;
  final Map<String, List<String>> transforms;

  QueryPart(
      this.scheme, this.path, this.parameters, this.transforms, this.required,
      {this.isPipe = false});

  static String _encodeSelectorPart(String part) {
    // Encode # in selectors but preserve in query params
    if (part.contains('?')) {
      final index = part.indexOf('?');
      final firstPart = part.substring(0, index);
      final secondPart = part.substring(index + 1);
      return '${firstPart.replaceAll('#', '%23')}?$secondPart';
    }
    return part.replaceAll('#', '%23');
  }

  static List<String> _splitTransforms(String value) {
    // Split on semicolons that are followed by known transform keywords
    // This allows regexp patterns with semicolons to stay intact
    // Example: "upper;regexp:/a;b/c/;lower" -> ["upper", "regexp:/a;b/c/", "lower"]

    // Known transform keywords that can follow a semicolon
    const transformKeywords = r'(?:upper|lower|json|jseval|regexp)';

    // Split on semicolons that are:
    // 1. NOT preceded by a backslash (negative lookbehind: (?<!\\))
    // 2. Followed by a transform keyword (positive lookahead: (?=...))
    final pattern = RegExp(r'(?<!\\);(?=' + transformKeywords + r':?)');

    return value.split(pattern);
  }

  static QueryPart parse(String queryString,
      {required bool required, bool isPipe = false}) {
    var scheme = schemeHtml;

    //remove scheme header
    for (var s in [schemeJson, schemeHtml, schemeUrl, schemeTemplate]) {
      if (queryString.startsWith('$s:')) {
        scheme = s;
        queryString = queryString.substring(s.length + 1);
        break;
      }
    }

    // Pre-encode selectors
    queryString = _encodeSelectorPart(queryString);

    // Negative lookahead pattern to prevent matching reserved parameter names
    // This ensures we don't accidentally capture "&filter=", "&update=", etc. as part of a value
    // Example: "transform=upper&filter=test" should capture "upper" not "upper&filter"
    const notLookAheadKeyWords =
        '(?!&(?:$paramFilter|$paramUpdate|$paramTransform|$paramRegexp|$paramSave|$paramKeep)=)';

    // Match any character (.) that is NOT followed by our reserved keywords
    // This creates a pattern that captures parameter values up to (but not including) the next reserved parameter
    const notLookAt = '(?:$notLookAheadKeyWords.)';

    // Pre-encode transform values
    // Matches "transform=" followed by any characters that don't start a new reserved parameter
    final transformRegex = RegExp('$paramTransform=($notLookAt*)');
    queryString = queryString.replaceAllMapped(transformRegex, (match) {
      return '$paramTransform=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode filter values
    // Matches "filter=" followed by any characters that don't start a new reserved parameter
    final filterRegex = RegExp('$paramFilter=($notLookAt*)');
    queryString = queryString.replaceAllMapped(filterRegex, (match) {
      return '$paramFilter=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode update values
    // Matches "update=" followed by any characters that don't start a new reserved parameter
    final updateRegex = RegExp('$paramUpdate=($notLookAt*)');
    queryString = queryString.replaceAllMapped(updateRegex, (match) {
      return '$paramUpdate=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode regexp values
    // Matches "regexp=" followed by any characters that don't start a new reserved parameter
    final regexpRegex = RegExp('$paramRegexp=($notLookAt*)');
    queryString = queryString.replaceAllMapped(regexpRegex, (match) {
      return '$paramRegexp=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode save values (stop at & or end of string)
    // Matches "save=" followed by any characters except "&" (which starts the next parameter)
    // [^&]* means: match zero or more characters that are NOT "&"
    // Example: "save=myVar&other=value" captures "myVar"
    final saveRegex = RegExp('$paramSave=([^&]*)');
    queryString = queryString.replaceAllMapped(saveRegex, (match) {
      return '$paramSave=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode keep values (stop at & or end of string)
    final keepRegex = RegExp('$paramKeep=([^&]*)');
    queryString = queryString.replaceAllMapped(keepRegex, (match) {
      return '$paramKeep=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Add dummy host if needed
    if (!queryString.contains('://')) {
      queryString = '$scheme://dummy/$queryString';
    }

    final uri = Uri.parse(queryString);
    var path = Uri.decodeFull(uri.path.replaceFirst('/dummy/', ''));
    if (path.startsWith('/') &&
        (scheme == schemeUrl || scheme == schemeTemplate)) {
      path = path.substring(1);
    }

    final params = <String, List<String>>{};
    uri.queryParametersAll.forEach((key, values) {
      for (var value in values) {
        if (key == paramTransform) {
          if (params.containsKey(key)) {
            params[key]!.addAll(_splitTransforms(value));
          } else {
            params[key] = _splitTransforms(value);
          }
        } else {
          // Split on semicolons that are NOT preceded by a backslash (negative lookbehind)
          // This allows escaped semicolons (\;) to be preserved in parameter values
          final parts = value.split(RegExp(r'(?<!\\);'));
          if (params.containsKey(key)) {
            params[key]!.addAll(parts);
          } else {
            params[key] = parts;
          }
        }
      }
    });

    final transforms = <String, List<String>>{};
    if (params.containsKey(paramTransform)) {
      transforms[paramTransform] = params[paramTransform]!;
      params.remove(paramTransform);
    }
    if (params.containsKey(paramRegexp)) {
      final regexps =
          params[paramRegexp]!.map((e) => '$paramRegexp:$e').toList();
      if (transforms.containsKey(paramTransform)) {
        transforms[paramTransform]!.addAll(regexps);
      } else {
        transforms[paramTransform] = regexps;
      }
      params.remove(paramRegexp);
    }
    if (params.containsKey(paramUpdate)) {
      transforms[paramUpdate] = params[paramUpdate]!;
      params.remove(paramUpdate);
    }
    if (params.containsKey(paramFilter)) {
      transforms[paramFilter] = params[paramFilter]!;
      params.remove(paramFilter);
    }
    if (params.containsKey(paramSave)) {
      transforms[paramSave] = params[paramSave]!;
      params.remove(paramSave);
    }
    if (params.containsKey(paramKeep)) {
      transforms[paramKeep] = params[paramKeep]!;
      params.remove(paramKeep);
    }

    // Validate parameters - check for unknown/typo parameters
    _validateParameters(params, transforms, scheme);

    return QueryPart(scheme, path, params, transforms, required,
        isPipe: isPipe);
  }

  static void _validateParameters(Map<String, List<String>> params,
      Map<String, List<String>> transforms, String scheme) {
    // Known valid parameter names
    const validParams = {paramRequired};
    const validTransforms = {
      paramTransform,
      paramFilter,
      paramUpdate,
      paramSave,
      paramKeep,
      paramRegexp
    };

    // Check for unknown parameters (likely typos)
    // Skip validation for URL scheme as it has dynamic parameters (_scheme, _host, etc.)
    if (scheme != schemeUrl) {
      for (var key in params.keys) {
        if (!validParams.contains(key)) {
          throw FormatException(
              'Unknown query parameter: "$key". Did you mean one of: ${validTransforms.join(', ')}?');
        }
      }
    }

    // Validate transform values
    if (transforms.containsKey(paramTransform)) {
      for (var transform in transforms[paramTransform]!) {
        _validateTransform(transform);
      }
    }

    // Validate save parameter has a value
    if (transforms.containsKey(paramSave)) {
      for (var saveVar in transforms[paramSave]!) {
        if (saveVar.isEmpty) {
          throw const FormatException(
              'save parameter requires a variable name: ?save=varName');
        }
      }
    }
  }

  static void _validateTransform(String transform) {
    // Check for common transform types
    if (transform.startsWith('$paramRegexp:')) {
      final pattern = transform.substring(7);
      if (pattern.isEmpty) {
        throw const FormatException(
            'regexp transform requires a pattern: ?transform=regexp:/pattern/');
      }
      // Don't validate regexp format - let it fail at runtime for better error messages
    } else if (transform.startsWith('json:')) {
      // json: can have optional variable name, so just check it's not malformed
      final varName = transform.substring(5);
      if (varName.contains('?') || varName.contains('&')) {
        throw const FormatException(
            'Invalid json transform format: ?transform=json:varName');
      }
    } else if (transform.startsWith('jseval:')) {
      // jseval: can have optional variable names
      final varNames = transform.substring(7);
      if (varNames.contains('?') || varNames.contains('&')) {
        throw const FormatException(
            'Invalid jseval transform format: ?transform=jseval:var1,var2');
      }
    } else if (!['upper', 'lower', 'json', 'jseval'].contains(transform)) {
      // Unknown transform - might be a typo
      throw FormatException(
          'Unknown transform: "$transform". Valid transforms: upper, lower, json, jseval, regexp');
    }
  }

  bool isRequired() {
    return required;
  }

  @override
  String toString() {
    return "QueryPart(scheme: $scheme, path: $path, parameters: $parameters, transforms: $transforms, required: $required, isPipe: $isPipe)";
  }
}
