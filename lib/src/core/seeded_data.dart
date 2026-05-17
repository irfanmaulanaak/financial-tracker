/// Default categories seeded into every new household. Editable by users
/// post-creation.
///
/// Note: payment methods are NO LONGER seeded. The "where did the money
/// come from" question is now answered by:
/// - cash flow → `Expense.sourceAccountId` → `Household.cashAccounts/savingsAccounts[].id`
/// - credit flow → `Expense.cardId` → `households/{hid}/cards/{cid}`
///
/// The user models their own real accounts (BCA, GoPay, etc.) on the Aset
/// screen instead of picking from a fixed seeded list.
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

const seededCategories = <SeededCategory>[
  SeededCategory(id: 'food', label: 'Makanan & Minuman', icon: 'restaurant', color: '#F59E0B'),
  SeededCategory(id: 'bills', label: 'Tagihan & Utilitas', icon: 'receipt_long', color: '#3B82F6'),
  SeededCategory(id: 'shopping', label: 'Belanja', icon: 'shopping_bag', color: '#EC4899'),
  SeededCategory(id: 'transport', label: 'Transportasi', icon: 'directions_car', color: '#10B981'),
  SeededCategory(id: 'entertainment', label: 'Hiburan', icon: 'movie', color: '#8B5CF6'),
  SeededCategory(id: 'health', label: 'Kesehatan', icon: 'favorite', color: '#EF4444'),
  SeededCategory(id: 'other', label: 'Lainnya', icon: 'category', color: '#64748B'),
];
