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

/// Short first-name form of [prettyName] — use wherever space is tight
/// (header, chips, activity rows, card owner). Full names ("Irfan Maulana
/// Akbar") go through Profile/Members; everywhere else should call this
/// instead of repeating `prettyName(x).split(' ').first` ad hoc.
String shortName(String raw) =>
    prettyName(raw).split(RegExp(r'\s+')).first;
