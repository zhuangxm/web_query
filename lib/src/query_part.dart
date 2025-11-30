class QueryPart {
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
    final rawParts = value.split(RegExp(r'(?<!\\);'));
    final result = <String>[];
    String? pending;

    for (var part in rawParts) {
      if (pending != null) {
        pending = '$pending;$part';
      } else {
        if (part.trim().startsWith('regexp:')) {
          pending = part;
        } else {
          result.add(part);
          continue;
        }
      }

      if (_isCompleteRegexp(pending)) {
        result.add(pending);
        pending = null;
      }
    }

    if (pending != null) {
      result.add(pending);
    }

    return result;
  }

  static bool _isCompleteRegexp(String value) {
    if (!value.startsWith('regexp:')) return true;

    // Find first slash
    final firstSlash = value.indexOf('/');
    if (firstSlash == -1) return false;

    // Find second slash (end of pattern)
    final secondSlash = _findNextSlash(value, firstSlash + 1);
    if (secondSlash == -1) return false;

    // If string ends here, it's valid (pattern only)
    if (secondSlash == value.length - 1) return true;

    // Find third slash (end of replacement)
    final thirdSlash = _findNextSlash(value, secondSlash + 1);
    if (thirdSlash == -1) return false;

    // If string ends here, it's valid (replacement)
    if (thirdSlash == value.length - 1) return true;

    return false;
  }

  static int _findNextSlash(String value, int start) {
    for (var i = start; i < value.length; i++) {
      if (value[i] == '/' && (i == 0 || value[i - 1] != '\\')) {
        return i;
      }
    }
    return -1;
  }

  static QueryPart parse(String queryString,
      {required bool required, bool isPipe = false}) {
    var scheme = 'html';
    if (queryString.startsWith('json:')) {
      scheme = 'json';
      queryString = queryString.substring(5);
    } else if (queryString.startsWith('html:')) {
      queryString = queryString.substring(5);
    } else if (queryString.startsWith('url:')) {
      scheme = 'url';
      queryString = queryString.substring(4);
    } else if (queryString.startsWith('template:')) {
      scheme = 'template';
      queryString = queryString.substring(9);
    }

    // Pre-encode selectors
    queryString = _encodeSelectorPart(queryString);

    // Pre-encode transform values
    final transformRegex =
        RegExp(r'transform=((?:(?!&(?:filter|update|transform|regexp)=).)*)');
    queryString = queryString.replaceAllMapped(transformRegex, (match) {
      return 'transform=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode filter values
    final filterRegex =
        RegExp(r'filter=((?:(?!&(?:filter|update|transform|regexp)=).)*)');
    queryString = queryString.replaceAllMapped(filterRegex, (match) {
      return 'filter=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode update values
    final updateRegex =
        RegExp(r'update=((?:(?!&(?:filter|update|transform|regexp)=).)*)');
    queryString = queryString.replaceAllMapped(updateRegex, (match) {
      return 'update=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode regexp values
    final regexpRegex =
        RegExp(r'regexp=((?:(?!&(?:filter|update|transform|regexp)=).)*)');
    queryString = queryString.replaceAllMapped(regexpRegex, (match) {
      return 'regexp=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Pre-encode save values
    final saveRegex =
        RegExp(r'save=((?:(?!&(?:filter|update|transform|regexp|save)=).)*)');
    queryString = queryString.replaceAllMapped(saveRegex, (match) {
      return 'save=${Uri.encodeQueryComponent(match.group(1)!)}';
    });

    // Add dummy host if needed
    if (!queryString.contains('://')) {
      queryString = '$scheme://dummy/$queryString';
    }

    final uri = Uri.parse(queryString);
    var path = Uri.decodeFull(uri.path.replaceFirst('/dummy/', ''));
    if (path.startsWith('/') && (scheme == 'url' || scheme == 'template')) {
      path = path.substring(1);
    }

    final params = <String, List<String>>{};
    uri.queryParametersAll.forEach((key, values) {
      for (var value in values) {
        if (key == 'transform') {
          if (params.containsKey(key)) {
            params[key]!.addAll(_splitTransforms(value));
          } else {
            params[key] = _splitTransforms(value);
          }
        } else {
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
    if (params.containsKey('transform')) {
      transforms['transform'] = params['transform']!;
      params.remove('transform');
    }
    if (params.containsKey('regexp')) {
      final regexps = params['regexp']!.map((e) => 'regexp:$e').toList();
      if (transforms.containsKey('transform')) {
        transforms['transform']!.addAll(regexps);
      } else {
        transforms['transform'] = regexps;
      }
      params.remove('regexp');
    }
    if (params.containsKey('update')) {
      transforms['update'] = params['update']!;
      params.remove('update');
    }
    if (params.containsKey('filter')) {
      transforms['filter'] = params['filter']!;
      params.remove('filter');
    }
    if (params.containsKey('save')) {
      transforms['save'] = params['save']!;
      params.remove('save');
    }

    return QueryPart(scheme, path, params, transforms, required,
        isPipe: isPipe);
  }

  bool isRequired() {
    return required;
  }

  @override
  String toString() {
    return "QueryPart(scheme: $scheme, path: $path, parameters: $parameters, transforms: $transforms, required: $required, isPipe: $isPipe)";
  }
}
