// screens-assets.jsx — "Aset" tab: total assets, breakdown across cash /
// savings / investments, plus the allocation recommendation as a subsection.

function AssetsScreen({ theme, data, go, onEditAsset }) {
  const [tab, setTab] = React.useState('tunai'); // tunai | tabungan | investasi | alokasi
  const a = data.assets;
  const cash    = a.breakdown.find(b => b.id === 'cash');
  const savings = a.breakdown.find(b => b.id === 'savings');
  const inv     = a.breakdown.find(b => b.id === 'inv');

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Aset" onBack={() => go('home')}/>

      {/* Hero */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <Eyebrow theme={theme}>Total Aset</Eyebrow>
          <div className="ft-serif ft-fadeup" style={{
            fontSize: 38, fontWeight: 400, color: theme.ink,
            letterSpacing: -1.3, marginTop: 6, lineHeight: 1,
          }}>
            {fmtRp(a.total).replace('Rp ', '')}
            <span className="ft-sans" style={{ fontSize: 13, color: theme.ink3, marginLeft: 8, letterSpacing: 0, fontWeight: 400 }}>IDR</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 12 }}>
            <span style={{
              display: 'inline-flex', alignItems: 'center', gap: 4,
              color: theme.moss, fontSize: 12, fontWeight: 500,
            }}>
              <Icon name="arrowUp" size={12} color={theme.moss} stroke={2}/>
              {fmtRp(a.deltaMo, { compact: true })} · +{a.deltaPct}%
            </span>
            <span style={{ fontSize: 11, color: theme.ink3 }}>vs bulan lalu</span>
          </div>

          {/* Composition bar */}
          <div style={{ marginTop: 16, paddingTop: 16, borderTop: `0.5px dashed ${theme.line}` }}>
            <div style={{ display: 'flex', height: 8, borderRadius: 4, overflow: 'hidden', marginBottom: 12 }}>
              <div style={{ flex: cash.value, background: theme.sky }}/>
              <div style={{ flex: savings.value, background: theme.moss }}/>
              <div style={{ flex: inv.value, background: theme.clay }}/>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10 }}>
              {[
                { label: 'Tunai', v: cash.value, c: theme.sky, dp: cash.deltaPct },
                { label: 'Tabungan', v: savings.value, c: theme.moss, dp: savings.deltaPct },
                { label: 'Investasi', v: inv.value, c: theme.clay, dp: inv.deltaPct },
              ].map(s => (
                <div key={s.label}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                    <div style={{ width: 6, height: 6, borderRadius: '50%', background: s.c }}/>
                    <span style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>{s.label}</span>
                  </div>
                  <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500, marginTop: 3 }}>
                    {fmtRp(s.v, { compact: true })}
                  </div>
                  <div style={{ fontSize: 10, color: s.dp < 0 ? theme.danger : theme.moss, marginTop: 2 }}>
                    {s.dp > 0 ? '+' : ''}{s.dp}%
                  </div>
                </div>
              ))}
            </div>
          </div>
        </Card>
      </div>

      {/* Tabs */}
      <div style={{ padding: '14px 16px 0' }}>
        <div style={{
          display: 'flex', padding: 3, borderRadius: 999,
          background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
        }}>
          {[
            { id: 'tunai', label: 'Tunai' },
            { id: 'tabungan', label: 'Tabungan' },
            { id: 'investasi', label: 'Investasi' },
            { id: 'alokasi', label: 'Alokasi' },
          ].map(t => {
            const on = tab === t.id;
            return (
              <button key={t.id} onClick={() => setTab(t.id)} style={{
                flex: 1, padding: '8px 0', borderRadius: 999, fontSize: 11.5, fontWeight: 500,
                background: on ? theme.ink : 'transparent',
                color: on ? theme.bg : theme.ink2,
                transition: 'all 200ms',
              }}>{t.label}</button>
            );
          })}
        </div>
      </div>

      {/* Tab content */}
      {tab === 'tunai' && <AssetList theme={theme} items={data.cashAccounts} total={cash.value} accent={theme.sky} subtitle="Tunai & rekening cair · siap pakai" kind="cash" onEdit={onEditAsset}/>}
      {tab === 'tabungan' && <AssetList theme={theme} items={data.savingsAccounts} total={savings.value} accent={theme.moss} subtitle="Dana terkunci untuk tujuan dan dana darurat" kind="savings" onEdit={onEditAsset}/>}
      {tab === 'investasi' && <InvestmentList theme={theme} items={data.investments} total={inv.value} accent={theme.clay} kind="inv" onEdit={onEditAsset}/>}
      {tab === 'alokasi' && <AllocationView theme={theme} data={data}/>}
    </div>
  );
}

