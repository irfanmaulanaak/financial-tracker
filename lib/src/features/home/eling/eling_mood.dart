/// Eling's mood — picked from the household's state with the priority order
/// in DESIGN.md section 6. Pure and deterministic so it can be unit-tested.
library;

enum ElingMood { bobo, ngirit, hore, senang }

/// Returns Eling's mood. Rules are checked in order; the first that applies
/// wins (DESIGN.md section 6):
///   1. Bobo   — 21:00 to 04:59 local time.
///   2. Ngirit — has a budget and the money left today is low:
///               `remaining <= 0`, or `perDay * cycleLength < 0.5 * monthlyBudget`.
///   3. Hore   — nothing was spent yesterday.
///   4. Senang — everything else.
ElingMood elingMood({
  required DateTime now,
  required bool hasBudget,
  required int remaining,
  required int perDay,
  required int cycleLength,
  required int monthlyBudget,
  required bool noSpendYesterday,
}) {
  final hour = now.hour;
  if (hour >= 21 || hour < 5) return ElingMood.bobo;

  if (hasBudget &&
      (remaining <= 0 || perDay * cycleLength < monthlyBudget * 0.5)) {
    return ElingMood.ngirit;
  }

  if (noSpendYesterday) return ElingMood.hore;

  return ElingMood.senang;
}

/// Default speech-bubble line for each mood (used when there is no locked
/// daily insight). DESIGN.md section 6.
String elingLine(ElingMood mood) => switch (mood) {
      ElingMood.senang => 'Hari ini masih aman.',
      ElingMood.ngirit => 'Pelan-pelan dulu ya, sisa anggaran tinggal sedikit.',
      ElingMood.bobo => 'Selamat istirahat. Besok kita cek lagi.',
      ElingMood.hore => 'Kemarin nggak ada jajan. Mantap!',
    };
