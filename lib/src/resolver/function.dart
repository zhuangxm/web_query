import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/data_transforms.dart';
import 'package:web_query/src/transforms/functions.dart';
import 'package:web_query/src/transforms/selection_transforms.dart';

final _log = Logger("FunctionResolver");

typedef TransformFunction = dynamic Function(dynamic value);
typedef CreateTransformFunction = TransformFunction Function(
    Map<String, dynamic> params);

class FunctionDefinition {
  final bool mapList;
  final CreateTransformFunction createFunction;

  FunctionDefinition(this.mapList, this.createFunction);
}

Map<String, FunctionDefinition> _buildInFunctions = {
  "upper": FunctionDefinition(true, (params) => (v) => toUpperCase(v)),
  "lower": FunctionDefinition(true, (params) => (v) => toLowerCase(v)),
  "md5": FunctionDefinition(true, (params) => (v) => md5Hash(v)),
  "base64": FunctionDefinition(true, (params) => (v) => base64Encode(v)),
  "base64decode": FunctionDefinition(true, (params) => (v) => base64Decode(v)),
  "reverse": FunctionDefinition(true, (params) => (v) => reverse(v)),
  "sha1": FunctionDefinition(true, (params) => (v) => sha1Hash(v)),
  "update":
      FunctionDefinition(true, (params) => (v) => applyUpdateJson(v, params)),
  "unique": FunctionDefinition(false, (params) => (v) => applyUnique(v)),
  "sort": FunctionDefinition(false, (params) => (v) => applySort(v)),
  "distinct": FunctionDefinition(false, (params) => (v) => applyUnique(v)),
  "join": FunctionDefinition(
      false, (params) => (v) => (v as List).join(params["separator"])),
};

class FunctionResolver implements Resolver {
  final Map<String, FunctionDefinition> functions;

  FunctionResolver(this.functions);

  static Map<String, FunctionDefinition> defaultFunctions = {};

  static const String functionNameKey = "function_name";

  bool hasFunction(String functionName) {
    return getCreateFunction(functionName) != null;
  }

  static String getAllFunctionName() {
    return {..._buildInFunctions, ...defaultFunctions}.keys.join("|");
  }

  FunctionDefinition? getCreateFunction(String functionName) {
    return functions[functionName] ??
        defaultFunctions[functionName] ??
        _buildInFunctions[functionName];
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
      final FunctionDefinition? functionDefinition =
          getCreateFunction(functionName);
      if (functionDefinition == null) {
        _log.warning('Function $functionName is not defined');
        return value;
      }
      final TransformFunction transformFunction =
          functionDefinition.createFunction(params);
      return transformFunction(value);
    }
  }
}