// ───── Asset list (cash / savings) ─────
function AssetList({ theme, items, total, accent, subtitle, kind, onEdit }) {
  return (
    <div style={{ padding: '14px 22px 0' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
        <Eyebrow theme={theme}>{items.length} rekening</Eyebrow>
        <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>
          {fmtRp(total, { compact: true })}
        </span>
      </div>
      <div style={{ fontSize: 11, color: theme.ink3, marginBottom: 10, lineHeight: 1.4 }}>{subtitle}</div>
      <Card theme={theme} padded={false}>
        {items.map((it, i) => (
          <button key={it.id} onClick={() => onEdit && onEdit(it, kind)}
            style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
              width: '100%', textAlign: 'left',
              borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              transition: 'background 150ms', cursor: onEdit ? 'pointer' : 'default',
            }}
            onMouseEnter={e => onEdit && (e.currentTarget.style.background = theme.surfaceAlt)}
            onMouseLeave={e => onEdit && (e.currentTarget.style.background = 'transparent')}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `${accent}1a`, border: `0.5px solid ${accent}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name="bank" size={16} color={accent}/></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{it.label}</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{it.hint}</div>
            </div>
            <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
              {fmtRp(it.value, { compact: true })}
            </div>
            {onEdit && <Icon name="forward" size={12} color={theme.ink4}/>}
          </button>
        ))}
      </Card>

      {onEdit && (
        <button onClick={() => onEdit({ id: 'new-' + Date.now(), label: 'Rekening Baru', hint: 'Tap untuk atur saldo', value: 0 }, kind)}
          style={{
            marginTop: 12, width: '100%', padding: '12px 0', borderRadius: 12,
            background: 'transparent', border: `0.5px dashed ${theme.lineStrong}`,
            color: theme.ink2, fontSize: 12, fontWeight: 500,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
          <Icon name="plus" size={13} color={theme.ink2} stroke={2}/> Tambah rekening
        </button>
      )}
    </div>
  );
}

// ───── Investment list (with delta + weighting) ─────
function InvestmentList({ theme, items, total, accent, kind, onEdit }) {
  return (
    <div style={{ padding: '14px 22px 0' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
        <Eyebrow theme={theme}>{items.length} posisi</Eyebrow>
        <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>
          {fmtRp(total, { compact: true })}
        </span>
      </div>
      <Card theme={theme} padded={false}>
        {items.map((it, i) => {
          const pct = (it.value / total) * 100;
          const up = it.delta >= 0;
          return (
            <button key={it.id} onClick={() => onEdit && onEdit(it, kind)}
              style={{
                padding: '14px 16px', width: '100%', textAlign: 'left',
                borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
                cursor: onEdit ? 'pointer' : 'default', transition: 'background 150ms',
              }}
              onMouseEnter={e => onEdit && (e.currentTarget.style.background = theme.surfaceAlt)}
              onMouseLeave={e => onEdit && (e.currentTarget.style.background = 'transparent')}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
                <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{it.label}</span>
                <span className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                  {fmtRp(it.value, { compact: true })}
                </span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span style={{ fontSize: 11, color: theme.ink3 }}>{it.hint}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <span className="ft-mono" style={{ fontSize: 10, color: theme.ink3 }}>{pct.toFixed(1)}%</span>
                  <span className="ft-mono" style={{ fontSize: 11, color: up ? theme.moss : theme.danger, fontWeight: 500 }}>
                    {up ? '+' : ''}{it.delta}%
                  </span>
                </div>
              </div>
              <div style={{ marginTop: 8 }}>
                <Bar value={pct} max={100} color={accent} track={theme.line} height={2.5}/>
              </div>
            </button>
          );
        })}
      </Card>
      {onEdit && (
        <button onClick={() => onEdit({ id: 'new-' + Date.now(), label: 'Posisi Baru', hint: 'Tap untuk atur nilai', value: 0, delta: 0 }, kind)}
          style={{
            marginTop: 12, width: '100%', padding: '12px 0', borderRadius: 12,
            background: 'transparent', border: `0.5px dashed ${theme.lineStrong}`,
            color: theme.ink2, fontSize: 12, fontWeight: 500,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
          <Icon name="plus" size={13} color={theme.ink2} stroke={2}/> Tambah posisi
        </button>
      )}
    </div>
  );
}

// ───── Allocation recommendation view (formerly InvestScreen) ─────
function AllocationView({ theme, data }) {
  const [view, setView] = React.useState('target');
  const alloc = view === 'target' ? data.allocation.target : data.allocation.current;
  const segments = alloc.map(a => ({ id: a.label, value: a.pct, color: a.color }));

  return (
    <>
      {/* Market context */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme} style={{ background: theme.surfaceAlt }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <Icon name="sparkle" size={14} color={theme.clay}/>
            <Eyebrow theme={theme}>Kondisi Global</Eyebrow>
            <span style={{ fontSize: 10, color: theme.ink4, marginLeft: 'auto' }}>{data.allocation.asOf}</span>
          </div>
          <div className="ft-serif" style={{ fontSize: 14, color: theme.ink, lineHeight: 1.45, fontWeight: 400 }}>
            {data.allocation.context}
          </div>
        </Card>
      </div>

      {/* Allocation pie */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <Eyebrow theme={theme}>Alokasi Portofolio</Eyebrow>
            <div style={{
              display: 'inline-flex', padding: 3, borderRadius: 999,
              background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
            }}>
              {['current','target'].map(v => (
                <button key={v} onClick={() => setView(v)} style={{
                  padding: '5px 12px', borderRadius: 999, fontSize: 11, fontWeight: 500,
                  background: view === v ? theme.ink : 'transparent',
                  color: view === v ? theme.bg : theme.ink2,
                }}>{v === 'target' ? 'Direkomendasikan' : 'Sekarang'}</button>
              ))}
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <Donut segments={segments} size={150} thickness={20} theme={theme} t={1}/>
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {alloc.map(a => (
                <div key={a.label} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ width: 8, height: 8, borderRadius: 2, background: theme[a.color] }}/>
                  <span style={{ fontSize: 11, color: theme.ink2, flex: 1, lineHeight: 1.2 }}>{a.label}</span>
                  <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>{a.pct}%</span>
                </div>
              ))}
            </div>
          </div>

          <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: theme.bg, border: `0.5px dashed ${theme.line}` }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
              <Icon name="leaf" size={12} color={theme.moss}/>
              <span style={{ fontSize: 11, color: theme.ink2, fontWeight: 500, letterSpacing: 0.2 }}>RINGKASAN</span>
            </div>
            <div className="ft-serif" style={{ fontSize: 14, color: theme.ink, lineHeight: 1.45 }}>
              {data.allocation.summary}
            </div>
          </div>
        </Card>
      </div>

      {/* Rebalance moves */}
      <div style={{ padding: '18px 22px 0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
          <Eyebrow theme={theme}>Langkah Rebalancing</Eyebrow>
          <Chip color={theme.clay} theme={theme}>3 aksi</Chip>
        </div>
        <Card theme={theme} padded={false}>
          {data.allocation.moves.map((m, i) => (
            <div key={i} style={{
              padding: '14px 16px', borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8, flexWrap: 'wrap' }}>
                <Chip color={theme.danger} theme={theme}>− {m.from}</Chip>
                <Icon name="forward" size={12} color={theme.ink4}/>
                <Chip color={theme.moss} theme={theme}>+ {m.to}</Chip>
                <span className="ft-mono" style={{ marginLeft: 'auto', fontSize: 12, color: theme.ink, fontWeight: 500 }}>
                  {fmtRp(m.amount, { compact: true })}
                </span>
              </div>
              <div style={{ fontSize: 11, color: theme.ink2, lineHeight: 1.4 }}>{m.reason}</div>
            </div>
          ))}
        </Card>
      </div>

      <div style={{ padding: '14px 22px 0', fontSize: 10, color: theme.ink4, textAlign: 'center', lineHeight: 1.4 }}>
        Rekomendasi bersifat indikatif. Bukan saran investasi.
      </div>
    </>
  );
}

window.AssetsScreen = AssetsScreen;
