// PWA install bridge. Captures `beforeinstallprompt` before Flutter boots and
// exposes a tiny API for Dart to read state + trigger the install dialog.
// Extracted from index.html for CSP (script-src 'self') — see SEC-006.
(function () {
  var deferred = null;
  var installed = false;
  function isStandalone() {
    return (window.matchMedia &&
            window.matchMedia('(display-mode: standalone)').matches) ||
           window.navigator.standalone === true;
  }
  function isIOS() {
    var ua = window.navigator.userAgent || '';
    return /iPad|iPhone|iPod/.test(ua) && !window.MSStream;
  }
  window.addEventListener('beforeinstallprompt', function (e) {
    e.preventDefault();
    deferred = e;
  });
  window.addEventListener('appinstalled', function () {
    installed = true;
    deferred = null;
  });
  window.ftPwa = {
    canPrompt: function () { return !!deferred && !isStandalone() && !installed; },
    needsIosInstructions: function () { return isIOS() && !isStandalone() && !installed; },
    isStandalone: isStandalone,
    prompt: function () {
      if (!deferred) return Promise.resolve(false);
      var d = deferred;
      deferred = null;
      d.prompt();
      return d.userChoice.then(function (c) { return c.outcome === 'accepted'; });
    }
  };
})();
