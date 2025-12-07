import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/resolver/function.dart';

final _log = Logger("Transformer.common");

class ResultWithVariables {
  dynamic result;
  Map<String, dynamic> variables = const {};

  bool isValid() =>
      result != null && result != 'null' && result.toString().trim().isNotEmpty;

  @override
  String toString() {
    return 'TransformResult{result: $result, changedVariables: $variables}';
  }

  ResultWithVariables({
    this.result,
    this.variables = const {},
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

  ResultWithVariables transform(dynamic value);

  static ResultWithVariables transformMultiple(
      List<Transformer> transformers, value) {
    return transformers.fold(ResultWithVariables(result: value),
        (prevResult, transform) {
      final nv = transform.transform(prevResult.result);
      return ResultWithVariables(
          result: nv.result,
          variables: {...prevResult.variables, ...nv.variables});
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
      throw FormatException('Unknown transform: "$functionName"');
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
  ResultWithVariables transform(value) {
    _log.finer("Transforming $value with $functionName");
    final result = functionResolver.resolve(value, params: {
      ..._params ?? {},
      FunctionResolver.functionNameKey: functionName
    });
    return ResultWithVariables(result: result, variables: {});
  }

  @override
  String get groupName => Transformer.paramTransform;
}

class KeepTransformer extends Transformer {
  final bool keep;
  final String rawString;
  KeepTransformer(this.rawString) : keep = rawString != 'false';
  @override
  ResultWithVariables transform(value) {
    _log.fine("keep $keep, value: $value");
    if (!keep) {
      return ResultWithVariables(result: null, variables: {});
    }
    return ResultWithVariables(result: value, variables: {});
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
