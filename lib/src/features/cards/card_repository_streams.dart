part of 'card_repository.dart';

/// Read-only stream accessors for [CardRepository]. Split into this part file
/// (same library) so they can reach the repository's private collection
/// helpers while keeping `card_repository.dart` under the line budget.
extension CardRepositoryStreams on CardRepository {
  Stream<List<CreditCard>> watchAll(String hid) {
    return _cards(hid).snapshots().map(
          (s) => s.docs.map(CreditCard.fromSnapshot).toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
        );
  }

  Stream<CreditCard?> watchOne({required String hid, required String cardId}) {
    return _cards(hid)
        .doc(cardId)
        .snapshots()
        .map((s) => s.exists ? CreditCard.fromSnapshot(s) : null);
  }

  Stream<List<Installment>> watchInstallments({
    required String hid,
    required String cardId,
  }) {
    return _installments(hid, cardId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Installment.fromSnapshot(d, cardId)).toList());
  }
}
