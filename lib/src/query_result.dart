extension SplitKeepSeparator on String {
  List<String> splitKeep(Pattern pattern) {
    if (isEmpty) return [];

    final result = <String>[];
    var start = 0;

    for (var match in pattern.allMatches(this)) {
      if (start != match.start) {
        result.add(substring(start, match.start));
      }
      result.add(substring(match.start, match.end));
      start = match.end;
    }

    if (start < length) {
      result.add(substring(start));
    }

    return result;
  }
}

//result of query, the result is list, it will not be confused with the list of result
class QueryResult {
  final List data;

  QueryResult(input)
      : data = input is List
            ? input
            : input == null
                ? []
                : [input];

  QueryResult combine(QueryResult other) {
    return QueryResult([...data, ...other.data]);
  }

  @override
  String toString() => "QueryResult($data)";
}

class QueryResultWithVariables {
  final QueryResult queryResult;
  final Map<String, dynamic> variables;

  QueryResultWithVariables(this.queryResult, this.variables);
}
