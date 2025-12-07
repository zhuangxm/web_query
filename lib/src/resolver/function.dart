import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/data_transforms.dart';
import 'package:web_query/src/transforms/functions.dart';

final _log = Logger("FunctionResolver");

typedef TransformFunction = dynamic Function(dynamic value);
typedef CreateTransformFunction = TransformFunction Function(
    Map<String, dynamic> params);

Map<String, CreateTransformFunction> _buildinFunctions = {
  "upper": (params) => (v) => toUpperCase(v),
  "lower": (params) => (v) => toLowerCase(v),
  "md5": (params) => (v) => md5Hash(v),
  "base64": (params) => (v) => base64Encode(v),
  "base64decode": (params) => (v) => base64Decode(v),
  "reverse": (params) => (v) => reverseString(v),
  "sha1": (params) => (v) => sha1Hash(v),
  "update": (params) => (v) => applyUpdateJson(v, params),
};

class FunctionResolver implements Resolver {
  final Map<String, CreateTransformFunction> functions;

  FunctionResolver(this.functions);

  static Map<String, CreateTransformFunction> defaultFunctions = {};

  static const String functionNameKey = "function_name";

  bool hasFunction(String functionName) {
    return functions.containsKey(functionName);
  }

  getCreateFunction(String functionName) {
    return functions[functionName] ??
        defaultFunctions[functionName] ??
        _buildinFunctions[functionName];
  }

  @override
  dynamic resolve(dynamic value, {Map<String, dynamic>? params}) {
    if (params == null) {
      return value;
    }

    final String? functionName = params[functionNameKey] as String?;
    if (functionName == null || functionName.isEmpty) {
      _log.warning('Function name is null');
      return value;
    } else {
      final CreateTransformFunction? createTransformFunction =
          getCreateFunction(functionName);
      if (createTransformFunction == null) {
        _log.warning('Function $functionName is not defined');
        return value;
      }
      final TransformFunction transformFunction =
          createTransformFunction(params);
      return transformFunction(value);
    }
  }
}
