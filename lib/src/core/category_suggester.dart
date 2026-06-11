/// Keyword → category suggestion for the record-expense flow.
///
/// Pure Dart so the matcher is unit-testable. The keyword map targets the
/// seeded category IDs (`seeded_data.dart`) which survive label renames.
/// Sources: Exa research Jun 2026 — top Indonesian merchants/services
/// (ShopeePay/GoPay/DANA/OVO, Shopee/TikTok Shop/Tokopedia, GoFood/GrabFood/
/// ShopeeFood, PLN/IndiHome/BPJS, dst) + common id-ID spending vocabulary.
library;

/// Longest-keyword-wins suggestion. Returns a seeded category id
/// ('food' | 'bills' | 'shopping' | 'transport' | 'entertainment' |
/// 'health' | 'other') or null when nothing matches.
String? suggestSeededCategoryId(String note) {
  final normalized = _normalize(note);
  if (normalized.isEmpty) return null;
  final padded = ' $normalized ';

  String? best;
  var bestLen = 0;
  for (final entry in _keywordToCategory.entries) {
    final kw = entry.key;
    if (kw.length <= bestLen) continue;
    if (padded.contains(' $kw ')) {
      best = entry.value;
      bestLen = kw.length;
    }
  }
  return best;
}

/// Matches the note against custom category labels (e.g. a user-added
/// "Kopi" category catches note "kopi tuku"). Label tokens of length >= 4
/// are matched as whole words. Returns the matching category id or null.
String? suggestByLabel(
  String note,
  Iterable<({String id, String label})> categories,
) {
  final padded = ' ${_normalize(note)} ';
  if (padded.trim().isEmpty) return null;
  for (final c in categories) {
    for (final token in _normalize(c.label).split(' ')) {
      if (token.length >= 4 && padded.contains(' $token ')) return c.id;
    }
  }
  return null;
}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

