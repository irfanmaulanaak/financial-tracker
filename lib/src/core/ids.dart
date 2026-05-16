import 'dart:math';

/// Short random IDs for embedded subdocs (categories, payment methods,
/// accounts). 8 chars, alphanumeric. Unique within a small bounded set.
String shortId({Random? random}) {
  final rng = random ?? Random.secure();
  const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(8, (_) => alphabet[rng.nextInt(alphabet.length)]).join();
}
