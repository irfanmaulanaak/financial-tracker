// screens-actions.jsx — Add Income, Action Chooser (bottom sheet), Edit Asset modal.

// ───── Bottom-sheet primitive ─────
function BottomSheet({ theme, open, onClose, children, height = 'auto' }) {
  if (!open) return null;
  return (
    <div style={{
      position: 'absolute', inset: 0, zIndex: 70, display: 'flex',
      flexDirection: 'column', justifyContent: 'flex-end',
    }}>
      {/* backdrop */}
      <div onClick={onClose} style={{
        position: 'absolute', inset: 0,
        background: theme.name === 'dark' ? 'rgba(0,0,0,0.5)' : 'rgba(10,8,4,0.32)',
        backdropFilter: 'blur(2px)',
        animation: 'ft-fadeup 200ms both',
      }}/>
      <div style={{
        position: 'relative',
        background: theme.bg,
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '10px 0 28px',
        boxShadow: theme.name === 'dark' ? '0 -10px 40px rgba(0,0,0,0.45)' : '0 -10px 40px rgba(0,0,0,0.12)',
        animation: 'ft-fadeup 280ms cubic-bezier(.2,.7,.3,1) both',
        maxHeight: '85%', overflow: 'auto',
      }} className="ft-scroll">
        <div style={{ display: 'flex', justifyContent: 'center', padding: '4px 0 8px' }}>
          <div style={{ width: 42, height: 5, borderRadius: 4, background: theme.lineStrong }}/>
        </div>
        {children}
      </div>
    </div>
  );
}

