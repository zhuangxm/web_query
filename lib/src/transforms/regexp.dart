import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/common.dart';

final _log = Logger("RegExpTransformer");
({String pattern, String replacement, bool replaceMode})? parseRegexpPattern(
    String pattern) {
  // Decode pattern after splitting to preserve escaped slashes
  final parts =
      pattern.split(RegExp(r'(?<!\\)/')).where((e) => e.isNotEmpty).toList();

  if (parts.isEmpty) {
    return null;
  }

  // If only pattern provided, replacement is empty
  if (parts.length == 1) {
    parts.add("");
  }

  // Decode special characters in pattern
  String regexPattern = parts[0];
  String replacePattern = parts.length > 1 ? parts[1] : "";
  bool replaceMode = parts.length > 2 ? parts[2] != "s" : true;
  // Handle \ALL keyword - matches entire string including newlines
  if (regexPattern.contains(r'\ALL')) {
    regexPattern = regexPattern.replaceAll(r'\ALL', r'^[\s\S]*$');
  }

  // Decode escaped characters in replacement
  replacePattern = replacePattern.replaceAll(r'\/', '/').replaceAll(r'\;', ';');

  return (
    pattern: regexPattern,
    replacement: replacePattern,
    replaceMode: replaceMode
  );
}

class RegExpTransformer extends Transformer {
  final String name = 'regexp';
  final String rawValue;

  late String _pattern;
  late String _replaceMent;
  bool _replaceMode = true;
  String? errorMessage;

  RegExpTransformer(this.rawValue) {
    final parsed = parseRegexpPattern(rawValue);
    if (parsed == null) {
      throw const FormatException("regexp transform requires a pattern");
    }
    _pattern = parsed.pattern;
    _replaceMent = parsed.replacement;
    _replaceMode = parsed.replacement.isNotEmpty && parsed.replaceMode;
  }

  String _replaceResult(Match match) {
    var result = _replaceMent;
    for (var i = 1; i <= match.groupCount; i++) {
      result = result.replaceAll('\$$i', match.group(i) ?? '');
    }
    return result.replaceAll(r'$0', match.group(0) ?? '');
  }

  dynamic _transformInter(dynamic value) {
    try {
      final regexp = RegExp(_pattern, multiLine: true);
      final valueStr = value.toString();

      // Pattern-only mode (empty replacement part)
      if (!_replaceMode) {
        final match = regexp.firstMatch(valueStr);
        if (_replaceMent.isEmpty) {
          return match?.group(0);
        } else if (match != null) {
          return _replaceResult(match);
        } else {
          return null;
        }
      }

      // Replace mode
      return valueStr.replaceAllMapped(regexp, (Match match) {
        var result = _replaceMent;
        for (var i = 1; i <= match.groupCount; i++) {
          result = result.replaceAll('\$$i', match.group(i) ?? '');
        }
        return _replaceResult(match);
      });
    } catch (e) {
      _log.warning('Failed to apply regexp: $_pattern, error: $e');
      return value;
    }
  }

  @override
  ResultWithVariables transform(dynamic value) {
    _log.finer("Transforming $value with $this");
    if (value == null) return ResultWithVariables(result: null);
    return ResultWithVariables(result: _transformInter(value));
  }

  @override
  Map<String, dynamic> toJson() {
    if (errorMessage?.isNotEmpty == true) {
      return {
        'name': Transformer.paramRegexp,
        'raw': rawValue,
        'errorMessage': errorMessage,
      };
    }
    return {
      'name': Transformer.paramRegexp,
      'raw': rawValue,
      'pattern': _pattern,
      'replacement': _replaceMent,
      'replaceMode': _replaceMode,
    };
  }

  @override
  resolve(Resolver resolver) {
    _pattern = resolver.resolve(_pattern) as String;
    _replaceMent = resolver.resolve(_replaceMent) as String;
  }

  @override
  String get groupName => Transformer.paramTransform;
}
