/// Returns a human-friendly display name. Strips the `@domain.com` portion if
/// the input looks like a bare email — so a member who joined via email link
/// without setting a name shows as "john" instead of "john@gmail.com".
///
/// Capitalises the first letter so the output reads cleanly in lists / chips.
String prettyName(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return 'Anggota';
  final at = s.indexOf('@');
  final base = at > 0 ? s.substring(0, at) : s;
  if (base.isEmpty) return 'Anggota';
  return base[0].toUpperCase() + base.substring(1);
}
