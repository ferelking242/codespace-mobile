// Conditional export: web gets redirect UI, native gets the WebView login.
export 'auth_screen_web.dart'
    if (dart.library.io) 'auth_screen_mobile.dart';
