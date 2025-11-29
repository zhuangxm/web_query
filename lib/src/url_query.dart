import 'page_data.dart';
import 'query_part.dart';
import 'query_result.dart';

QueryResult applyUrlPathFor(PageNode node, QueryPart query) {
  var url = node.pageData.url;

  // Apply modifications from parameters
  if (query.parameters.isNotEmpty) {
    url = modifyUrl(url, query.parameters);
  }

  if (query.path.isEmpty) {
    return QueryResult(url);
  }

  final uri = Uri.parse(url);

  if (query.path == 'scheme') return QueryResult(uri.scheme);
  if (query.path == 'host') return QueryResult(uri.host);
  if (query.path == 'port') return QueryResult(uri.port.toString());
  if (query.path == 'path') return QueryResult(uri.path);
  if (query.path == 'query') return QueryResult(uri.query);
  if (query.path == 'fragment') return QueryResult(uri.fragment);
  if (query.path == 'userInfo') return QueryResult(uri.userInfo);
  if (query.path == 'origin') return QueryResult(uri.origin);

  if (query.path == 'queryParameters') return QueryResult(uri.queryParameters);

  if (query.path.startsWith('queryParameters/')) {
    final key = query.path.substring('queryParameters/'.length);
    return QueryResult(uri.queryParameters[key]);
  }

  return QueryResult(null);
}

String modifyUrl(String url, Map<String, List<String>> parameters) {
  var uri = Uri.parse(url);
  var newQueryParameters =
      Map<String, List<String>>.from(uri.queryParametersAll);

  String? newScheme;
  String? newHost;
  int? newPort;
  String? newPath;
  String? newFragment;
  String? newUserInfo;

  parameters.forEach((key, values) {
    final value = values.isNotEmpty ? values.last : '';

    if (key == '_scheme') {
      newScheme = value;
    } else if (key == '_host') {
      newHost = value;
    } else if (key == '_port') {
      newPort = int.tryParse(value);
    } else if (key == '_path') {
      newPath = value;
    } else if (key == '_fragment') {
      newFragment = value;
    } else if (key == '_userInfo') {
      newUserInfo = value;
    } else if (key == '_remove') {
      // Handle removal
      for (var v in values) {
        for (var k in v.split(',')) {
          newQueryParameters.remove(k.trim());
        }
      }
    } else {
      // Treat as query parameter update
      newQueryParameters[key] = values;
    }
  });

  return uri
      .replace(
        scheme: newScheme,
        host: newHost,
        port: newPort,
        path: newPath,
        fragment: newFragment,
        userInfo: newUserInfo,
        queryParameters: newQueryParameters.isEmpty ? null : newQueryParameters,
      )
      .toString();
}
