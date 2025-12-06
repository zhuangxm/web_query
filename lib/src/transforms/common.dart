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

  TransformResult({
    this.result,
    this.changedVariables = const {},
  });
}

abstract class Transformer {
  Resolver? resolver;

  TransformResult transform(dynamic value);

  void resolve(Resolver resolver);

  Map<String, dynamic> info();

  @override
  String toString() {
    return info().toString();
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
        errorMessage = 'Invalid JSON format for function parameters';
      }
    } else {
      _params = null;
    }
  }

  @override
  Map<String, dynamic> info() {
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
    _log.fine("Transforming $value with $functionName");
    final result = functionResolver.resolve(value, params: {
      ..._params ?? {},
      FunctionResolver.functionNameKey: functionName
    });
    return TransformResult(result: result, changedVariables: {});
  }
}

class KeepTransformer extends Transformer {
  final String rawValue;
  KeepTransformer(this.rawValue);
  @override
  TransformResult transform(value) {
    return TransformResult(result: value, changedVariables: {});
  }

  @override
  void resolve(Resolver resolver) {
    // do nothing.
  }

  @override
  Map<String, dynamic> info() {
    return {
      "name": "keep",
    };
  }
}
