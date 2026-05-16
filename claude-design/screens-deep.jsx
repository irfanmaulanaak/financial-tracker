// screens-deep.jsx — Add Expense, Expenses log, Spend chart, Category detail,
// Goals, Health detector, Investments, Settings.

// ───── Shared sub-header bar (back + title) ─────
function SubHeader({ theme, title, onBack, action }) {
  return (
    <div style={{
      padding: '54px 18px 14px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      gap: 8, position: 'sticky', top: 0,
      background: theme.bg, zIndex: 5,
      borderBottom: `0.5px solid ${theme.line}`,
    }}>
      <button onClick={onBack} style={{
        width: 34, height: 34, borderRadius: '50%',
        border: `0.5px solid ${theme.line}`, background: theme.surface,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}><Icon name="back" size={16} color={theme.ink2}/></button>
      <div className="ft-serif" style={{ fontSize: 17, color: theme.ink, fontWeight: 500 }}>{title}</div>
      <div style={{ minWidth: 34 }}>{action}</div>
    </div>
  );
}

// ───── ADD EXPENSE SCREEN ─────
function AddExpenseScreen({ theme, data, go, onCommit, initialPayType = 'cash', initialAmount = 0 }) {
  const [amount, setAmount] = React.useState(initialAmount);
  const [cat, setCat] = React.useState('food');
  const [note, setNote] = React.useState('');

  // payment type: 'cash' (cash/debit/e-wallet) or 'credit' (CC w/ installment)
  const [payType, setPayType] = React.useState(initialPayType);
  const cashOptions = ['Tunai', 'BCA Debit', 'GoPay', 'OVO'];
  const [cashMethod, setCashMethod] = React.useState('GoPay');
  const [cardId, setCardId] = React.useState(data.cards[0].id);
  const [planId, setPlanId] = React.useState('full');

  const card = data.cards.find(c => c.id === cardId);
  const plan = data.installmentPlans.find(p => p.id === planId);
  const monthly = plan.months > 1
    ? Math.round((amount * (1 + plan.apr/100 * plan.months / 12)) / plan.months)
    : amount;

  function tap(d) {
    if (d === '←') { setAmount(Math.floor(amount / 10)); return; }
    if (d === '000') { setAmount(amount * 1000); return; }
    setAmount(Math.min(999_999_999, amount * 10 + Number(d)));
  }

  function handleCommit() {
    const method = payType === 'cash'
      ? cashMethod
      : `${card.label}${plan.months > 1 ? ` · ${plan.months}× cicilan` : ''}`;
    onCommit({ amount, cat, note, method, payType, cardId: payType === 'credit' ? cardId : null, planId: payType === 'credit' ? planId : null });
    go('home');
  }

  const keys = ['1','2','3','4','5','6','7','8','9','000','0','←'];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: theme.bg }}>
      <SubHeader theme={theme} title="Catat Pengeluaran" onBack={() => go('home')}
        action={
          <button onClick={handleCommit}
            disabled={!amount}
            style={{
              width: 34, height: 34, borderRadius: '50%',
              background: amount ? theme.ink : theme.line, color: theme.bg,
              opacity: amount ? 1 : 0.5,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="check" size={16} color={amount ? theme.bg : theme.ink3} stroke={2}/></button>
        }/>

      <div style={{ flex: 1, overflow: 'auto' }} className="ft-scroll">
        {/* amount display */}
        <div style={{ padding: '20px 22px 12px', textAlign: 'center' }}>
          <Eyebrow theme={theme}>Jumlah</Eyebrow>
          <div className="ft-serif" style={{
            fontSize: 48, fontWeight: 400, color: theme.ink, letterSpacing: -1.5,
            marginTop: 10, lineHeight: 1,
          }}>
            <span style={{ fontSize: 20, color: theme.ink3, marginRight: 6, letterSpacing: 0 }}>Rp</span>
            {amount.toLocaleString('id-ID')}
            <span className="ft-pulse" style={{ display: 'inline-block', width: 2, height: 38, background: theme.clay, marginLeft: 6, verticalAlign: 'middle' }}/>
          </div>
        </div>

        {/* category chips */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Kategori</Eyebrow>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {data.categories.map(c => {
              const on = cat === c.id;
              return (
                <button key={c.id} onClick={() => setCat(c.id)} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: '7px 12px', borderRadius: 999,
                  background: on ? theme[c.color] : theme.surface,
                  color: on ? '#fff' : theme.ink2,
                  border: `0.5px solid ${on ? theme[c.color] : theme.line}`,
                  fontSize: 12, fontWeight: 500,
                  transition: 'all 200ms',
                }}>
                  <Icon name={c.icon} size={13} color={on ? '#fff' : theme[c.color]}/>
                  {c.label.split(' ')[0]}
                </button>
              );
            })}
          </div>
        </div>

        {/* payment type: cash vs credit */}
        <div style={{ padding: '0 22px 12px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Pembayaran</Eyebrow>
          <div style={{
            display: 'flex', padding: 3, borderRadius: 12,
            background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
          }}>
            <button onClick={() => setPayType('cash')} style={{
              flex: 1, padding: '9px 0', borderRadius: 10, fontSize: 12, fontWeight: 500,
              background: payType === 'cash' ? theme.ink : 'transparent',
              color: payType === 'cash' ? theme.bg : theme.ink2,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
              <Icon name="cash" size={14} color={payType === 'cash' ? theme.bg : theme.ink2}/>
              Tunai / Debit
            </button>
            <button onClick={() => setPayType('credit')} style={{
              flex: 1, padding: '9px 0', borderRadius: 10, fontSize: 12, fontWeight: 500,
              background: payType === 'credit' ? theme.ink : 'transparent',
              color: payType === 'credit' ? theme.bg : theme.ink2,
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
              <Icon name="bank" size={14} color={payType === 'credit' ? theme.bg : theme.ink2}/>
              Kartu Kredit
            </button>
          </div>
        </div>

        {/* cash variant: methods */}
        {payType === 'cash' && (
          <div style={{ padding: '0 22px 14px' }}>
            <div style={{ display: 'flex', gap: 8 }}>
              {cashOptions.map(m => {
                const on = cashMethod === m;
                return (
                  <button key={m} onClick={() => setCashMethod(m)} style={{
                    flex: 1, padding: '8px 0', borderRadius: 10,
                    background: on ? theme.surface : 'transparent',
                    color: on ? theme.ink : theme.ink3,
                    border: `0.5px solid ${on ? theme.lineStrong : theme.line}`,
                    fontSize: 11, fontWeight: 500,
                  }}>{m}</button>
                );
              })}
            </div>
          </div>
        )}

        {/* credit variant: card + plan */}
        {payType === 'credit' && (
          <div style={{ padding: '0 22px 14px' }}>
            {/* card selector */}
            <div style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
              {data.cards.map(c => {
                const on = cardId === c.id;
                const accent = theme[c.accent];
                return (
                  <button key={c.id} onClick={() => setCardId(c.id)} style={{
                    flex: 1, padding: 10, borderRadius: 12, textAlign: 'left',
                    background: on ? `${accent}1a` : theme.surface,
                    border: `0.5px solid ${on ? accent : theme.line}`,
                    transition: 'all 200ms',
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                      <div style={{ width: 6, height: 6, borderRadius: '50%', background: accent }}/>
                      <span style={{ fontSize: 11, color: theme.ink, fontWeight: 500 }}>{c.label}</span>
                    </div>
                    <div className="ft-mono" style={{ fontSize: 10, color: theme.ink3 }}>•••• {c.last4}</div>
                    <div style={{ marginTop: 6 }}>
                      <Bar value={c.used} max={c.limit} color={accent} track={theme.line} height={2}/>
                    </div>
                    <div className="ft-mono" style={{ fontSize: 9, color: theme.ink3, marginTop: 4 }}>
                      Tersisa {fmtRp(c.limit - c.used, { compact: true })}
                    </div>
                  </button>
                );
              })}
            </div>

            {/* installment plans */}
            <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Cicilan</Eyebrow>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 6 }}>
              {data.installmentPlans.map(p => {
                const on = planId === p.id;
                return (
                  <button key={p.id} onClick={() => setPlanId(p.id)} style={{
                    padding: '10px 4px', borderRadius: 10,
                    background: on ? theme.ink : theme.surface,
                    color: on ? theme.bg : theme.ink2,
                    border: `0.5px solid ${on ? theme.ink : theme.line}`,
                    fontSize: 11, fontWeight: 500,
                    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 2,
                  }}>
                    <span style={{ fontSize: 13, fontFamily: "'Newsreader', serif", fontWeight: 500 }}>
                      {p.months === 1 ? 'Lunas' : `${p.months}×`}
                    </span>
                    <span style={{ fontSize: 9, opacity: 0.7 }}>
                      {p.apr === 0 ? (p.months > 1 ? '0%' : 'penuh') : `${p.apr}% pa`}
                    </span>
                  </button>
                );
              })}
            </div>

            {/* preview */}
            {amount > 0 && (
              <div style={{
                marginTop: 12, padding: 12, borderRadius: 10,
                background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
              }}>
                {plan.months === 1 ? (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: 11, color: theme.ink3 }}>Tagihan saat jatuh tempo</span>
                    <span className="ft-mono ft-serif" style={{ fontSize: 16, color: theme.ink, fontWeight: 500 }}>
                      {fmtRp(amount, { compact: true })}
                    </span>
                  </div>
                ) : (
                  <>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
                      <span style={{ fontSize: 11, color: theme.ink3 }}>Cicilan per bulan</span>
                      <div>
                        <span className="ft-mono ft-serif" style={{ fontSize: 18, color: theme.ink, fontWeight: 500 }}>
                          {fmtRp(monthly, { compact: true })}
                        </span>
                        <span style={{ fontSize: 11, color: theme.ink3 }}> × {plan.months} bln</span>
                      </div>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: theme.ink3 }}>
                      <span>Total bayar</span>
                      <span className="ft-mono">{fmtRp(monthly * plan.months, { compact: true })}</span>
                    </div>
                    {plan.apr > 0 && (
                      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: theme.ink3, marginTop: 2 }}>
                        <span>Bunga ({plan.apr}% pa)</span>
                        <span className="ft-mono">+{fmtRp(monthly * plan.months - amount, { compact: true })}</span>
                      </div>
                    )}
                  </>
                )}
              </div>
            )}
          </div>
        )}

        {/* note */}
        <div style={{ padding: '0 22px 24px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Catatan (opsional)</Eyebrow>
          <input value={note} onChange={e => setNote(e.target.value)}
            placeholder="Misal: Kopi Tuku"
            style={{
              width: '100%', padding: '12px 14px', borderRadius: 12,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              color: theme.ink, fontSize: 13, fontFamily: 'inherit', outline: 'none',
            }}/>
        </div>
      </div>

      {/* keypad */}
      <div style={{
        padding: '14px 22px 28px',
        background: theme.surfaceAlt, borderTop: `0.5px solid ${theme.line}`,
      }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
          {keys.map(k => (
            <button key={k} onClick={() => tap(k)} style={{
              padding: '13px 0', borderRadius: 14,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              fontSize: 22, color: theme.ink, fontFamily: "'Newsreader', serif", fontWeight: 400,
            }}>{k}</button>
          ))}
        </div>
      </div>
    </div>
  );
}

// ───── EXPENSES LOG SCREEN ─────
function ExpensesScreen({ theme, data, go, extraExpenses = [] }) {
  const [filter, setFilter] = React.useState('all');
  const [memberFilter, setMemberFilter] = React.useState('all');
  const all = [...extraExpenses, ...data.expenses];
  let list = filter === 'all' ? all : all.filter(e => e.cat === filter);
  if (memberFilter !== 'all') list = list.filter(e => e.by === memberFilter);

  // group by date
  const grouped = list.reduce((m, e) => {
    (m[e.date] = m[e.date] || []).push(e);
    return m;
  }, {});

  const totalToday = all.filter(e => e.date === '16 Mei').reduce((s, e) => s + e.amount, 0);
  const household = data.household;

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Pengeluaran" onBack={() => go('home')}
        action={<button style={{ width: 34, height: 34, borderRadius: '50%', background: theme.surface, border: `0.5px solid ${theme.line}`, display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="filter" size={16} color={theme.ink2}/></button>}/>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <Eyebrow theme={theme}>{household && household.sharedWallet ? 'Total Hari Ini · Keluarga' : 'Total Hari Ini'}</Eyebrow>
              <div className="ft-serif" style={{ fontSize: 26, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
                {fmtRp(totalToday, { compact: true })}
              </div>
            </div>
            <button onClick={() => go('add')} style={{
              padding: '8px 14px', borderRadius: 999, background: theme.ink, color: theme.bg,
              fontSize: 12, fontWeight: 500, display: 'inline-flex', alignItems: 'center', gap: 4,
            }}><Icon name="plus" size={14} color={theme.bg} stroke={2}/> Catat</button>
          </div>
        </Card>
      </div>

      {/* member filter */}
      {household && (
        <div style={{ padding: '14px 16px 0', display: 'flex', gap: 6, overflowX: 'auto' }} className="ft-scroll">
          {[{ id: 'all', label: 'Semua Anggota' },
            ...household.members.filter(m => m.status === 'active').map(m => ({ id: m.id, member: m })),
          ].map(f => {
            const on = memberFilter === f.id;
            if (f.member) {
              const color = theme[f.member.color];
              return (
                <button key={f.id} onClick={() => setMemberFilter(f.id)} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: '5px 10px 5px 4px', borderRadius: 999, fontSize: 12, fontWeight: 500,
                  background: on ? color : theme.surface,
                  color: on ? '#fff' : theme.ink2,
                  border: `0.5px solid ${on ? color : theme.line}`,
                  whiteSpace: 'nowrap',
                }}>
                  <MemberAvatar member={f.member} theme={theme} size={20}/>
                  {f.member.isMe ? 'Saya' : f.member.name.split(' ')[0]}
                </button>
              );
            }
            return (
              <button key={f.id} onClick={() => setMemberFilter(f.id)} style={{
                padding: '7px 12px', borderRadius: 999, fontSize: 12, fontWeight: 500,
                background: on ? theme.ink : theme.surface, color: on ? theme.bg : theme.ink2,
                border: `0.5px solid ${on ? theme.ink : theme.line}`,
                whiteSpace: 'nowrap',
              }}>{f.label}</button>
            );
          })}
        </div>
      )}

      <div style={{ padding: '8px 16px 0', display: 'flex', gap: 6, overflowX: 'auto' }} className="ft-scroll">
        {[{id:'all',label:'Semua'}, ...data.categories.map(c => ({id:c.id, label:c.label.split(' ')[0], color: c.color}))].map(f => {
          const on = filter === f.id;
          return (
            <button key={f.id} onClick={() => setFilter(f.id)} style={{
              padding: '6px 12px', borderRadius: 999, fontSize: 12, whiteSpace: 'nowrap',
              background: on ? theme.ink : theme.surface, color: on ? theme.bg : theme.ink2,
              border: `0.5px solid ${on ? theme.ink : theme.line}`,
              fontWeight: 500,
            }}>{f.label}</button>
          );
        })}
      </div>

      {Object.entries(grouped).map(([date, items]) => (
        <div key={date}>
          <div style={{ padding: '14px 22px 6px', display: 'flex', justifyContent: 'space-between' }}>
            <span style={{ fontSize: 11, letterSpacing: 1, textTransform: 'uppercase', color: theme.ink3, fontWeight: 500 }}>{date}</span>
            <span className="ft-mono" style={{ fontSize: 11, color: theme.ink3 }}>
              {fmtRp(items.reduce((s, e) => s + e.amount, 0), { compact: true })}
            </span>
          </div>
          <Card theme={theme} padded={false} style={{ margin: '0 16px' }}>
            {items.map((e, i) => {
              const cat = data.categories.find(c => c.id === e.cat);
              return (
                <div key={e.id} style={{
                  display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                  borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
                }}>
                  <div style={{
                    width: 34, height: 34, borderRadius: 10,
                    background: `${theme[cat.color]}1a`, border: `0.5px solid ${theme[cat.color]}33`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}><Icon name={cat.icon} size={15} color={theme[cat.color]}/></div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{e.label}</div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 3, flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 11, color: theme.ink3 }}>{e.time} · {e.method}</span>
                      {household && e.by && <MemberChip memberId={e.by} members={household.members} theme={theme}/>}
                    </div>
                  </div>
                  <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                    −{fmtRp(e.amount, { compact: true })}
                  </div>
                </div>
              );
            })}
          </Card>
        </div>
      ))}
    </div>
  );
}

// ───── SPEND CHART SCREEN (monthly, categorized) ─────
function SpendScreen({ theme, data, go }) {
  const [period, setPeriod] = React.useState('Mei');
  const [hoverId, setHoverId] = React.useState(null);
  const cats = data.categories;
  const total = cats.reduce((s, c) => s + c.value, 0);
  const segments = cats.map(c => ({ id: c.id, value: c.value, color: c.color }));

  // mock multi-month bars
  const months = [
    { label: 'Feb', total: 7_900_000, segments: cats.map(c => ({ color: c.color, value: c.value * 0.9 })) },
    { label: 'Mar', total: 8_800_000, segments: cats.map(c => ({ color: c.color, value: c.value * 1.05 })) },
    { label: 'Apr', total: 8_400_000, segments: cats.map(c => ({ color: c.color, value: c.value * 1.0 })) },
    { label: 'Mei', total: total,     segments: cats.map(c => ({ color: c.color, value: c.value })) },
  ];

  const focused = hoverId ? cats.find(c => c.id === hoverId) : null;

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Pengeluaran Bulanan" onBack={() => go('home')}/>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div>
              <Eyebrow theme={theme}>{data.month.name} · Total</Eyebrow>
              <div className="ft-serif" style={{ fontSize: 30, color: theme.ink, marginTop: 4, letterSpacing: -0.5 }}>
                {fmtRp(focused ? focused.value : total, { compact: true })}
              </div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 4 }}>
                {focused ? focused.label : `${Math.round((total / data.month.budget) * 100)}% dari anggaran · ${data.month.daysPassed}/${data.month.daysTotal} hari`}
              </div>
            </div>
            <Donut segments={segments} size={130} thickness={16} theme={theme} t={1}/>
          </div>

          <div style={{ display: 'flex', gap: 6, padding: '12px 0 0', borderTop: `0.5px dashed ${theme.line}` }}>
            {['Feb','Mar','Apr','Mei'].map(p => {
              const on = period === p;
              return (
                <button key={p} onClick={() => setPeriod(p)} style={{
                  flex: 1, padding: '6px 0', borderRadius: 8,
                  background: on ? theme.ink : 'transparent', color: on ? theme.bg : theme.ink2,
                  fontSize: 11, fontWeight: 500,
                }}>{p}</button>
              );
            })}
          </div>
        </Card>
      </div>

      {/* monthly trend bars removed — focus on the breakdown below */}

      {/* category legend list */}
      <div style={{ padding: '14px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Rincian Kategori</Eyebrow>
        <Card theme={theme} padded={false}>
          {cats.map((c, i) => {
            const pct = (c.value / total) * 100;
            const overBudget = c.value > c.budget;
            return (
              <button key={c.id}
                onMouseEnter={() => setHoverId(c.id)}
                onMouseLeave={() => setHoverId(null)}
                onClick={() => go('category', c.id)}
                style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  width: '100%', padding: '12px 16px', textAlign: 'left',
                  borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
                  background: hoverId === c.id ? theme.surfaceAlt : 'transparent',
                  transition: 'background 150ms',
                }}>
                <div style={{ width: 10, height: 10, borderRadius: 3, background: theme[c.color] }}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{c.label}</span>
                    <span className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                      {fmtRp(c.value, { compact: true })}
                    </span>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 4 }}>
                    <span className="ft-mono" style={{ fontSize: 10, color: theme.ink3 }}>{pct.toFixed(1)}%</span>
                    <span style={{ fontSize: 10, color: overBudget ? theme.danger : theme.ink3 }}>
                      {overBudget ? `+${Math.round(((c.value/c.budget)-1)*100)}% vs anggaran` : `dari ${fmtRp(c.budget, { compact: true })}`}
                    </span>
                  </div>
                </div>
                <Icon name="forward" size={14} color={theme.ink4}/>
              </button>
            );
          })}
        </Card>
      </div>
    </div>
  );
}

