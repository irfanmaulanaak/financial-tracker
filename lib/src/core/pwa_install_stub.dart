/// Native / non-web stub. PWA install only exists on the web platform.
class PwaInstall {
  static bool get canPrompt => false;
  static bool get needsIosInstructions => false;
  static Future<bool> prompt() async => false;
}
