import 'dart:html' as html;

void removeQueryParamFromUrl(String param) {
  final uri = html.window.location.href;
  final parsed = Uri.parse(uri);
  final queryParams = Map<String, String>.from(parsed.queryParameters);
  queryParams.remove(param);
  final newQuery = queryParams.isEmpty
      ? ''
      : '?${Uri(queryParameters: queryParams).query}';
  final newUrl =
      '${parsed.scheme}://${parsed.host}:${parsed.port}${parsed.path}$newQuery';
  html.window.history.replaceState({}, '', newUrl);
}

void cleanAuthUrlParams() {
  final uri = html.window.location.href;
  final parsed = Uri.parse(uri);

  final authParams = [
    'code',
    'error',
    'error_description',
    'error_code',
    'type'
  ];
  final queryParams = Map<String, String>.from(parsed.queryParameters);
  queryParams.removeWhere((k, _) => authParams.contains(k));

  final newQuery = queryParams.isEmpty
      ? ''
      : '?${Uri(queryParameters: queryParams).query}';

  final newUrl =
      '${parsed.scheme}://${parsed.host}:${parsed.port}${parsed.path}$newQuery';
  html.window.history.replaceState({}, '', newUrl);
}
