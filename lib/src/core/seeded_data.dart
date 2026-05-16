/// Default categories + payment methods seeded into every new household.
/// Editable by users post-creation.
library;

class SeededCategory {
  final String id;
  final String label;
  final String icon;
  final String color;

  const SeededCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class SeededPaymentMethod {
  final String id;
  final String label;
  final String type;

  const SeededPaymentMethod({
    required this.id,
    required this.label,
    required this.type,
  });
}

const seededCategories = <SeededCategory>[
  SeededCategory(id: 'food', label: 'Makanan & Minuman', icon: 'restaurant', color: '#F59E0B'),
  SeededCategory(id: 'bills', label: 'Tagihan & Utilitas', icon: 'receipt_long', color: '#3B82F6'),
  SeededCategory(id: 'shopping', label: 'Belanja', icon: 'shopping_bag', color: '#EC4899'),
  SeededCategory(id: 'transport', label: 'Transportasi', icon: 'directions_car', color: '#10B981'),
  SeededCategory(id: 'entertainment', label: 'Hiburan', icon: 'movie', color: '#8B5CF6'),
  SeededCategory(id: 'health', label: 'Kesehatan', icon: 'favorite', color: '#EF4444'),
  SeededCategory(id: 'other', label: 'Lainnya', icon: 'category', color: '#64748B'),
];

const seededPaymentMethods = <SeededPaymentMethod>[
  SeededPaymentMethod(id: 'cash', label: 'Tunai', type: 'cash'),
  SeededPaymentMethod(id: 'bca_debit', label: 'BCA Debit', type: 'debit'),
  SeededPaymentMethod(id: 'mandiri_debit', label: 'Mandiri Debit', type: 'debit'),
  SeededPaymentMethod(id: 'gopay', label: 'GoPay', type: 'ewallet'),
  SeededPaymentMethod(id: 'ovo', label: 'OVO', type: 'ewallet'),
  SeededPaymentMethod(id: 'dana', label: 'DANA', type: 'ewallet'),
  SeededPaymentMethod(id: 'cc', label: 'Kartu Kredit', type: 'credit'),
];
