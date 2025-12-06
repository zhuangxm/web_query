import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';

final _log = Logger("FunctionResolver");

typedef TransformFunction = dynamic Function(dynamic value);
typedef CreateTransFormFunction = TransformFunction Function(
    Map<String, dynamic> params);

class FunctionResolver implements Resolver {
  final Map<String, CreateTransFormFunction> functions;

  FunctionResolver(this.functions);

  static const String functionNameKey = "function_name";

  bool hasFunction(String functionName) {
    return functions.containsKey(functionName);
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
      final CreateTransFormFunction? createTransformFunction =
          functions[functionName];
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
