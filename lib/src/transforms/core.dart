import 'package:logging/logging.dart';
import 'package:web_query/src/query_part.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/resolver/function.dart';
import 'package:web_query/src/resolver/variable.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/data_transforms.dart';
import 'package:web_query/src/transforms/functions.dart';
import 'package:web_query/src/transforms/javascript.dart';
import 'package:web_query/src/transforms/json.dart';
import 'package:web_query/src/transforms/regexp.dart';
import 'package:web_query/src/transforms/selection.dart';

final _log = Logger("transformer.core");

class ChainResolver extends Resolver {
  final List<Resolver> resolvers;

  ChainResolver({required this.resolvers});
  @override
  resolve(value, {Map<String, dynamic>? params}) {
    var result = value;
    for (final resolver in resolvers) {
      result = resolver.resolve(result, params: params);
    }
    return result;
  }
}

Map<String, CreateTransFormFunction> defaultFunctions = {
  "upper": (params) => (v) => toUpperCase(v),
  "lower": (params) => (v) => toLowerCase(v),
  "md5": (params) => (v) => md5Hash(v),
  "base64": (params) => (v) => base64Encode(v.codeUnits),
  "base64Decode": (params) => (v) => base64Decode(v),
  "reverse": (params) => (v) => reverseString(v),
  "sha1": (params) => (v) => sha1Hash(v),
  "update": (params) => (v) => applyUpdateJson(v, params),
};

Resolver createDefaultResolver({
  Map<String, dynamic> variables = const {},
  Map<String, CreateTransFormFunction> functions = const {},
}) {
  return ChainResolver(resolvers: [
    VariableResolver(variables),
    FunctionResolver({...defaultFunctions, ...functions})
  ]);
}

class GroupTransformer extends Transformer {
  final List<Transformer> _transformers;

  List<Transformer> get transformers => _transformers;
  final bool mapList;
  GroupTransformer(this._transformers, {this.mapList = false});

  addTransform(Transformer transform) {
    _transformers.add(transform);
  }

  addTransforms(Iterable<Transformer> transforms) {
    _transformers.addAll(transforms);
  }

  TransformResult transformSingle(value) {
    return transformers.fold(TransformResult(result: value),
        (prevResult, transform) {
      final nv = transform.transform(prevResult.result);
      return TransformResult(result: nv.result, changedVariables: {
        ...prevResult.changedVariables,
        ...nv.changedVariables
      });
    });
  }

  @override
  TransformResult transform(value) {
    _log.fine("group transfer $value");
    _log.fine("group transfers $_transformers");
    if (value is List && mapList) {
      if (mapList) {
        final results = value.map((v) => transformSingle(v));
        return TransformResult(
            result:
                results.where((v) => v.isValid()).map((v) => v.result).toList(),
            changedVariables: results
                .map((v) => v.changedVariables)
                .toList()
                .fold({}, (prev, next) => {...prev, ...next}));
      } else {
        return transformSingle(value);
      }
    } else {
      return transformSingle(value);
    }
  }

  @override
  Map<String, dynamic> info() {
    return {"name": "group", "transformers": _transformers, "mapList": mapList};
  }

  @override
  void resolve(Resolver resolver) {
    for (final transformer in _transformers) {
      transformer.resolve(resolver);
    }
  }
}

class SaveTransformer extends Transformer {
  final String varName;
  SaveTransformer(this.varName) {
    if (varName.isEmpty) {
      throw Exception(
        "SaveTransformer: varName cannot be empty",
      );
    }
  }

  @override
  TransformResult transform(value) {
    _log.fine("save transform $value to $varName");
    return TransformResult(result: value, changedVariables: {varName: value});
  }

  @override
  Map<String, dynamic> info() {
    return {
      "name": "save",
      "variable": varName,
    };
  }

  @override
  void resolve(Resolver resolver) {
    // do nothing.
  }
}

Transformer createTransform(String rawValue) {
  _log.fine("create transform: $rawValue");
  final parts = rawValue.split(':');
  return createTransformWithName(parts[0], parts.length > 1 ? parts[1] : "");
}

Transformer createTransformWithName(String name, String rawValue) {
  _log.fine("create transform name: $name rawValue: $rawValue");
  switch (name) {
    case QueryPart.paramRegexp:
      return RegExpTransformer(rawValue);
    case 'jseval':
      return JavascriptTransformer(rawValue);
    case 'json':
      return JsonTransformer(rawValue);
    case QueryPart.paramTransform:
      return GroupTransformer([]);
    case QueryPart.paramFilter:
      return FilterTransformer(rawValue);
    case QueryPart.paramIndex:
      return IndexTransformer(rawValue);
    case QueryPart.paramUpdate:
      return SimpleFunctionTransformer(
          functionName: 'update',
          functionResolver: FunctionResolver(defaultFunctions),
          rawValue: rawValue);
    case QueryPart.paramSave:
      return SaveTransformer(rawValue);
    case QueryPart.paramKeep:
      return KeepTransformer(rawValue);
    default:
      return SimpleFunctionTransformer(
          functionName: name,
          functionResolver: FunctionResolver(defaultFunctions),
          rawValue: rawValue);
    //throw ArgumentError.value(name, 'name', 'Unknown transform name');
  }
}
