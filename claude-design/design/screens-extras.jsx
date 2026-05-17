// screens-extras.jsx — AddGoal, PayCardSheet, NotificationsScreen.

// ───── ADD GOAL SCREEN ─────
function AddGoalScreen({ theme, data, go, onCommit }) {
  const [label, setLabel] = React.useState('');
  const [icon, setIcon] = React.useState('target');
  const [tone, setTone] = React.useState('clay');
  const [target, setTarget] = React.useState(0);
  const [current, setCurrent] = React.useState(0);
  const [activeField, setActiveField] = React.useState('target'); // 'target' | 'current'
  const [monthsTo, setMonthsTo] = React.useState(12);
  const [sourceAccount, setSourceAccount] = React.useState(data.cashAccounts[0]?.id || 'bca');
  const [autoTransfer, setAutoTransfer] = React.useState(true);

  const remaining = Math.max(0, target - current);
  const monthly = monthsTo > 0 ? Math.ceil(remaining / monthsTo) : 0;
  const monthsList = [3, 6, 12, 18, 24, 36, 60];

  const dueLabel = (() => {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    const d = new Date(2026, 4, 16);
    d.setMonth(d.getMonth() + monthsTo);
    return `${months[d.getMonth()]} ${d.getFullYear()}`;
  })();

  const presets = [
    { icon: 'shield',  label: 'Dana Darurat', tone: 'sage' },
    { icon: 'wave',    label: 'Liburan',      tone: 'sky' },
    { icon: 'house',   label: 'Rumah',        tone: 'clay' },
    { icon: 'laptop',  label: 'Gadget',       tone: 'plum' },
    { icon: 'heart',   label: 'Pernikahan',   tone: 'plum' },
    { icon: 'sparkle', label: 'Lainnya',      tone: 'ochre' },
  ];

  const tones = [
    { id: 'clay',  name: 'Tanah Liat' },
    { id: 'sage',  name: 'Sage' },
    { id: 'sky',   name: 'Langit' },
    { id: 'plum',  name: 'Anggur' },
    { id: 'ochre', name: 'Oker' },
    { id: 'moss',  name: 'Lumut' },
  ];

  function tap(d) {
    const setter = activeField === 'target' ? setTarget : setCurrent;
    const value = activeField === 'target' ? target : current;
    if (d === '←') { setter(Math.floor(value / 10)); return; }
    if (d === '000') { setter(value * 1000); return; }
    setter(Math.min(9_999_999_999, value * 10 + Number(d)));
  }
  const keys = ['1','2','3','4','5','6','7','8','9','000','0','←'];

  function selectPreset(p) {
    setIcon(p.icon);
    setTone(p.tone);
    if (!label) setLabel(p.label);
  }

  function handleCommit() {
    onCommit({
      label: label || 'Tujuan Baru',
      icon, tone, target, current, monthly,
      due: dueLabel,
      sourceAccount, autoTransfer,
    });
    go('goals');
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: theme.bg }}>
      <SubHeader theme={theme} title="Buat Tujuan Baru" onBack={() => go('goals')}
        action={
          <button onClick={handleCommit} disabled={!target}
            style={{
              width: 34, height: 34, borderRadius: '50%',
              background: target ? theme[tone] : theme.line, color: '#fff',
              opacity: target ? 1 : 0.5,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="check" size={16} color={target ? '#fff' : theme.ink3} stroke={2}/></button>
        }/>

      <div style={{ flex: 1, overflow: 'auto' }} className="ft-scroll">
        {/* Preview hero */}
        <div style={{ padding: '18px 22px 14px' }}>
          <Card theme={theme}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <div style={{
                width: 56, height: 56, borderRadius: 14,
                background: `${theme[tone]}1a`, border: `0.5px solid ${theme[tone]}33`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'all 200ms',
              }}><Icon name={icon} size={26} color={theme[tone]}/></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div className="ft-serif" style={{ fontSize: 18, color: theme.ink, fontWeight: 500, letterSpacing: -0.2 }}>
                  {label || 'Tujuan Baru'}
                </div>
                <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>
                  {target > 0
                    ? `${fmtRp(monthly, { compact: true })}/bln · ${dueLabel}`
                    : 'Atur target untuk melihat proyeksi'}
                </div>
                {target > 0 && (
                  <div style={{ marginTop: 8 }}>
                    <Bar value={current} max={target} color={theme[tone]} track={theme.line} height={3}/>
                  </div>
                )}
              </div>
            </div>
          </Card>
        </div>

        {/* Preset templates */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Template Tujuan</Eyebrow>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
            {presets.map(p => {
              const on = icon === p.icon;
              return (
                <button key={p.icon} onClick={() => selectPreset(p)}
                  style={{
                    padding: '12px 6px', borderRadius: 12,
                    background: on ? `${theme[p.tone]}1a` : theme.surface,
                    border: `0.5px solid ${on ? theme[p.tone] : theme.line}`,
                    display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
                    transition: 'all 200ms', cursor: 'pointer',
                  }}>
                  <Icon name={p.icon} size={20} color={on ? theme[p.tone] : theme.ink2}/>
                  <span style={{ fontSize: 11, color: on ? theme.ink : theme.ink2, fontWeight: 500 }}>
                    {p.label}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Name */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Nama Tujuan</Eyebrow>
          <input value={label} onChange={e => setLabel(e.target.value)}
            placeholder="Misal: Dana Darurat Keluarga"
            style={{
              width: '100%', padding: '12px 14px', borderRadius: 12,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              color: theme.ink, fontSize: 14, fontFamily: 'inherit', outline: 'none',
            }}/>
        </div>

        {/* Accent color */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Aksen Warna</Eyebrow>
          <div style={{ display: 'flex', gap: 8 }}>
            {tones.map(c => {
              const on = tone === c.id;
              return (
                <button key={c.id} onClick={() => setTone(c.id)} style={{
                  width: 36, height: 36, borderRadius: '50%',
                  background: theme[c.id],
                  border: on ? `2px solid ${theme.ink}` : `2px solid transparent`,
                  boxShadow: on ? `inset 0 0 0 2px ${theme.bg}` : 'none',
                  cursor: 'pointer', flexShrink: 0,
                  transition: 'all 200ms',
                }}/>
              );
            })}
          </div>
        </div>

        {/* Amount fields */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Jumlah</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <button onClick={() => setActiveField('target')} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '14px 16px', borderRadius: 12,
              background: activeField === 'target' ? `${theme[tone]}10` : theme.surface,
              border: `0.5px solid ${activeField === 'target' ? theme[tone] : theme.line}`,
              textAlign: 'left', cursor: 'pointer',
            }}>
              <div>
                <div style={{ fontSize: 11, color: theme.ink3, letterSpacing: 0.3 }}>TARGET</div>
                <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
                  Rp {target.toLocaleString('id-ID')}
                  {activeField === 'target' && (
                    <span className="ft-pulse" style={{ display: 'inline-block', width: 2, height: 22, background: theme[tone], marginLeft: 4, verticalAlign: 'middle' }}/>
                  )}
                </div>
              </div>
              {activeField === 'target' && <Icon name="check" size={16} color={theme[tone]} stroke={2}/>}
            </button>
            <button onClick={() => setActiveField('current')} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '14px 16px', borderRadius: 12,
              background: activeField === 'current' ? `${theme[tone]}10` : theme.surface,
              border: `0.5px solid ${activeField === 'current' ? theme[tone] : theme.line}`,
              textAlign: 'left', cursor: 'pointer',
            }}>
              <div>
                <div style={{ fontSize: 11, color: theme.ink3, letterSpacing: 0.3 }}>SUDAH TERKUMPUL · OPSIONAL</div>
                <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
                  Rp {current.toLocaleString('id-ID')}
                  {activeField === 'current' && (
                    <span className="ft-pulse" style={{ display: 'inline-block', width: 2, height: 22, background: theme[tone], marginLeft: 4, verticalAlign: 'middle' }}/>
                  )}
                </div>
              </div>
              {activeField === 'current' && <Icon name="check" size={16} color={theme[tone]} stroke={2}/>}
            </button>
          </div>
        </div>

        {/* Months / due */}
        <div style={{ padding: '0 22px 14px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <Eyebrow theme={theme}>Tercapai dalam</Eyebrow>
            <span style={{ fontSize: 11, color: theme.ink3 }}>{dueLabel}</span>
          </div>
          <div style={{ display: 'flex', gap: 6, overflowX: 'auto' }} className="ft-scroll">
            {monthsList.map(m => {
              const on = monthsTo === m;
              return (
                <button key={m} onClick={() => setMonthsTo(m)} style={{
                  padding: '8px 14px', borderRadius: 999, fontSize: 12, fontWeight: 500,
                  background: on ? theme.ink : theme.surface,
                  color: on ? theme.bg : theme.ink2,
                  border: `0.5px solid ${on ? theme.ink : theme.line}`,
                  whiteSpace: 'nowrap', flexShrink: 0,
                }}>{m < 12 ? `${m} bulan` : m === 12 ? '1 tahun' : `${m/12} tahun`}</button>
              );
            })}
          </div>
        </div>

        {/* Projection card */}
        {target > 0 && (
          <div style={{ padding: '0 22px 14px' }}>
            <div style={{
              padding: 14, borderRadius: 12,
              background: `${theme[tone]}10`, border: `0.5px solid ${theme[tone]}33`,
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
                <Icon name="trend" size={14} color={theme[tone]}/>
                <Eyebrow theme={theme}>Proyeksi</Eyebrow>
              </div>
              <div className="ft-serif" style={{ fontSize: 14, color: theme.ink, lineHeight: 1.45 }}>
                Menabung <span className="ft-mono ft-serif" style={{ color: theme[tone], fontWeight: 500 }}>{fmtRp(monthly, { compact: true })}</span> per bulan
                {current > 0 && <> dari saldo awal <span className="ft-mono ft-serif" style={{ fontWeight: 500 }}>{fmtRp(current, { compact: true })}</span></>},
                tujuan tercapai dalam <span className="ft-mono ft-serif" style={{ fontWeight: 500 }}>{monthsTo} bulan</span>.
              </div>
              {monthly > data.month.income * 0.3 && (
                <div style={{ marginTop: 8, fontSize: 11, color: theme.ochre, display: 'flex', gap: 4 }}>
                  <Icon name="info" size={11} color={theme.ochre}/>
                  Setoran melebihi 30% pendapatan — pertimbangkan target waktu lebih panjang.
                </div>
              )}
            </div>
          </div>
        )}

        {/* Source account + auto-transfer */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Sumber Dana Bulanan</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {data.cashAccounts.map(a => {
              const on = sourceAccount === a.id;
              return (
                <button key={a.id} onClick={() => setSourceAccount(a.id)} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '11px 14px', borderRadius: 12, textAlign: 'left',
                  background: on ? `${theme[tone]}10` : theme.surface,
                  border: `0.5px solid ${on ? theme[tone] : theme.line}`, cursor: 'pointer',
                }}>
                  <Icon name="bank" size={16} color={on ? theme[tone] : theme.ink2}/>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{a.label}</div>
                    <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{a.hint}</div>
                  </div>
                  <div className="ft-mono" style={{ fontSize: 11, color: theme.ink3 }}>
                    {fmtRp(a.value, { compact: true })}
                  </div>
                </button>
              );
            })}
          </div>

          <button onClick={() => setAutoTransfer(!autoTransfer)} style={{
            marginTop: 8,
            width: '100%', padding: '12px 14px', borderRadius: 12,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left', cursor: 'pointer',
          }}>
            <Icon name="pulse" size={16} color={autoTransfer ? theme[tone] : theme.ink3}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>Auto-debit setiap tanggal 1</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>
                Setoran rutin dipotong otomatis dari rekening sumber
              </div>
            </div>
            <div style={{
              width: 38, height: 22, borderRadius: 999, padding: 2,
              background: autoTransfer ? theme[tone] : theme.line,
              transition: 'background 200ms', flexShrink: 0,
            }}>
              <div style={{
                width: 18, height: 18, borderRadius: '50%', background: '#fff',
                transform: autoTransfer ? 'translateX(16px)' : 'translateX(0)',
                transition: 'transform 200ms',
              }}/>
            </div>
          </button>
        </div>

        <div style={{ height: 24 }}/>
      </div>

      {/* keypad */}
      <div style={{
        padding: '14px 22px 28px',
        background: theme.surfaceAlt, borderTop: `0.5px solid ${theme.line}`,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <span style={{ fontSize: 11, color: theme.ink3, letterSpacing: 0.3 }}>
            Edit: <span style={{ color: theme.ink, fontWeight: 500 }}>{activeField === 'target' ? 'Target' : 'Sudah Terkumpul'}</span>
          </span>
        </div>
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

// ───── PAY CARD SHEET ─────
function PayCardSheet({ theme, open, onClose, card, onPay }) {
  const [option, setOption] = React.useState('min'); // 'min' | 'full' | 'custom'
  const [custom, setCustom] = React.useState(0);

  React.useEffect(() => {
    if (open && card) {
      setOption('min');
      setCustom(card.minPayment);
    }
  }, [open, card]);

  if (!card) return null;

  const amount = option === 'min' ? card.minPayment : option === 'full' ? card.used : custom;

  function tap(d) {
    if (option !== 'custom') return;
    if (d === '←') { setCustom(Math.floor(custom / 10)); return; }
    if (d === '000') { setCustom(custom * 1000); return; }
    setCustom(Math.min(card.used, custom * 10 + Number(d)));
  }
  const keys = ['1','2','3','4','5','6','7','8','9','000','0','←'];

  return (
    <BottomSheet theme={theme} open={open} onClose={onClose}>
      <div style={{ padding: '6px 22px 12px' }}>
        <Eyebrow theme={theme}>Bayar Tagihan</Eyebrow>
        <div className="ft-serif" style={{ fontSize: 19, color: theme.ink, fontWeight: 500, marginTop: 4, letterSpacing: -0.3 }}>
          {card.label}
        </div>
        <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>
          Tagihan {fmtRp(card.used, { compact: true })} · Jatuh tempo {card.dueDate}
        </div>
      </div>

      <div style={{ padding: '0 22px 12px' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { id: 'min',    title: 'Bayar Minimum',  detail: `Setoran terendah · hindari denda`, value: card.minPayment },
            { id: 'full',   title: 'Lunas',          detail: 'Bebas bunga · disarankan',         value: card.used },
            { id: 'custom', title: 'Jumlah Lain',    detail: 'Tentukan sendiri',                  value: option === 'custom' ? custom : null },
          ].map(o => {
            const on = option === o.id;
            return (
              <button key={o.id} onClick={() => setOption(o.id)} style={{
                display: 'flex', alignItems: 'center', gap: 12,
                padding: '12px 14px', borderRadius: 12, textAlign: 'left',
                background: on ? `${theme[card.accent]}10` : theme.surface,
                border: `0.5px solid ${on ? theme[card.accent] : theme.line}`, cursor: 'pointer',
              }}>
                <div style={{
                  width: 16, height: 16, borderRadius: '50%',
                  border: `1.5px solid ${on ? theme[card.accent] : theme.lineStrong}`,
                  background: on ? theme[card.accent] : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  {on && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#fff' }}/>}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{o.title}</div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{o.detail}</div>
                </div>
                {o.value !== null && (
                  <span className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                    {fmtRp(o.value, { compact: true })}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* custom keypad */}
      {option === 'custom' && (
        <div style={{ padding: '0 22px 12px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 6 }}>
            {keys.map(k => (
              <button key={k} onClick={() => tap(k)} style={{
                padding: '10px 0', borderRadius: 10,
                background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
                fontSize: 18, color: theme.ink, fontFamily: "'Newsreader', serif", fontWeight: 400,
              }}>{k}</button>
            ))}
          </div>
        </div>
      )}

      <div style={{ padding: '8px 22px 0', display: 'flex', gap: 10 }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '14px 0', borderRadius: 12,
          background: theme.surface, border: `0.5px solid ${theme.line}`,
          color: theme.ink, fontSize: 13, fontWeight: 500,
        }}>Batal</button>
        <button onClick={() => { onPay(card.id, amount); onClose(); }}
          disabled={!amount}
          style={{
            flex: 2, padding: '14px 0', borderRadius: 12,
            background: theme[card.accent], color: '#fff', fontSize: 13, fontWeight: 500,
            opacity: amount ? 1 : 0.4,
          }}>
          Bayar {fmtRp(amount, { compact: true })}
        </button>
      </div>
    </BottomSheet>
  );
}

// ───── NOTIFICATIONS SCREEN ─────
function NotificationsScreen({ theme, data, go }) {
  const groups = [
    {
      label: 'Baru',
      items: [
        { id: 'n1', kind: 'flag',    icon: 'pulse',   color: 'danger', title: 'Belanja melebihi anggaran',  detail: 'Kategori Belanja sudah Rp 1.18jt dari batas Rp 800rb', time: '14:08', tap: () => go('category', 'shopping') },
        { id: 'n2', kind: 'family',  icon: 'house',   color: 'sky',    title: 'Aditya mencatat pengeluaran', detail: 'Rp 142rb · Makan Siang · Sushi Tei',                 time: '12:15', tap: () => go('expenses') },
        { id: 'n3', kind: 'due',     icon: 'bank',    color: 'plum',   title: 'BCA Mastercard jatuh tempo',  detail: '12 hari lagi · Min Rp 485rb',                       time: 'Hari ini', tap: () => go('cards') },
      ],
    },
    {
      label: 'Minggu ini',
      items: [
        { id: 'n4', kind: 'goal',    icon: 'target',  color: 'moss',   title: 'MacBook Pro · 73% tercapai',  detail: 'Tinggal 2 bulan untuk mencapai target',             time: 'Kemarin', tap: () => go('goalDetail', 'mac') },
        { id: 'n5', kind: 'invite',  icon: 'sparkle', color: 'ochre',  title: 'Undangan diterima',           detail: 'Aditya telah bergabung di Keluarga Andini',         time: '2 hari',  tap: () => go('settings') },
        { id: 'n6', kind: 'invest',  icon: 'trend',   color: 'clay',   title: 'Rekomendasi rebalancing',     detail: 'Diversifikasi saham global · The Fed jeda',         time: '3 hari',  tap: () => go('assets') },
      ],
    },
  ];

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Notifikasi" onBack={() => go('home')}
        action={<button style={{ fontSize: 12, color: theme.ink3, padding: '0 8px' }}>Tandai dibaca</button>}/>

      {groups.map(g => (
        <div key={g.label}>
          <div style={{ padding: '18px 22px 8px' }}>
            <Eyebrow theme={theme}>{g.label}</Eyebrow>
          </div>
          <Card theme={theme} padded={false} style={{ margin: '0 16px' }}>
            {g.items.map((it, i) => {
              const c = theme[it.color] || theme.clay;
              return (
                <button key={it.id} onClick={it.tap} style={{
                  display: 'flex', alignItems: 'flex-start', gap: 12,
                  padding: '14px 16px', width: '100%', textAlign: 'left',
                  borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
                  cursor: 'pointer',
                }}>
                  <div style={{
                    width: 36, height: 36, borderRadius: 10,
                    background: `${c}1a`, border: `0.5px solid ${c}33`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0, marginTop: 2,
                  }}><Icon name={it.icon} size={16} color={c}/></div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
                      <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{it.title}</span>
                      <span style={{ fontSize: 10, color: theme.ink4, marginLeft: 'auto', flexShrink: 0 }}>{it.time}</span>
                    </div>
                    <div style={{ fontSize: 11, color: theme.ink3, marginTop: 3, lineHeight: 1.4 }}>{it.detail}</div>
                  </div>
                </button>
              );
            })}
          </Card>
        </div>
      ))}

      <div style={{ textAlign: 'center', padding: '24px 22px 0' }}>
        <button style={{ fontSize: 12, color: theme.ink3 }}>Riwayat lebih lama →</button>
      </div>
    </div>
  );
}

window.AddGoalScreen = AddGoalScreen;
window.PayCardSheet = PayCardSheet;
window.NotificationsScreen = NotificationsScreen;
