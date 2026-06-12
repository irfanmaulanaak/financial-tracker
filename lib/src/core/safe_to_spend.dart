/// "Aman dibelanjakan": sisa anggaran siklus dibagi hari tersisa.
/// Jawaban satu angka untuk "boleh jajan berapa hari ini?".
library;

({int remaining, int perDay}) safeToSpend({
  required int totalBudget,
  required int spent,
  required int daysLeft,
}) {
  final remaining = totalBudget - spent;
  if (remaining <= 0) return (remaining: remaining, perDay: 0);
  return (
    remaining: remaining,
    perDay: daysLeft <= 1 ? remaining : remaining ~/ daysLeft,
  );
}
