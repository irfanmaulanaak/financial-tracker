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

  /// See `Category.isInvestment` — excluded from total-spend aggregates.
  final bool isInvestment;

  const SeededCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.isInvestment = false,
  });
}

// Colors are the light-mode values of `FtColors.cat*` (warm editorial
// palette). `parseColor` maps them — and the legacy Tailwind seeds — onto
// theme-aware light/dark pairs at render time.
const seededCategories = <SeededCategory>[
  SeededCategory(id: 'food', label: 'Makanan & Minuman', icon: 'restaurant', color: '#C4612A'),
  SeededCategory(id: 'bills', label: 'Tagihan & Utilitas', icon: 'receipt_long', color: '#B89030'),
  SeededCategory(id: 'shopping', label: 'Belanja', icon: 'shopping_bag', color: '#7A3F4E'),
  SeededCategory(id: 'transport', label: 'Transportasi', icon: 'directions_car', color: '#5E7A64'),
  SeededCategory(id: 'entertainment', label: 'Hiburan', icon: 'movie', color: '#3A6075'),
  SeededCategory(id: 'health', label: 'Kesehatan', icon: 'favorite', color: '#2D5040'),
  SeededCategory(id: 'investment', label: 'Investasi', icon: 'trending_up', color: '#E8B4C0', isInvestment: true),
  SeededCategory(id: 'other', label: 'Lainnya', icon: 'category', color: '#A89880'),
];
