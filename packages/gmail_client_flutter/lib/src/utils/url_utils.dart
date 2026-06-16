import 'url_utils_stub.dart' if (dart.library.html) 'url_utils_web.dart' as impl;

void removeQueryParamFromUrl(String param) =>
    impl.removeQueryParamFromUrl(param);

void cleanAuthUrlParams() => impl.cleanAuthUrlParams();
