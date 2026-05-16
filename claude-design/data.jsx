// data.jsx — mock dataset for the financial tracker prototype

const FT_DATA = {
  user: {
    name: 'Citra Andini',
    initials: 'CA',
    memberSince: 'Sejak Mar 2023',
    asOf: 'Hari ini, 14:08',
  },

  // Shared household
  household: {
    name: 'Keluarga Andini',
    sharedWallet: true,
    members: [
      { id: 'me',      name: 'Citra Andini',    initials: 'CA', role: 'Istri',  status: 'active',  color: 'clay', isMe: true,  joinedAt: 'Mar 2023' },
      { id: 'aditya',  name: 'Aditya Pratama',  initials: 'AP', role: 'Suami',  status: 'active',  color: 'sky',  joinedAt: 'Mar 2023' },
      { id: 'naysila', name: 'Naysila Andini',  initials: 'NA', role: 'Anak',   status: 'pending', color: 'plum', joinedAt: '14 Mei 2026' },
    ],
  },

  assets: {
    total: 248_500_000,
    deltaMo: 4_320_000, // monthly change
    deltaPct: 1.8,
    breakdown: [
      { id: 'cash', label: 'Tunai & Rekening', value: 32_000_000, hint: '3 rekening', deltaPct: -0.4 },
      { id: 'savings', label: 'Tabungan Berjangka', value: 60_500_000, hint: 'Deposito · Goals', deltaPct: +0.8 },
      { id: 'inv', label: 'Investasi', value: 156_000_000, hint: 'Saham · Reksa Dana · Emas', deltaPct: +2.6 },
    ],
  },

  // Asset-class detail (accounts/positions)
  cashAccounts: [
    { id: 'bca',   label: 'BCA · Tabungan',  hint: '•••• 8821',     value: 18_500_000 },
    { id: 'bni',   label: 'BNI · Giro',      hint: '•••• 4012',     value:  9_200_000 },
    { id: 'gopay', label: 'GoPay',           hint: 'e-Wallet',      value:  4_300_000 },
  ],
  savingsAccounts: [
    { id: 'depo',     label: 'BCA Deposito 6 bln', hint: '4.5% pa · jatuh tempo 12 Sep', value: 35_000_000 },
    { id: 'em-locked', label: 'Tabungan Dana Darurat', hint: 'auto-debit Rp 2.5jt/bln',  value: 25_500_000 },
  ],
  investments: [
    { id: 'stocks-id',     label: 'Saham Indonesia', hint: 'IHSG · 12 emiten',         value: 96_700_000, delta: -2.1 },
    { id: 'stocks-global', label: 'Saham Global',    hint: 'S&P 500 ETF · NASDAQ',     value: 18_750_000, delta: +5.8 },
    { id: 'mm',            label: 'Pasar Uang',       hint: 'Reksa Dana · 3.8% pa',     value: 18_700_000, delta: +0.3 },
    { id: 'bonds',         label: 'Obligasi (SBN)',   hint: 'FR0086 · ORI020',          value: 12_500_000, delta: +0.4 },
    { id: 'gold',          label: 'Emas Digital',     hint: 'Pegadaian · 8.4 gr',       value:  9_350_000, delta: +3.2 },
  ],

  today: {
    date: 'Sabtu, 16 Mei 2026',
    spend: 285_000,
    budget: 450_000,
    txnCount: 4,
  },

  month: {
    name: 'Mei 2026',
    daysPassed: 16,
    daysTotal: 31,
    spend: 6_820_000,
    budget: 12_000_000,
    savingsRate: 18.4,        // %
    savingsRatePrev: 26.1,
    income: 18_500_000,
  },

  // Income sources for entry
  incomeSources: [
    { id: 'salary',    label: 'Gaji',           icon: 'cash',    color: 'sage' },
    { id: 'freelance', label: 'Freelance',      icon: 'sparkle', color: 'clay' },
    { id: 'invest',    label: 'Hasil Investasi', icon: 'trend',   color: 'moss' },
    { id: 'gift',      label: 'Hadiah',         icon: 'heart',   color: 'plum' },
    { id: 'refund',    label: 'Pengembalian',   icon: 'arrowDown', color: 'sky' },
    { id: 'other',     label: 'Lainnya',        icon: 'dots',    color: 'catOther' },
  ],

  // Income log
  incomes: [
    { id: 'i1', date: '01 Mei', time: '09:00', source: 'salary',    label: 'Gaji · PT Anugrah Karya',    amount: 16_000_000, account: 'bca' },
    { id: 'i2', date: '08 Mei', time: '14:22', source: 'freelance', label: 'Project · Brand Identity',   amount:  2_500_000, account: 'gopay' },
  ],

  // Credit cards — debt tracking
  cards: [
    {
      id: 'bca-mc', label: 'BCA Mastercard', last4: '4821',
      limit: 25_000_000, used: 4_850_000, accumulatedMo: 1_924_000,
      dueDate: '28 Mei', minPayment: 485_000,
      apr: 26.95, accent: 'plum',
      // Active installment plans on this card
      installments: [
        { id: 'i1', label: 'iPhone 16 Pro', total: 19_999_000, monthly: 1_667_000, monthsTotal: 12, monthsPaid: 4, started: 'Jan 2026' },
        { id: 'i2', label: 'Uniqlo · Kemeja',  total: 399_000,    monthly: 133_000,   monthsTotal: 3,  monthsPaid: 0, started: 'Mei 2026' },
      ],
    },
    {
      id: 'mandiri-visa', label: 'Mandiri Visa', last4: '7203',
      limit: 15_000_000, used: 1_180_000, accumulatedMo: 383_000,
      dueDate: '05 Jun', minPayment: 120_000,
      apr: 28.5, accent: 'clay',
      installments: [
        { id: 'i3', label: 'Tokopedia · Skincare', total: 287_000, monthly: 96_000, monthsTotal: 3, monthsPaid: 0, started: 'Mei 2026' },
      ],
    },
  ],

  // Cicilan plan options at point-of-sale
  installmentPlans: [
    { id: 'full', label: 'Lunas',  months: 1,  apr: 0 },
    { id: '3',    label: '3 bulan', months: 3,  apr: 0,  badge: '0% promo' },
    { id: '6',    label: '6 bulan', months: 6,  apr: 6.5 },
    { id: '12',   label: '12 bulan',months: 12, apr: 12.0 },
  ],

  // Health: traffic light → amber
  health: {
    score: 72,
    state: 'caution',         // 'good' | 'caution' | 'risk'
    summary: 'Pengeluaran terkendali, tapi rasio menabung turun bulan ini.',
    factors: [
      { id: 'spend',   label: 'Disiplin pengeluaran',  weight: 30, score: 78, state: 'good',    note: '56% anggaran terpakai di hari ke-16' },
      { id: 'save',    label: 'Rasio menabung',        weight: 25, score: 58, state: 'caution', note: 'Turun dari 26% → 18% bulan ini' },
      { id: 'emfund',  label: 'Dana darurat',          weight: 20, score: 84, state: 'good',    note: '4.1× pengeluaran bulanan' },
      { id: 'debt',    label: 'Beban utang',           weight: 15, score: 92, state: 'good',    note: 'Tidak ada utang konsumtif' },
      { id: 'invest',  label: 'Diversifikasi investasi', weight: 10, score: 64, state: 'caution', note: 'Konsentrasi 62% di saham ID' },
    ],
    flags: [
      { cat: 'Belanja', delta: +24, msg: 'Belanja non-esensial naik 24% vs rata-rata 3 bulan' },
      { cat: 'Hiburan', delta: +12, msg: 'Langganan + makan keluar di atas pola biasa' },
      { cat: 'Transport', delta: -8, msg: 'Lebih hemat dari rata-rata — pertahankan' },
    ],
  },

  // Categories — total = month.spend
  categories: [
    { id: 'food',      label: 'Makanan & Minuman', value: 2_140_000, budget: 3_000_000, color: 'catFood',          icon: 'fork' },
    { id: 'bills',     label: 'Tagihan & Utilitas', value: 1_450_000, budget: 1_500_000, color: 'catBills',        icon: 'bolt' },
    { id: 'shopping',  label: 'Belanja',            value: 1_180_000, budget: 800_000,   color: 'catShopping',     icon: 'bag' },
    { id: 'transport', label: 'Transportasi',       value:   980_000, budget: 1_200_000, color: 'catTransport',    icon: 'car' },
    { id: 'entertainment', label: 'Hiburan',        value:   520_000, budget: 400_000,   color: 'catEntertainment', icon: 'play' },
    { id: 'health',    label: 'Kesehatan',          value:   350_000, budget: 500_000,   color: 'catHealth',       icon: 'heart' },
    { id: 'other',     label: 'Lainnya',            value:   200_000, budget: 600_000,   color: 'catOther',        icon: 'dots' },
  ],

  // Recent expenses log
  expenses: [
    { id: 1, date: '16 Mei',  time: '13:42', cat: 'food',      label: 'Kopi Tuku',           amount: 38_000,  method: 'GoPay',     by: 'me' },
    { id: 2, date: '16 Mei',  time: '12:15', cat: 'food',      label: 'Makan Siang · Sushi Tei', amount: 142_000, method: 'BCA Debit', by: 'aditya' },
    { id: 3, date: '16 Mei',  time: '09:30', cat: 'transport', label: 'Grab ke Kantor',      amount: 45_000,  method: 'GoPay',     by: 'me' },
    { id: 4, date: '16 Mei',  time: '08:02', cat: 'food',      label: 'Sarapan · Roti O',    amount: 60_000,  method: 'Tunai',     by: 'aditya' },
    { id: 5, date: '15 Mei',  time: '20:11', cat: 'shopping',  label: 'Uniqlo · Kemeja',     amount: 399_000, method: 'BCA Kredit', by: 'me' },
    { id: 6, date: '15 Mei',  time: '19:30', cat: 'entertainment', label: 'CGV · Premiere',  amount: 100_000, method: 'BCA Debit', by: 'aditya' },
    { id: 7, date: '15 Mei',  time: '12:40', cat: 'food',      label: 'Makan Siang',         amount: 75_000,  method: 'GoPay',     by: 'me' },
    { id: 8, date: '15 Mei',  time: '08:15', cat: 'transport', label: 'Grab',                amount: 38_000,  method: 'GoPay',     by: 'me' },
    { id: 9, date: '14 Mei',  time: '21:02', cat: 'bills',     label: 'PLN · Listrik',       amount: 425_000, method: 'BCA Debit', by: 'aditya' },
    { id: 10, date: '14 Mei', time: '18:45', cat: 'shopping',  label: 'Tokopedia · Skincare', amount: 287_000, method: 'BCA Kredit', by: 'me' },
  ],

  goals: [
    { id: 'em',  label: 'Dana Darurat',     target: 75_000_000,  current: 50_000_000,  due: 'Des 2026', monthly: 2_500_000, icon: 'shield', tone: 'sage' },
    { id: 'bali', label: 'Liburan ke Bali', target: 25_000_000,  current:  7_500_000,  due: 'Agu 2026', monthly: 4_500_000, icon: 'wave',   tone: 'sky' },
    { id: 'mac', label: 'MacBook Pro',      target: 30_000_000,  current: 22_000_000,  due: 'Jul 2026', monthly: 4_000_000, icon: 'laptop', tone: 'plum' },
    { id: 'house', label: 'DP Rumah',       target: 500_000_000, current: 180_000_000, due: '2028',     monthly: 8_000_000, icon: 'house',  tone: 'clay' },
  ],

  // Investment allocation recommendation
  allocation: {
    asOf: 'Diperbarui 14 Mei 2026',
    context: 'IHSG sideways · The Fed jeda pemotongan suku bunga · Rupiah menguat tipis · Emas mendekati ATH',
    summary: 'Profil moderat. Pertahankan ekuitas global, tambah obligasi pemerintah seiring stabilitas suku bunga.',
    current: [
      { label: 'Saham Indonesia',   pct: 62, color: 'catShopping' },
      { label: 'Saham Global',      pct: 12, color: 'catTransport' },
      { label: 'Obligasi',          pct: 8,  color: 'catBills' },
      { label: 'Emas',              pct: 6,  color: 'catEntertainment' },
      { label: 'Kas / Pasar Uang',  pct: 12, color: 'catOther' },
    ],
    target: [
      { label: 'Saham Indonesia',   pct: 20, color: 'catShopping' },
      { label: 'Saham Global',      pct: 45, color: 'catTransport' },
      { label: 'Obligasi',          pct: 15, color: 'catBills' },
      { label: 'Emas',              pct: 10, color: 'catEntertainment' },
      { label: 'Kas / Pasar Uang',  pct: 10, color: 'catOther' },
    ],
    moves: [
      { from: 'Saham Indonesia', to: 'Saham Global',  amount: 16_000_000, reason: 'Diversifikasi geografis · USD hedging' },
      { from: 'Kas / Pasar Uang', to: 'Obligasi Pemerintah', amount: 4_000_000, reason: 'Yield SBN 10y 6.7% — lock-in jangka menengah' },
      { from: 'Saham Indonesia', to: 'Emas', amount: 6_000_000, reason: 'Lindung nilai inflasi · ketegangan geopolitik' },
    ],
  },
};

window.FT_DATA = FT_DATA;