/// keyword (normalized, single word or phrase) → seeded category id.
const _keywordToCategory = <String, String>{
  // ---- Makanan & Minuman ----------------------------------------------
  'gofood': 'food', 'go food': 'food', 'grabfood': 'food',
  'grab food': 'food', 'shopeefood': 'food', 'shopee food': 'food',
  'maxim food': 'food',
  'makan': 'food', 'makanan': 'food', 'minum': 'food', 'minuman': 'food',
  'sarapan': 'food', 'jajan': 'food', 'snack': 'food', 'cemilan': 'food',
  'camilan': 'food', 'catering': 'food', 'frozen food': 'food',
  'kopi': 'food', 'cafe': 'food', 'kafe': 'food', 'coffee': 'food',
  'starbucks': 'food', 'janji jiwa': 'food', 'kopi kenangan': 'food',
  'fore': 'food', 'tuku': 'food', 'boba': 'food', 'chatime': 'food',
  'mixue': 'food', 'es teh': 'food', 'es krim': 'food', 'dessert': 'food',
  'warung': 'food', 'warteg': 'food', 'resto': 'food', 'restoran': 'food',
  'bakso': 'food', 'mie ayam': 'food', 'mie': 'food', 'bakmi': 'food',
  'nasi': 'food', 'nasi goreng': 'food', 'padang': 'food', 'sate': 'food',
  'seblak': 'food', 'geprek': 'food', 'ayam': 'food', 'martabak': 'food',
  'gorengan': 'food', 'soto': 'food', 'pecel': 'food', 'gado gado': 'food',
  'steak': 'food', 'dimsum': 'food', 'sushi': 'food', 'ramen': 'food',
  'takoyaki': 'food', 'cilok': 'food', 'batagor': 'food', 'siomay': 'food',
  'mcd': 'food', 'mcdonald': 'food', 'mcdonalds': 'food', 'kfc': 'food',
  'burger': 'food', 'pizza': 'food', 'hokben': 'food', 'richeese': 'food',
  'roti': 'food', 'bakery': 'food', 'donat': 'food',
  'galon': 'food', 'aqua': 'food',
  'buah': 'food', 'sayur': 'food', 'beras': 'food', 'telur': 'food',
  'bumbu': 'food', 'dapur': 'food',

  // ---- Tagihan & Utilitas ----------------------------------------------
  'listrik': 'bills', 'pln': 'bills', 'token listrik': 'bills',
  'pdam': 'bills', 'pam': 'bills', 'air pam': 'bills',
  'indihome': 'bills', 'biznet': 'bills', 'first media': 'bills',
  'myrepublic': 'bills', 'wifi': 'bills', 'internet': 'bills',
  'pulsa': 'bills', 'paket data': 'bills', 'kuota': 'bills',
  'telkomsel': 'bills', 'indosat': 'bills', 'im3': 'bills', 'axis': 'bills',
  'smartfren': 'bills', 'by u': 'bills', 'tri': 'bills', 'xl': 'bills',
  'bpjs': 'bills', 'iuran': 'bills', 'ipl': 'bills', 'sampah': 'bills',
  'gas': 'bills', 'lpg': 'bills', 'elpiji': 'bills',
  'spp': 'bills', 'uang sekolah': 'bills', 'sekolah': 'bills',
  'les': 'bills', 'bimbel': 'bills', 'daycare': 'bills',
  'asuransi': 'bills', 'premi': 'bills',
  'pajak': 'bills', 'pbb': 'bills',
  'sewa': 'bills', 'kontrakan': 'bills', 'kos': 'bills', 'kost': 'bills',
  'kpr': 'bills', 'tagihan': 'bills', 'langganan': 'bills',
  'biaya admin': 'bills', 'admin bank': 'bills', 'materai': 'bills',
  'art': 'bills', 'gaji art': 'bills', 'pembantu': 'bills',

  // ---- Belanja -----------------------------------------------------------
  'shopee': 'shopping', 'tokopedia': 'shopping', 'tokped': 'shopping',
  'lazada': 'shopping', 'blibli': 'shopping', 'tiktok shop': 'shopping',
  'tiktokshop': 'shopping',
  'indomaret': 'shopping', 'alfamart': 'shopping', 'alfamidi': 'shopping',
  'superindo': 'shopping', 'hypermart': 'shopping', 'transmart': 'shopping',
  'supermarket': 'shopping', 'minimarket': 'shopping', 'pasar': 'shopping',
  'belanja': 'shopping', 'baju': 'shopping', 'celana': 'shopping',
  'sepatu': 'shopping', 'sandal': 'shopping', 'tas': 'shopping',
  'uniqlo': 'shopping', 'zara': 'shopping', 'matahari': 'shopping',
  'ramayana': 'shopping',
  'skincare': 'shopping', 'kosmetik': 'shopping', 'makeup': 'shopping',
  'sociolla': 'shopping', 'parfum': 'shopping', 'somethinc': 'shopping',
  'skintific': 'shopping',
  'miniso': 'shopping', 'mr diy': 'shopping', 'ikea': 'shopping',
  'informa': 'shopping', 'ace': 'shopping',
  'elektronik': 'shopping', 'laptop': 'shopping', 'aksesoris': 'shopping',
  'mainan': 'shopping', 'kado': 'shopping', 'hadiah': 'shopping',
  'popok': 'shopping', 'pampers': 'shopping', 'diapers': 'shopping',
  'sabun': 'shopping', 'shampoo': 'shopping', 'sampo': 'shopping',
  'deterjen': 'shopping', 'odol': 'shopping', 'pasta gigi': 'shopping',
  'tisu': 'shopping', 'tissue': 'shopping',

  // ---- Transportasi -------------------------------------------------------
  'gojek': 'transport', 'goride': 'transport', 'gocar': 'transport',
  'go ride': 'transport', 'go car': 'transport',
  'grab': 'transport', 'grabbike': 'transport', 'grabcar': 'transport',
  'grab bike': 'transport', 'grab car': 'transport',
  'maxim': 'transport', 'indrive': 'transport', 'bluebird': 'transport',
  'taksi': 'transport', 'taxi': 'transport', 'ojek': 'transport',
  'ojol': 'transport',
  'bensin': 'transport', 'pertamina': 'transport', 'pertalite': 'transport',
  'pertamax': 'transport', 'shell': 'transport', 'spbu': 'transport',
  'solar': 'transport', 'bbm': 'transport',
  'parkir': 'transport', 'tol': 'transport', 'etoll': 'transport',
  'e toll': 'transport',
  'krl': 'transport', 'mrt': 'transport', 'lrt': 'transport',
  'transjakarta': 'transport', 'busway': 'transport', 'bus': 'transport',
  'kereta': 'transport', 'kai': 'transport',
  'pesawat': 'transport', 'garuda': 'transport', 'lion air': 'transport',
  'citilink': 'transport', 'airasia': 'transport', 'batik air': 'transport',
  'damri': 'transport',
  'servis motor': 'transport', 'servis mobil': 'transport',
  'service motor': 'transport', 'service mobil': 'transport',
  'bengkel': 'transport', 'oli': 'transport', 'ban': 'transport',
  'cuci motor': 'transport', 'cuci mobil': 'transport',
  'stnk': 'transport', 'kir': 'transport',

  // ---- Hiburan -------------------------------------------------------------
  'netflix': 'entertainment', 'spotify': 'entertainment',
  'disney': 'entertainment', 'vidio': 'entertainment',
  'viu': 'entertainment', 'wetv': 'entertainment',
  'youtube premium': 'entertainment', 'prime video': 'entertainment',
  'hbo': 'entertainment', 'catchplay': 'entertainment',
  'iqiyi': 'entertainment',
  'bioskop': 'entertainment', 'xxi': 'entertainment', 'cgv': 'entertainment',
  'cinepolis': 'entertainment', 'nonton': 'entertainment',
  'film': 'entertainment',
  'game': 'entertainment', 'steam': 'entertainment',
  'top up game': 'entertainment', 'topup game': 'entertainment',
  'diamond': 'entertainment', 'mobile legends': 'entertainment',
  'genshin': 'entertainment', 'valorant': 'entertainment',
  'pubg': 'entertainment', 'free fire': 'entertainment',
  'playstation': 'entertainment', 'nintendo': 'entertainment',
  'timezone': 'entertainment',
  'konser': 'entertainment', 'karaoke': 'entertainment',
  'liburan': 'entertainment', 'wisata': 'entertainment',
  'staycation': 'entertainment', 'hotel': 'entertainment',
  'villa': 'entertainment', 'traveloka': 'entertainment',
  'tiket com': 'entertainment', 'agoda': 'entertainment',
  'rekreasi': 'entertainment',

  // ---- Kesehatan ------------------------------------------------------------
  'dokter': 'health', 'rumah sakit': 'health', 'rs': 'health',
  'klinik': 'health', 'puskesmas': 'health',
  'apotek': 'health', 'apotik': 'health', 'kimia farma': 'health',
  'k24': 'health', 'century': 'health', 'guardian': 'health',
  'watsons': 'health',
  'halodoc': 'health', 'alodokter': 'health',
  'obat': 'health', 'vitamin': 'health', 'suplemen': 'health',
  'lab': 'health', 'mcu': 'health', 'medical check': 'health',
  'gigi': 'health', 'kacamata': 'health', 'optik': 'health',
  'terapi': 'health', 'fisioterapi': 'health',
  'vaksin': 'health', 'imunisasi': 'health', 'bidan': 'health',
  'posyandu': 'health',
  'gym': 'health', 'fitness': 'health', 'pijat': 'health', 'urut': 'health',

  // ---- Lainnya ----------------------------------------------------------------
  'zakat': 'other', 'infaq': 'other', 'infak': 'other', 'sedekah': 'other',
  'donasi': 'other', 'qurban': 'other', 'kurban': 'other',
  'arisan': 'other', 'kondangan': 'other', 'angpao': 'other',
  'amplop': 'other', 'nikahan': 'other', 'hajatan': 'other',
  'sumbangan': 'other', 'patungan': 'other', 'urunan': 'other',
  'kas rt': 'other',
  'laundry': 'other', 'pangkas': 'other', 'barbershop': 'other',
  'salon': 'other', 'potong rambut': 'other', 'cukur': 'other',
  'print': 'other', 'fotokopi': 'other', 'denda': 'other',
};