// ───── Action chooser sheet (Pengeluaran vs Pendapatan vs Sesuaikan Aset) ─────
function ActionChooserSheet({ theme, open, onClose, go }) {
  const actions = [
    { id: 'expense', label: 'Catat Pengeluaran', detail: 'Tunai · Debit · Kartu Kredit', icon: 'arrowDown', color: theme.clay, route: 'add' },
    { id: 'income',  label: 'Catat Pendapatan',  detail: 'Gaji · Freelance · Lainnya',   icon: 'arrowUp',   color: theme.moss, route: 'addIncome' },
    { id: 'adjust',  label: 'Sesuaikan Aset',    detail: 'Update saldo rekening / posisi', icon: 'pulse',  color: theme.sky,  route: 'assets' },
  ];
  return (
    <BottomSheet theme={theme} open={open} onClose={onClose}>
      <div style={{ padding: '4px 22px 8px' }}>
        <Eyebrow theme={theme}>Catat Aktivitas</Eyebrow>
      </div>
      <div style={{ padding: '0 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {actions.map(a => (
          <button key={a.id} onClick={() => { onClose(); setTimeout(() => go(a.route), 50); }}
            style={{
              display: 'flex', alignItems: 'center', gap: 14, width: '100%',
              padding: '16px 18px', borderRadius: 16, textAlign: 'left',
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              cursor: 'pointer',
            }}>
            <div style={{
              width: 42, height: 42, borderRadius: 12,
              background: `${a.color}1a`, border: `0.5px solid ${a.color}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name={a.icon} size={20} color={a.color} stroke={2}/></div>
            <div style={{ flex: 1 }}>
              <div className="ft-serif" style={{ fontSize: 16, color: theme.ink, fontWeight: 500 }}>{a.label}</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{a.detail}</div>
            </div>
            <Icon name="forward" size={14} color={theme.ink4}/>
          </button>
        ))}
      </div>
    </BottomSheet>
  );
}

// ───── Add Income Screen ─────
function AddIncomeScreen({ theme, data, go, onCommit }) {
  const [amount, setAmount] = React.useState(0);
  const [source, setSource] = React.useState('salary');
  const [account, setAccount] = React.useState(data.cashAccounts[0].id);
  const [note, setNote] = React.useState('');
  const [recurring, setRecurring] = React.useState(false);

  function tap(d) {
    if (d === '←') { setAmount(Math.floor(amount / 10)); return; }
    if (d === '000') { setAmount(amount * 1000); return; }
    setAmount(Math.min(999_999_999, amount * 10 + Number(d)));
  }
  const keys = ['1','2','3','4','5','6','7','8','9','000','0','←'];

  const src = data.incomeSources.find(s => s.id === source);
  const acc = data.cashAccounts.find(a => a.id === account);

  function handleCommit() {
    onCommit({
      amount, source, account, note,
      label: note || src.label,
      recurring,
    });
    go('home');
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: theme.bg }}>
      <SubHeader theme={theme} title="Catat Pendapatan" onBack={() => go('home')}
        action={
          <button onClick={handleCommit} disabled={!amount}
            style={{
              width: 34, height: 34, borderRadius: '50%',
              background: amount ? theme.moss : theme.line, color: '#fff',
              opacity: amount ? 1 : 0.5,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="check" size={16} color={amount ? '#fff' : theme.ink3} stroke={2}/></button>
        }/>

      <div style={{ flex: 1, overflow: 'auto' }} className="ft-scroll">
        {/* amount */}
        <div style={{ padding: '20px 22px 12px', textAlign: 'center' }}>
          <Eyebrow theme={theme}>Jumlah Pendapatan</Eyebrow>
          <div className="ft-serif" style={{
            fontSize: 48, fontWeight: 400, color: theme.ink, letterSpacing: -1.5,
            marginTop: 10, lineHeight: 1,
          }}>
            <span style={{ fontSize: 20, color: theme.ink3, marginRight: 6, letterSpacing: 0 }}>+Rp</span>
            <span style={{ color: amount > 0 ? theme.moss : theme.ink }}>{amount.toLocaleString('id-ID')}</span>
            <span className="ft-pulse" style={{ display: 'inline-block', width: 2, height: 38, background: theme.moss, marginLeft: 6, verticalAlign: 'middle' }}/>
          </div>
          {amount > 0 && (
            <div style={{ fontSize: 11, color: theme.ink3, marginTop: 10 }}>
              Masuk ke <span style={{ color: theme.ink, fontWeight: 500 }}>{acc.label}</span> · Rasio menabung naik ~{((amount / data.month.income) * 12).toFixed(1)}%
            </div>
          )}
        </div>

        {/* source */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Sumber</Eyebrow>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {data.incomeSources.map(s => {
              const on = source === s.id;
              return (
                <button key={s.id} onClick={() => setSource(s.id)} style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  padding: '7px 12px', borderRadius: 999,
                  background: on ? theme[s.color] : theme.surface,
                  color: on ? '#fff' : theme.ink2,
                  border: `0.5px solid ${on ? theme[s.color] : theme.line}`,
                  fontSize: 12, fontWeight: 500,
                  transition: 'all 200ms',
                }}>
                  <Icon name={s.icon} size={13} color={on ? '#fff' : theme[s.color]}/>
                  {s.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* destination account */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Masuk ke</Eyebrow>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {data.cashAccounts.map(a => {
              const on = account === a.id;
              return (
                <button key={a.id} onClick={() => setAccount(a.id)} style={{
                  display: 'flex', alignItems: 'center', gap: 12,
                  padding: '11px 14px', borderRadius: 12, textAlign: 'left',
                  background: on ? `${theme.moss}10` : theme.surface,
                  border: `0.5px solid ${on ? theme.moss : theme.line}`,
                  cursor: 'pointer', transition: 'all 200ms',
                }}>
                  <div style={{
                    width: 28, height: 28, borderRadius: 8,
                    background: on ? theme.moss : theme.surfaceAlt,
                    border: `0.5px solid ${on ? theme.moss : theme.line}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon name="bank" size={14} color={on ? '#fff' : theme.ink2}/>
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{a.label}</div>
                    <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{a.hint}</div>
                  </div>
                  <div className="ft-mono" style={{ fontSize: 12, color: theme.ink3 }}>
                    {fmtRp(a.value, { compact: true })}
                  </div>
                  {on && <Icon name="check" size={14} color={theme.moss} stroke={2.5}/>}
                </button>
              );
            })}
          </div>
        </div>

        {/* recurring toggle */}
        <div style={{ padding: '0 22px 14px' }}>
          <button onClick={() => setRecurring(!recurring)} style={{
            width: '100%', padding: '14px 16px', borderRadius: 12,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            display: 'flex', alignItems: 'center', gap: 12, textAlign: 'left',
          }}>
            <Icon name="pulse" size={16} color={recurring ? theme.moss : theme.ink3}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>Pendapatan rutin</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>Setiap bulan otomatis tercatat</div>
            </div>
            <div style={{
              width: 38, height: 22, borderRadius: 999, padding: 2,
              background: recurring ? theme.moss : theme.line,
              transition: 'background 200ms',
            }}>
              <div style={{
                width: 18, height: 18, borderRadius: '50%', background: '#fff',
                transform: recurring ? 'translateX(16px)' : 'translateX(0)',
                transition: 'transform 200ms',
              }}/>
            </div>
          </button>
        </div>

        {/* note */}
        <div style={{ padding: '0 22px 24px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Catatan (opsional)</Eyebrow>
          <input value={note} onChange={e => setNote(e.target.value)}
            placeholder="Misal: Bonus akhir tahun"
            style={{
              width: '100%', padding: '12px 14px', borderRadius: 12,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              color: theme.ink, fontSize: 13, fontFamily: 'inherit', outline: 'none',
            }}/>
        </div>
      </div>

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

// ───── Edit Asset Sheet (adjust balance / set new value) ─────
function EditAssetSheet({ theme, open, onClose, item, kind = 'cash', onSave }) {
  const [mode, setMode] = React.useState('set'); // 'set' | 'delta'
  const [value, setValue] = React.useState(0);
  const [sign, setSign] = React.useState('+'); // for delta

  React.useEffect(() => {
    if (open && item) {
      setMode('set');
      setValue(item.value);
      setSign('+');
    }
  }, [open, item]);

  if (!item) return null;

  const newBalance = mode === 'set' ? value : (sign === '+' ? item.value + value : item.value - value);
  const diff = newBalance - item.value;

  function tap(d) {
    if (d === '←') { setValue(Math.floor(value / 10)); return; }
    if (d === '000') { setValue(value * 1000); return; }
    setValue(Math.min(9_999_999_999, value * 10 + Number(d)));
  }
  const keys = ['1','2','3','4','5','6','7','8','9','000','0','←'];

  return (
    <BottomSheet theme={theme} open={open} onClose={onClose}>
      <div style={{ padding: '6px 22px 12px' }}>
        <Eyebrow theme={theme}>Sesuaikan Saldo</Eyebrow>
        <div className="ft-serif" style={{ fontSize: 19, color: theme.ink, fontWeight: 500, marginTop: 4, letterSpacing: -0.3 }}>
          {item.label}
        </div>
        <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{item.hint}</div>
      </div>

      {/* mode toggle */}
      <div style={{ padding: '0 22px 12px' }}>
        <div style={{
          display: 'flex', padding: 3, borderRadius: 12,
          background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
        }}>
          {[{ id: 'set', label: 'Atur Saldo' }, { id: 'delta', label: 'Tambah / Kurangi' }].map(m => (
            <button key={m.id} onClick={() => { setMode(m.id); setValue(m.id === 'set' ? item.value : 0); }}
              style={{
                flex: 1, padding: '8px 0', borderRadius: 10, fontSize: 12, fontWeight: 500,
                background: mode === m.id ? theme.ink : 'transparent',
                color: mode === m.id ? theme.bg : theme.ink2,
              }}>{m.label}</button>
          ))}
        </div>
      </div>

      {/* delta sign toggle */}
      {mode === 'delta' && (
        <div style={{ padding: '0 22px 12px' }}>
          <div style={{ display: 'flex', gap: 8 }}>
            {['+', '−'].map(s => {
              const on = sign === s || (sign === '+' && s === '+') || (sign === '-' && s === '−');
              return (
                <button key={s} onClick={() => setSign(s === '−' ? '-' : '+')} style={{
                  flex: 1, padding: '10px 0', borderRadius: 10, fontSize: 18,
                  fontFamily: "'Newsreader', serif", fontWeight: 500,
                  background: on ? (s === '+' ? theme.moss : theme.danger) : theme.surface,
                  color: on ? '#fff' : theme.ink2,
                  border: `0.5px solid ${on ? 'transparent' : theme.line}`,
                }}>{s}</button>
              );
            })}
          </div>
        </div>
      )}

      {/* value display */}
      <div style={{ padding: '0 22px 14px', textAlign: 'center' }}>
        <Eyebrow theme={theme}>{mode === 'set' ? 'Saldo Baru' : 'Jumlah Penyesuaian'}</Eyebrow>
        <div className="ft-serif" style={{
          fontSize: 38, color: theme.ink, fontWeight: 400, letterSpacing: -1,
          marginTop: 8, lineHeight: 1,
        }}>
          <span style={{ fontSize: 18, color: theme.ink3, marginRight: 6, letterSpacing: 0 }}>
            {mode === 'delta' ? (sign === '+' ? '+' : '−') : ''}Rp
          </span>
          {value.toLocaleString('id-ID')}
        </div>
        {mode === 'delta' && value > 0 && (
          <div style={{ fontSize: 11, color: theme.ink3, marginTop: 8 }}>
            Saldo baru: <span className="ft-mono" style={{ color: theme.ink, fontWeight: 500 }}>{fmtRp(newBalance, { compact: true })}</span>
          </div>
        )}
        {mode === 'set' && (
          <div style={{ fontSize: 11, color: theme.ink3, marginTop: 8 }}>
            Sebelumnya <span className="ft-mono">{fmtRp(item.value, { compact: true })}</span>
            {diff !== 0 && (
              <span style={{ color: diff > 0 ? theme.moss : theme.danger, marginLeft: 6, fontWeight: 500 }}>
                {diff > 0 ? '+' : '−'}{fmtRp(Math.abs(diff), { compact: true })}
              </span>
            )}
          </div>
        )}
      </div>

      {/* mini keypad */}
      <div style={{ padding: '0 22px 12px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {keys.map(k => (
            <button key={k} onClick={() => tap(k)} style={{
              padding: '11px 0', borderRadius: 12,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              fontSize: 19, color: theme.ink, fontFamily: "'Newsreader', serif", fontWeight: 400,
            }}>{k}</button>
          ))}
        </div>
      </div>

      <div style={{ padding: '8px 22px 0', display: 'flex', gap: 10 }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '14px 0', borderRadius: 12,
          background: theme.surface, border: `0.5px solid ${theme.line}`,
          color: theme.ink, fontSize: 13, fontWeight: 500,
        }}>Batal</button>
        <button onClick={() => { onSave(item.id, newBalance, kind); onClose(); }}
          disabled={mode === 'delta' && value === 0}
          style={{
            flex: 1, padding: '14px 0', borderRadius: 12,
            background: theme.ink, color: theme.bg, fontSize: 13, fontWeight: 500,
            opacity: (mode === 'delta' && value === 0) ? 0.4 : 1,
          }}>Simpan</button>
      </div>
    </BottomSheet>
  );
}

window.BottomSheet = BottomSheet;
window.ActionChooserSheet = ActionChooserSheet;
window.AddIncomeScreen = AddIncomeScreen;
window.EditAssetSheet = EditAssetSheet;
