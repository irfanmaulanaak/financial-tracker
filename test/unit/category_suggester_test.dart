import 'package:flutter_test/flutter_test.dart';

import 'package:financial_tracker/src/core/category_suggester.dart';

void main() {
  group('suggestSeededCategoryId', () {
    test('matches common Indonesian merchants', () {
      expect(suggestSeededCategoryId('GoFood ayam geprek'), 'food');
      expect(suggestSeededCategoryId('kopi tuku'), 'food');
      expect(suggestSeededCategoryId('Token listrik PLN'), 'bills');
      expect(suggestSeededCategoryId('bayar indihome'), 'bills');
      expect(suggestSeededCategoryId('checkout Shopee'), 'shopping');
      expect(suggestSeededCategoryId('belanja indomaret'), 'shopping');
      expect(suggestSeededCategoryId('isi bensin pertamax'), 'transport');
      expect(suggestSeededCategoryId('gojek ke kantor'), 'transport');
      expect(suggestSeededCategoryId('langganan Netflix'), 'bills');
      expect(suggestSeededCategoryId('nonton XXI'), 'entertainment');
      expect(suggestSeededCategoryId('obat di apotek'), 'health');
      expect(suggestSeededCategoryId('zakat fitrah'), 'other');
      expect(suggestSeededCategoryId('laundry kiloan'), 'other');
    });

    test('longest keyword wins on overlap', () {
      // 'grab' → transport, but 'grab food' → food.
      expect(suggestSeededCategoryId('grab ke stasiun'), 'transport');
      expect(suggestSeededCategoryId('grab food mcd'), 'food');
      // 'game' → entertainment, 'top up game' also entertainment.
      expect(suggestSeededCategoryId('top up game ml'), 'entertainment');
    });

    test('matches are whole-word, not substring', () {
      // 'tas' must not match inside 'pertamina' / 'batas'.
      expect(suggestSeededCategoryId('batas saldo'), isNull);
      // 'rs' must not match inside 'kursi'.
      expect(suggestSeededCategoryId('beli kursi'), isNull);
      expect(suggestSeededCategoryId('rs hermina'), 'health');
    });

    test('normalizes punctuation and case', () {
      expect(suggestSeededCategoryId('GRAB-FOOD: ayam'), 'food');
      expect(suggestSeededCategoryId('e-toll cikampek'), 'transport');
      expect(suggestSeededCategoryId('tiket.com hotel bali'), 'entertainment');
    });

    test('returns null for empty / no-match notes', () {
      expect(suggestSeededCategoryId(''), isNull);
      expect(suggestSeededCategoryId('   '), isNull);
      expect(suggestSeededCategoryId('qwerty xyz'), isNull);
    });
  });

  group('suggestByLabel', () {
    const cats = [
      (id: 'c1', label: 'Kopi'),
      (id: 'c2', label: 'Anak & Sekolah'),
      (id: 'c3', label: 'Per'), // <4 chars: never matches
    ];

    test('matches custom category label as whole word', () {
      expect(suggestByLabel('kopi kenangan grande', cats), 'c1');
      expect(suggestByLabel('bayar sekolah kakak', cats), 'c2');
    });

    test('short label tokens (<4 chars) are ignored', () {
      expect(suggestByLabel('per bulan', cats), isNull);
    });

    test('no match returns null', () {
      expect(suggestByLabel('belanja bulanan', cats), isNull);
    });
  });
}