// ───── CATEGORY DETAIL SCREEN ─────
function CategoryScreen({ theme, data, catId, go }) {
  const cat = data.categories.find(c => c.id === catId) || data.categories[0];
  const expenses = data.expenses.filter(e => e.cat === cat.id);
  const pct = (cat.value / cat.budget) * 100;
  const over = cat.value > cat.budget;
  const avgPrev = cat.budget * 0.85; // mock prior avg
  const delta = ((cat.value - avgPrev) / avgPrev) * 100;
  const deltaPos = delta > 0;

  // mini daily bars for last 14 days
  const daily = Array.from({ length: 14 }, (_, i) => Math.max(0, Math.round(cat.value/14 * (0.4 + Math.random() * 1.6))));

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title={cat.label} onBack={() => go('spend')}/>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{
              width: 44, height: 44, borderRadius: 12,
              background: `${theme[cat.color]}1a`, border: `0.5px solid ${theme[cat.color]}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name={cat.icon} size={20} color={theme[cat.color]}/></div>
            <div style={{ flex: 1 }}>
              <Eyebrow theme={theme}>Pengeluaran {data.month.name}</Eyebrow>
              <div className="ft-serif" style={{ fontSize: 26, color: theme.ink, marginTop: 2, letterSpacing: -0.3 }}>
                {fmtRp(cat.value, { compact: true })}
              </div>
            </div>
            <Chip color={over ? theme.danger : theme.healthOk} theme={theme}>
              {over ? '↑ Over' : '✓ Aman'}
            </Chip>
          </div>

          <div style={{ marginTop: 14 }}>
            <Bar value={cat.value} max={cat.budget} color={theme[cat.color]} track={theme.line} height={6}
              overflowColor={theme.danger}/>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
              <span className="ft-mono" style={{ fontSize: 11, color: theme.ink2 }}>
                {fmtRp(cat.value, { compact: true })} / {fmtRp(cat.budget, { compact: true })}
              </span>
              <span style={{ fontSize: 11, color: over ? theme.danger : theme.ink3 }}>
                {Math.round(pct)}% terpakai
              </span>
            </div>
          </div>
        </Card>
      </div>

      {/* analysis card — drilldown from health detector */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginBottom: 10 }}>
            <Icon name="pulse" size={16} color={theme.clay}/>
            <Eyebrow theme={theme}>Analisis Kategori</Eyebrow>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 14 }}>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>vs rata-rata 3 bulan</div>
              <div className="ft-serif" style={{
                fontSize: 22, marginTop: 2, letterSpacing: -0.3,
                color: deltaPos ? theme.danger : theme.healthOk,
              }}>
                {deltaPos ? '+' : ''}{delta.toFixed(1)}%
              </div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Pengeluaran harian</div>
              <div className="ft-serif" style={{ fontSize: 22, marginTop: 2, color: theme.ink, letterSpacing: -0.3 }}>
                {fmtRp(Math.round(cat.value / data.month.daysPassed), { compact: true })}
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 3, height: 64 }}>
            {daily.map((v, i) => {
              const h = (v / Math.max(...daily)) * 56 + 4;
              return <div key={i} style={{
                flex: 1, height: h, borderRadius: 2,
                background: i === daily.length - 1 ? theme[cat.color] : `${theme[cat.color]}55`,
              }}/>;
            })}
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
            <span style={{ fontSize: 10, color: theme.ink3 }}>14 hari terakhir</span>
            <span style={{ fontSize: 10, color: theme.ink3 }}>hari ini</span>
          </div>

          {/* verdict */}
          <div style={{
            marginTop: 14, padding: 12, borderRadius: 10,
            background: over ? `${theme.danger}10` : `${theme.healthOk}10`,
            border: `0.5px solid ${over ? theme.danger : theme.healthOk}33`,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
              <TrafficLight state={over ? 'risk' : (deltaPos ? 'caution' : 'good')} theme={theme} size={6}/>
              <span style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>
                {over ? 'Melebihi anggaran' : (deltaPos ? 'Naik dari biasanya' : 'Dalam batas wajar')}
              </span>
            </div>
            <div style={{ fontSize: 11, color: theme.ink2, lineHeight: 1.5 }}>
              {over
                ? `Kategori ini sudah lewat anggaran ${Math.round(pct - 100)}%. Pertimbangkan menahan pembelian non-esensial selama 7 hari ke depan, atau alokasikan ulang dari kategori "Lainnya" (Rp ${(600).toLocaleString('id-ID')}rb sisa).`
                : `Pola pengeluaran wajar untuk kategori ini. Sisa anggaran ${fmtRp(cat.budget - cat.value, { compact: true })} untuk ${data.month.daysTotal - data.month.daysPassed} hari ke depan (≈ ${fmtRp(Math.round((cat.budget - cat.value)/(data.month.daysTotal - data.month.daysPassed)), { compact: true })}/hari).`
              }
            </div>
          </div>
        </Card>
      </div>

      {/* transactions in this category */}
      {expenses.length > 0 && (
        <div style={{ padding: '14px 22px 0' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Transaksi Terbaru</Eyebrow>
          <Card theme={theme} padded={false}>
            {expenses.map((e, i) => (
              <div key={e.id} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '12px 16px', borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              }}>
                <div>
                  <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{e.label}</div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{e.date} · {e.time} · {e.method}</div>
                </div>
                <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                  −{fmtRp(e.amount, { compact: true })}
                </div>
              </div>
            ))}
          </Card>
        </div>
      )}
    </div>
  );
}

window.AddExpenseScreen = AddExpenseScreen;
window.ExpensesScreen = ExpensesScreen;
window.SpendScreen = SpendScreen;
window.CategoryScreen = CategoryScreen;
window.SubHeader = SubHeader;
