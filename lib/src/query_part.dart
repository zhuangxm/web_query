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

  /// Extracts and removes the scheme prefix from the query string
  static ({String scheme, String queryString}) _extractScheme(
      String queryString) {
    var scheme = schemeHtml;

    // Remove scheme header
    for (var s in [schemeJson, schemeHtml, schemeUrl, schemeTemplate]) {
      if (queryString.startsWith('$s:')) {
        scheme = s;
        queryString = queryString.substring(s.length + 1);
        break;
      }
    }

    return (scheme: scheme, queryString: queryString);
  }

  /// Pre-encodes reserved parameter values to prevent URI parsing issues
  static String _preEncodeReservedParameters(String queryString) {
    // Pre-encode selectors
    queryString = _encodeSelectorPart(queryString);

    // Negative lookahead pattern to prevent matching reserved parameter names
    const notLookAheadKeyWords =
        '(?!&(?:$paramFilter|$paramUpdate|$paramTransform|$paramRegexp|$paramSave|$paramKeep)(?:=|&|\$))';
    const notLookAt = '(?:$notLookAheadKeyWords.)';

    // Helper to encode a parameter value
    void encodeParam(String paramName) {
      final regex = RegExp('$paramName=($notLookAt*)');
      queryString = queryString.replaceAllMapped(regex, (match) {
        return '$paramName=${Uri.encodeQueryComponent(match.group(1)!)}';
      });
    }

    // Pre-encode all reserved parameters
    encodeParam(paramTransform);
    encodeParam(paramFilter);
    encodeParam(paramUpdate);
    encodeParam(paramRegexp);

    // Save and keep use simpler pattern (stop at & or end)
    for (var param in [paramSave, paramKeep]) {
      final regex = RegExp('$param=([^&]*)');
      queryString = queryString.replaceAllMapped(regex, (match) {
        return '$param=${Uri.encodeQueryComponent(match.group(1)!)}';
      });
    }

    return queryString;
  }

  /// Parses the query string as a URI and extracts the path
  static ({Uri uri, String path}) _parseUri(String queryString, String scheme) {
    // Add dummy host if needed
    if (!queryString.contains('://')) {
      queryString = '$scheme://dummy/$queryString';
    }

    final uri = Uri.parse(queryString);
    var path = Uri.decodeFull(uri.path.replaceFirst('/dummy/', ''));

    // Remove leading slash for url and template schemes
    if (path.startsWith('/') &&
        (scheme == schemeUrl || scheme == schemeTemplate)) {
      path = path.substring(1);
    }

    return (uri: uri, path: path);
  }

  /// Extracts query parameters from the URI
  static Map<String, List<String>> _extractQueryParameters(Uri uri) {
    final params = <String, List<String>>{};

    uri.queryParametersAll.forEach((key, values) {
      for (var value in values) {
        final parts = key == paramTransform
            ? _splitTransforms(value)
            : value.split(RegExp(r'(?<!\\);')); // Split on unescaped semicolons

        if (params.containsKey(key)) {
          params[key]!.addAll(parts);
        } else {
          params[key] = parts;
        }
      }
    });

    return params;
  }

  /// Moves transform-related parameters from params to transforms map
  static Map<String, List<String>> _moveParamsToTransforms(
      Map<String, List<String>> params) {
    final transforms = <String, List<String>>{};

    // Move transform parameter
    if (params.containsKey(paramTransform)) {
      transforms[paramTransform] = params.remove(paramTransform)!;
    }

    // Move regexp parameter and convert to transform format
    if (params.containsKey(paramRegexp)) {
      final regexps =
          params.remove(paramRegexp)!.map((e) => '$paramRegexp:$e').toList();

      if (transforms.containsKey(paramTransform)) {
        transforms[paramTransform]!.addAll(regexps);
      } else {
        transforms[paramTransform] = regexps;
      }
    }

    // Move other transform-related parameters
    for (var param in [paramUpdate, paramFilter, paramSave, paramKeep]) {
      if (params.containsKey(param)) {
        transforms[param] = params.remove(param)!;
      }
    }

    return transforms;
  }

  static QueryPart parse(String queryString,
      {required bool required, bool isPipe = false}) {
    // Extract scheme
    final schemeResult = _extractScheme(queryString);
    final scheme = schemeResult.scheme;
    queryString = schemeResult.queryString;

    // Special handling for template scheme - treat entire content as path
    // Template content may contain ? and & characters that are part of the URL
    // being templated, not QueryPart parameters
    if (scheme == schemeTemplate) {
      return QueryPart(scheme, queryString, {}, {}, required, isPipe: isPipe);
    }

    // Pre-encode reserved parameters
    queryString = _preEncodeReservedParameters(queryString);

    // Parse URI and extract path
    final uriResult = _parseUri(queryString, scheme);
    final uri = uriResult.uri;
    final path = uriResult.path;

    // Extract query parameters
    final params = _extractQueryParameters(uri);

    // Move transform-related params to transforms map
    final transforms = _moveParamsToTransforms(params);

    // Validate parameters
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
