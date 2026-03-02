import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/pattern_transforms.dart'
    show parseRegexpPattern;

final _log = Logger("RegExpTransformer");

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
    _replaceMode = parsed.hasReplacement;
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
        return _replaceResult(match);
      });
    } catch (e) {
      _log.warning('Failed to apply regexp: $_pattern, error: $e');
      return value;
    }
  }

  @override
  ResultWithVariables realTransform(dynamic value) {
    //_log.finer("Transforming $value with $this");
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

  @override
  bool get mapList => true;
}
