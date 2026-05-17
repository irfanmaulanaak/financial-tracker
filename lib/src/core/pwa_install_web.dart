import 'dart:js_interop';

/// Mirrors `window.ftPwa` defined in `web/index.html`.
@JS('ftPwa')
external _FtPwa get _ftPwa;

@JS()
@staticInterop
class _FtPwa {}

extension _FtPwaApi on _FtPwa {
  external bool canPrompt();
  external bool needsIosInstructions();
  external JSPromise<JSBoolean> prompt();
}

/// Web impl. All methods are safe to call even if the bridge somehow
/// failed to inject (treats it as "not installable").
class PwaInstall {
  static bool get canPrompt {
    try {
      return _ftPwa.canPrompt();
    } catch (_) {
      return false;
    }
  }

  static bool get needsIosInstructions {
    try {
      return _ftPwa.needsIosInstructions();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> prompt() async {
    try {
      final result = await _ftPwa.prompt().toDart;
      return result.toDart;
    } catch (_) {
      return false;
    }
  }
}
