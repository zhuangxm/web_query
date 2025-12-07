import 'package:logging/logging.dart';
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

const transformOrder = [
  Transformer.paramTransform,
  Transformer.paramUpdate,
  Transformer.paramFilter,
  Transformer.paramIndex,
  Transformer.paramSave,
  Transformer.paramKeep
];

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
  final bool enableMulti;
  GroupTransformer(this._transformers,
      {this.mapList = true, this.enableMulti = true});

  addTransform(Transformer transform) {
    if (enableMulti) {
      _transformers.add(transform);
    } else {
      _transformers.clear();
      _transformers.add(transform);
    }
  }

  addTransforms(Iterable<Transformer> transforms) {
    for (var transform in transforms) {
      addTransform(transform);
    }
  }

  @override
  TransformResult transform(value) {
    // _log.fine("group transfer $value");
    // _log.fine("group transfers $_transformers");
    if (value is List && mapList) {
      final results =
          value.map((v) => Transformer.transformMultiple(transformers, v));
      return TransformResult(
          result:
              results.where((v) => v.isValid()).map((v) => v.result).toList(),
          changedVariables: results
              .map((v) => v.changedVariables)
              .toList()
              .fold({}, (prev, next) => {...prev, ...next}));
    } else {
      return Transformer.transformMultiple(transformers, value);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    if (_transformers.isEmpty) {
      return {};
    } else if (_transformers.length == 1) {
      return {
        "mapList": mapList,
        "transformer": _transformers.first.toJson(),
      };
    }
    return {
      "mapList": mapList,
      "transformers": _transformers.map((e) => e.toJson()).toList(),
    };
  }

  @override
  void resolve(Resolver resolver) {
    for (final transformer in _transformers) {
      transformer.resolve(resolver);
    }
  }

  //should never be called
  @override
  String get groupName => throw UnimplementedError();
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
    _log.fine("save $value to $varName");
    return TransformResult(result: value, changedVariables: {varName: value});
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "name": "save",
      "variable": varName,
    };
  }

  @override
  void resolve(Resolver resolver) {
    // do nothing.
  }

  @override
  String get groupName => Transformer.paramSave;
}

List<Transformer> createTransform(String rawValue) {
  //_log.fine("create transform: $rawValue");
  final parts = rawValue.split(':');
  return createTransformsWithName(parts[0], parts.skip(1).join(':'));
}

List<Transformer> createTransformsWithName(String name, String rawValue) {
  //_log.fine("create transform name: $name rawValue: $rawValue");
  switch (name) {
    case Transformer.paramRegexp:
      return [RegExpTransformer(rawValue)];
    case 'jseval':
      return [JavascriptTransformer(rawValue)];
    case 'json':
      return [JsonTransformer(rawValue)];
    case Transformer.paramTransform:
      return createTransform(rawValue);
    case Transformer.paramFilter:
      return [FilterTransformer(rawValue)];
    case Transformer.paramIndex:
      return [IndexTransformer(rawValue)];
    case Transformer.paramUpdate:
      return [
        SimpleFunctionTransformer(
            functionName: 'update',
            functionResolver: FunctionResolver(defaultFunctions),
            rawValue: rawValue)
      ];
    case Transformer.paramSave:
      return [SaveTransformer(rawValue), KeepTransformer('false')];
    case Transformer.paramKeep:
      return [KeepTransformer(rawValue)];
    default:
      return [
        SimpleFunctionTransformer(
            functionName: name,
            functionResolver: FunctionResolver(defaultFunctions),
            rawValue: rawValue)
      ];
    //throw ArgumentError.value(name, 'name', 'Unknown transform name');
  }
}
