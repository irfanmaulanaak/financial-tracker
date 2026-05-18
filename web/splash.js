// Removes the static splash <picture> + branding nodes once Flutter is ready
// to take over. Extracted from index.html for CSP (script-src 'self') — see
// SEC-006.
function removeSplashFromWeb() {
  document.getElementById("splash")?.remove();
  document.getElementById("splash-branding")?.remove();
  document.body.style.background = "transparent";
}
