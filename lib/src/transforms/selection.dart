import 'package:logging/logging.dart';
import 'package:web_query/src/resolver/common.dart';
import 'package:web_query/src/transforms/common.dart';
import 'package:web_query/src/transforms/selection_transforms.dart';

final _log = Logger("transformer.selection");

class FilterTransformer extends Transformer {
  final String _rawValue;

  final List<String> _filters = [];
  FilterTransformer(this._rawValue) {
    _filters.addAll(parseFilterPattern(_rawValue));
  }

  @override
  Map<String, dynamic> info() {
    return {
      "rawValue": _rawValue,
      "filters": _filters,
    };
  }

  @override
  TransformResult transform(dynamic value) {
    return TransformResult(result: applyFilterByList(value, _filters));
  }

  @override
  void resolve(Resolver resolver) {
    for (var i = 0; i < _filters.length; i++) {
      _filters[i] = resolver.resolve(_filters[i]);
    }
  }
}

class IndexTransformer extends Transformer {
  String _rawValue;

  IndexTransformer(this._rawValue);

  @override
  Map<String, dynamic> info() {
    return {
      "index": _rawValue,
    };
  }

  @override
  TransformResult transform(dynamic value) {
    _log.fine("apply index: $value, $_rawValue");
    return TransformResult(result: applyIndex(value, _rawValue));
  }

  @override
  void resolve(Resolver resolver) {
    _rawValue = resolver.resolve(_rawValue);
  }
}
