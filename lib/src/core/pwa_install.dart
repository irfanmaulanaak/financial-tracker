/// PWA-install bridge. On native, every getter returns false / no-op.
/// On web, talks to `window.ftPwa` injected in `web/index.html`.
///
/// Why split: `dart:js_interop` `external` symbols don't link on Dart VM,
/// so we conditional-import the real impl only when targeting JS.
library;

export 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart';
