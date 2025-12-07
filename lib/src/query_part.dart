import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/core.dart';

// ignore: unused_element
final _log = Logger("QueryPart");

class QueryPart {
  // Scheme constants for query types
  static const String schemeHtml = 'html';
  static const String schemeJson = 'json';
  static const String schemeUrl = 'url';
  static const String schemeTemplate = 'template';

  static const String reservedPattern =
      "(?:${Transformer.paramFilter}|${Transformer.paramUpdate}|${Transformer.paramTransform}|${Transformer.paramRegexp}|${Transformer.paramSave}|${Transformer.paramKeep}|${Transformer.paramIndex})";

  final String scheme;
  String _path;
  String get path => _path;
  final Map<String, List<String>> parameters;
  final Map<String, GroupTransformer> transforms;
  final bool required;
  final bool isPipe;

  QueryPart(
      this.scheme, this._path, this.parameters, this.transforms, this.required,
      {this.isPipe = false});

  void resolve(Resolver resolver) {
    //_log.fine("resolve path: $_path, $resolver query ${toString()}");
    _path = resolver.resolve(_path);
    parameters.forEach((key, values) {
      for (var v in values) {
        values[values.indexOf(v)] = resolver.resolve(v);
      }
    });
    transforms.forEach((key, value) {
      value.resolve(resolver);
    });
  }

  static replaceSpecialCharacter(String part) {
    return part
        .replaceAll('#', '%23')
        .replaceAll("?", "%3F")
        .replaceAll(r"\", "%5C");
  }

  static String _encodeSelectorPart(String part) {
    // Encode specialCharacter in selectors but preserve in query params
    final queryPattern = RegExp(r'(?<!\\)\?');
    if (part.contains(queryPattern)) {
      final index = part.indexOf(queryPattern);
      final firstPart = part.substring(0, index);
      final secondPart = part.substring(index + 1);
      return '${replaceSpecialCharacter(firstPart)}?$secondPart';
    }
    return replaceSpecialCharacter(part);
  }

  static List<String> _splitTransforms(String value) {
    // Split on semicolons that are followed by known transform keywords
    // This allows regexp patterns with semicolons to stay intact
    // Example: "upper;regexp:/a;b/c/;lower" -> ["upper", "regexp:/a;b/c/", "lower"]

    // Known transform keywords that can follow a semicolon
    final transformKeywords =
        '(?:json|jseval|regexp|${FunctionResolver.getAllFunctionName()})';

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
    const notLookAheadKeyWords = '(?!&$reservedPattern(?:=|&|\$))';
    const notLookAt = '(?:$notLookAheadKeyWords.)';

    // Helper to encode a parameter value
    void encodeParam(String paramName) {
      final regex = RegExp('$paramName=($notLookAt*)');
      queryString = queryString.replaceAllMapped(regex, (match) {
        return '$paramName=${Uri.encodeQueryComponent(match.group(1)!)}';
      });
    }

    // Pre-encode all reserved parameters
    encodeParam(Transformer.paramTransform);
    encodeParam(Transformer.paramFilter);
    encodeParam(Transformer.paramUpdate);
    encodeParam(Transformer.paramRegexp);
    encodeParam(Transformer.paramIndex);

    // Save and keep use simpler pattern (stop at & or end)
    for (var param in [Transformer.paramSave, Transformer.paramKeep]) {
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
        final parts = key == Transformer.paramTransform
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
  static Map<String, GroupTransformer> _moveParamsToTransforms(
      Map<String, List<String>> params,
      {bool throwException = true}) {
    final transforms = <String, GroupTransformer>{
      Transformer.paramTransform: GroupTransformer([], mapList: true),
      Transformer.paramUpdate: GroupTransformer([], mapList: true),
      Transformer.paramFilter: GroupTransformer([], mapList: true),
      Transformer.paramIndex:
          GroupTransformer([], mapList: false, enableMulti: false),
      Transformer.paramSave:
          GroupTransformer([], mapList: true, enableMulti: false),
      Transformer.paramKeep:
          GroupTransformer([], mapList: false, enableMulti: false),
    };

    // Move other transform-related parameters
    for (var paramEntry in params.entries) {
      final param = paramEntry.key;
      if (!Transformer.validTransformNames.contains(param)) {
        if (throwException) {
          throw FormatException(
              'Unknown query parameter: "$param". Did you mean one of: ${Transformer.validTransformNames.join(', ')}?');
        } else {
          continue;
        }
      }

      final transformsCreated = paramEntry.value
          .map((e) => createTransformsWithName(param, e))
          .expand((e) => e)
          .toList();

      for (var transformer in transformsCreated) {
        //_log.fine("add $transformer to ${transformer.groupName}");
        transforms[transformer.groupName]!.addTransform(transformer);
      }
    }

    //_log.fine("transforms: $transforms");
    transforms.removeWhere((key, value) => value.transformers.isEmpty);
    //_log.fine("transforms: $transforms");

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
    final transforms =
        _moveParamsToTransforms(params, throwException: scheme != schemeUrl);

    return QueryPart(scheme, path, params, transforms, required,
        isPipe: isPipe);
  }

  bool isRequired() {
    return required;
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Scheme: $scheme');
    buffer.writeln('Path: $path');
    final flags = <String>[];
    if (required) flags.add('required');
    if (isPipe) flags.add('pipe');

    if (flags.isNotEmpty) {
      buffer.writeln('Flags: ${flags.join(", ")}');
    }

    if (parameters.isNotEmpty) {
      buffer.writeln('  Parameters:');
      parameters.forEach((key, values) {
        buffer.writeln('    $key: ${values.join(", ")}');
      });
    }

    if (transforms.isNotEmpty) {
      buffer.writeln('Transforms:');
      for (var key in transformOrder) {
        if (transforms.containsKey(key)) {
          buffer.writeln('  ${jsonEncode(transforms[key]!.toJson())}');
        }
      }
    }

    return buffer.toString().trim();
  }
}
