import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/resolver/function.dart';

final _log = Logger("Transformer.common");

class TransformResult {
  dynamic result;
  Map<String, dynamic> changedVariables = const {};

  bool isValid() =>
      result != null && result != 'null' && result.toString().trim().isNotEmpty;

  @override
  String toString() {
    return 'TransformResult{result: $result, changedVariables: $changedVariables}';
  }

  TransformResult({
    this.result,
    this.changedVariables = const {},
  });
}

abstract class Transformer {
  // Parameter keyword constants
  static const String paramTransform = 'transform';
  static const String paramFilter = 'filter';
  static const String paramUpdate = 'update';
  static const String paramRegexp = 'regexp';
  static const String paramSave = 'save';
  static const String paramKeep = 'keep';
  static const String paramIndex = 'index';

  static const validTransformNames = [
    Transformer.paramRegexp,
    Transformer.paramTransform,
    Transformer.paramUpdate,
    Transformer.paramFilter,
    Transformer.paramIndex,
    Transformer.paramSave,
    Transformer.paramKeep,
  ];

  Resolver? resolver;

  TransformResult transform(dynamic value);

  static TransformResult transformMultiple(
      List<Transformer> transformers, value) {
    return transformers.fold(TransformResult(result: value),
        (prevResult, transform) {
      final nv = transform.transform(prevResult.result);
      return TransformResult(result: nv.result, changedVariables: {
        ...prevResult.changedVariables,
        ...nv.changedVariables
      });
    });
  }

  void resolve(Resolver resolver);

  Map<String, dynamic> toJson();

  String get groupName;

  @override
  String toString() {
    return toJson().toString();
  }
}

class SimpleFunctionTransformer extends Transformer {
  final String functionName;
  final String rawValue;
  late Map<String, dynamic>? _params;
  final FunctionResolver functionResolver;
  String? errorMessage;

  SimpleFunctionTransformer(
      {required this.functionName,
      required this.functionResolver,
      this.rawValue = ""}) {
    if (!functionResolver.hasFunction(functionName)) {
      throw ArgumentError.value(
          functionName, 'functionName', 'Unknown function name');
    } else if (rawValue.isNotEmpty) {
      try {
        _params = jsonDecode(rawValue);
      } on FormatException {
        _log.warning(
            'Invalid JSON format for function parameters. Function: $functionName, Raw Value: $rawValue');
        _params = null;
        errorMessage = 'Invalid JSON format for function parameters.';
      }
    } else {
      _params = null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    if (errorMessage?.isNotEmpty == true) {
      return {
        "name": functionName,
        "raw_value": rawValue,
        "params": _params,
        "error_message": errorMessage,
      };
    }
    return {
      "name": functionName,
      "raw_value": rawValue,
      "params": _params,
    };
  }

  @override
  void resolve(Resolver resolver) {
    //resolver.resolve(rawValue);
  }

  @override
  TransformResult transform(value) {
    _log.finer("Transforming $value with $functionName");
    final result = functionResolver.resolve(value, params: {
      ..._params ?? {},
      FunctionResolver.functionNameKey: functionName
    });
    return TransformResult(result: result, changedVariables: {});
  }

  @override
  String get groupName => Transformer.paramTransform;
}

class KeepTransformer extends Transformer {
  final bool keep;
  final String rawString;
  KeepTransformer(this.rawString) : keep = rawString != 'false';
  @override
  TransformResult transform(value) {
    _log.fine("keep $keep, value: $value");
    if (!keep) {
      return TransformResult(result: null, changedVariables: {});
    }
    return TransformResult(result: value, changedVariables: {});
  }

  @override
  void resolve(Resolver resolver) {
    // do nothing.
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "name": "keep",
      "rawValue": rawString,
      "keep": keep,
    };
  }

  @override
  String get groupName => Transformer.paramKeep;
}
