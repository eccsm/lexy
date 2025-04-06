import 'dart:js_interop';

@JS('navigator')
external Navigator get jsNavigator;

@JS()
@staticInterop
class Navigator {}

extension NavigatorExtension on Navigator {
  external String get userAgent;
}

String getUserAgent() {
  return jsNavigator.userAgent;
}
