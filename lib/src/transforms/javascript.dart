import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms.dart';
import 'package:web_query/src/transforms/common.dart';

class JavascriptTransformer extends Transformer {
  String _rawValue;

  late List<String> _variables = [];
  JavascriptTransformer(this._rawValue) {
    _variables = _rawValue.split(',');
  }

  @override
  Map<String, dynamic> info() {
    return {
      'name': 'jseval',
      'rawValue': _rawValue,
      'variables': _variables,
    };
  }

  @override
  void resolve(Resolver resolver) {
    _rawValue = resolver.resolve(_rawValue);
  }

  @override
  TransformResult transform(value) {
    return TransformResult(result: applyJsEvalTransform(value, _rawValue));
  }
}
