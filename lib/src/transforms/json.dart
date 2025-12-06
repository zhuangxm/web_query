import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/data_transforms.dart';

final _log = Logger("transformer.json");

class JsonTransformer extends Transformer {
  String _rawValue;

  JsonTransformer(this._rawValue);

  @override
  Map<String, dynamic> info() {
    return {
      'name': 'json',
      'varible': _rawValue,
    };
  }

  @override
  void resolve(Resolver resolver) {
    _rawValue = resolver.resolve(_rawValue);
  }

  @override
  TransformResult transform(value) {
    _log.fine("transform $value to json");
    return TransformResult(result: applyJsonTransform(value, _rawValue));
  }
}
