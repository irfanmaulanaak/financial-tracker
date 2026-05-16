// screens-home.jsx — Home (Dashboard) — Layout A and Layout B variants
// Plus shared header/tab pieces used by other screens.

// ───── Top header (cream paper feel, status-bar safe) ─────
function FTHeader({ theme, user, asset, deltaPct, onProfile, household, onMembers }) {
  return (
    <div style={{ padding: '54px 22px 16px', position: 'relative' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 26 }}>
        <button onClick={onProfile} style={{
          width: 38, height: 38, borderRadius: '50%',
          background: theme.surfaceAlt,
          border: `0.5px solid ${theme.lineStrong}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: "'Newsreader', serif", fontSize: 16, color: theme.ink,
          letterSpacing: 0.5, cursor: 'pointer', flexShrink: 0,
        }}>{user.initials}</button>
        <div style={{ flex: 1, lineHeight: 1.2, minWidth: 0 }}>
          <div style={{ fontSize: 11, color: theme.ink3, letterSpacing: 0.3 }}>
            {household ? household.name : 'Selamat siang,'}
          </div>
          <div className="ft-serif" style={{ fontSize: 17, color: theme.ink, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user.name}</div>
        </div>
        {household && (
          <MemberStack members={household.members} theme={theme} onTap={onMembers} size={26}/>
        )}
        <button style={{
          width: 38, height: 38, borderRadius: '50%',
          border: `0.5px solid ${theme.line}`, color: theme.ink2,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: theme.surface,
        }}><Icon name="bell" size={18} color={theme.ink2}/></button>
      </div>
    </div>
  );
}

// ───── Asset hero (layout A: editorial, large serif) ─────
function AssetHeroA({ theme, asset, onTap }) {
  return (
    <div onClick={onTap} style={{ padding: '0 22px 24px', cursor: onTap ? 'pointer' : 'default' }}>
      <div style={{ fontSize: 11, letterSpacing: 1.4, textTransform: 'uppercase', color: theme.ink3, marginBottom: 10 }}>
        Total Aset
      </div>
      <div className="ft-serif ft-fadeup" style={{
        fontSize: 46, lineHeight: 1, fontWeight: 400, color: theme.ink,
        letterSpacing: -1.5, fontFeatureSettings: '"lnum","tnum"',
      }}>
        {fmtRp(asset.total).replace('Rp ', '')}
        <span className="ft-sans" style={{ fontSize: 16, color: theme.ink3, marginLeft: 8, letterSpacing: 0, fontWeight: 400 }}>IDR</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginTop: 14 }}>
        <span style={{
          display: 'inline-flex', alignItems: 'center', gap: 4,
          color: theme.moss, fontSize: 12, fontWeight: 500,
        }}>
          <Icon name="arrowUp" size={12} color={theme.moss} stroke={2}/>
          {fmtRp(asset.deltaMo, { compact: true })} · +{asset.deltaPct}%
        </span>
        <span style={{ fontSize: 11, color: theme.ink3 }}>vs bulan lalu</span>
      </div>
    </div>
  );
}

// ───── Asset breakdown sub-list ─────
function AssetBreakdown({ theme, asset, onTap }) {
  return (
    <Card theme={theme} padded={false} onClick={onTap} style={{ margin: '0 22px 16px', cursor: onTap ? 'pointer' : 'default' }}>
      {asset.breakdown.map((b, i) => (
        <div key={b.id} style={{
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '14px 18px',
          borderBottom: i < asset.breakdown.length - 1 ? `0.5px solid ${theme.line}` : 'none',
        }}>
          <div>
            <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{b.label}</div>
            <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{b.hint}</div>
          </div>
          <div className="ft-mono" style={{ fontSize: 14, color: theme.ink, fontWeight: 500 }}>
            {fmtRp(b.value, { compact: true })}
          </div>
        </div>
      ))}
    </Card>
  );
}

// ───── Monthly spend strip (vs income) ─────
function MonthStrip({ theme, month, today, onAdd }) {
  const pct = (month.spend / month.income) * 100;
  return (
    <div style={{ padding: '0 22px 16px' }}>
      <Card theme={theme}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 14 }}>
          <div>
            <Eyebrow theme={theme}>Pengeluaran · {month.name}</Eyebrow>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
              <span className="ft-serif" style={{ fontSize: 28, color: theme.ink, letterSpacing: -0.5 }}>
                {fmtRp(month.spend, { compact: true })}
              </span>
              <span style={{ fontSize: 12, color: theme.ink3 }}>
                / {fmtRp(month.income, { compact: true })} pendapatan
              </span>
            </div>
          </div>
          <button onClick={onAdd} style={{
            width: 40, height: 40, borderRadius: '50%',
            background: theme.ink, color: theme.bg,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="plus" size={18} color={theme.bg} stroke={2}/>
          </button>
        </div>
        <Bar value={pct} max={100} color={theme.clay} track={theme.line} height={4}/>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
          <span style={{ fontSize: 11, color: theme.ink3 }}>
            <span className="ft-mono">{Math.round(pct)}%</span> dari pendapatan terpakai
          </span>
          <span style={{ fontSize: 11, color: theme.ink3 }}>
            Hari ini · <span className="ft-mono" style={{ color: theme.ink2 }}>{fmtRp(today.spend, { compact: true })}</span>
          </span>
        </div>
      </Card>
    </div>
  );
}

// ───── Health snapshot ─────
function HealthSnapshot({ theme, health, onTap }) {
  const stateLabel = { good: 'Sehat', caution: 'Perlu perhatian', risk: 'Berisiko' }[health.state];
  const stateColor = { good: theme.healthOk, caution: theme.healthWarn, risk: theme.healthBad }[health.state];
  return (
    <Card theme={theme} onClick={onTap} style={{ margin: '0 22px 16px', cursor: 'pointer' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
        <Ring value={health.score} size={64} thickness={6} color={stateColor} track={theme.line} t={1}/>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Eyebrow theme={theme}>Kesehatan Finansial</Eyebrow>
            <TrafficLight state={health.state} theme={theme} size={7}/>
          </div>
          <div className="ft-serif" style={{ fontSize: 17, color: theme.ink, marginTop: 4, fontWeight: 500 }}>
            {stateLabel} · <span className="ft-mono" style={{ fontSize: 15 }}>{health.score}</span>
          </div>
          <div style={{ fontSize: 12, color: theme.ink2, marginTop: 4, lineHeight: 1.4 }}>
            {health.summary}
          </div>
        </div>
        <Icon name="forward" size={16} color={theme.ink4}/>
      </div>
    </Card>
  );
}

// ───── Goal row preview ─────
function GoalsPreview({ theme, goals, onTap }) {
  return (
    <Card theme={theme} padded={false} onClick={onTap} style={{ margin: '0 22px 16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 18px 10px' }}>
        <Eyebrow theme={theme}>Tujuan Finansial</Eyebrow>
        <span style={{ fontSize: 11, color: theme.ink3 }}>{goals.length} aktif <Icon name="forward" size={10} color={theme.ink4} stroke={2}/></span>
      </div>
      {goals.slice(0, 3).map((g, i) => {
        const pct = (g.current / g.target) * 100;
        return (
          <div key={g.id} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 18px 12px',
            borderTop: `0.5px solid ${theme.line}`,
          }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `${theme[g.tone] || theme.clay}1a`,
              color: theme[g.tone] || theme.clay,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              border: `0.5px solid ${theme[g.tone] || theme.clay}33`,
            }}><Icon name={g.icon} size={18} color={theme[g.tone] || theme.clay}/></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{g.label}</span>
                <span className="ft-mono" style={{ fontSize: 11, color: theme.ink3 }}>
                  {Math.round(pct)}%
                </span>
              </div>
              <div style={{ marginTop: 6 }}>
                <Bar value={pct} max={100} color={theme[g.tone] || theme.clay} track={theme.line} height={3}/>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6 }}>
                <span className="ft-mono" style={{ fontSize: 11, color: theme.ink2 }}>
                  {fmtRp(g.current, { compact: true })} <span style={{ color: theme.ink4 }}>/ {fmtRp(g.target, { compact: true })}</span>
                </span>
                <span style={{ fontSize: 11, color: theme.ink3 }}>{g.due}</span>
              </div>
            </div>
          </div>
        );
      })}
    </Card>
  );
}

// ───── Quick-tap categories grid (Layout A) ─────
function CategoryStripA({ theme, categories, onTap }) {
  const top = categories.slice(0, 4);
  return (
    <div style={{ padding: '0 22px 16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <Eyebrow theme={theme}>Pengeluaran Bulan Ini</Eyebrow>
        <button onClick={onTap} style={{ fontSize: 11, color: theme.ink3, display: 'flex', alignItems: 'center', gap: 2 }}>
          Lihat semua <Icon name="forward" size={10} color={theme.ink3} stroke={2}/>
        </button>
      </div>
      <Card theme={theme}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: 12 }}>
          {top.map(c => {
            const over = c.value > c.budget;
            return (
              <div key={c.id} style={{
                background: theme.surfaceAlt, borderRadius: 12, padding: 12,
                border: `0.5px solid ${theme.line}`,
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                  <div style={{ color: theme[c.color] }}><Icon name={c.icon} size={14} color={theme[c.color]}/></div>
                  <span style={{ fontSize: 11, color: theme.ink2, fontWeight: 500 }}>{c.label}</span>
                </div>
                <div className="ft-mono" style={{ fontSize: 14, color: theme.ink, fontWeight: 500 }}>
                  {fmtRp(c.value, { compact: true })}
                </div>
                <div style={{ marginTop: 8 }}>
                  <Bar value={c.value} max={c.budget} color={theme[c.color]} track={theme.line} height={2.5}
                    overflowColor={theme.danger}/>
                </div>
                <div style={{ fontSize: 10, color: over ? theme.danger : theme.ink3, marginTop: 5 }}>
                  {over ? `+${Math.round(((c.value/c.budget)-1)*100)}% di atas anggaran` : `${Math.round((c.value/c.budget)*100)}% terpakai`}
                </div>
              </div>
            );
          })}
        </div>
      </Card>
    </div>
  );
}

// ───── Recent transactions strip ─────
function RecentList({ theme, expenses, max = 4, onTap, title = 'Aktivitas Terbaru', household }) {
  const items = expenses.slice(0, max);
  return (
    <Card theme={theme} padded={false} style={{ margin: '0 22px 16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 18px 10px' }}>
        <Eyebrow theme={theme}>{title}</Eyebrow>
        {onTap && <button onClick={onTap} style={{ fontSize: 11, color: theme.ink3 }}>Lihat semua →</button>}
      </div>
      {items.map((e, i) => {
        const cat = FT_DATA.categories.find(c => c.id === e.cat);
        return (
          <div key={e.id} style={{
            display: 'flex', alignItems: 'center', gap: 12,
            padding: '12px 18px',
            borderTop: `0.5px solid ${theme.line}`,
          }}>
            <div style={{
              width: 34, height: 34, borderRadius: 10,
              background: `${theme[cat.color]}1a`,
              border: `0.5px solid ${theme[cat.color]}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}><Icon name={cat.icon} size={15} color={theme[cat.color]}/></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{e.label}</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 3 }}>
                <span style={{ fontSize: 11, color: theme.ink3 }}>{e.date} · {e.time}</span>
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
  );
}

// ───── HOME LAYOUT A — Editorial / serif-led ─────
function HomeA({ theme, data, go }) {
  return (
    <div style={{ paddingBottom: 110, background: theme.bg, minHeight: '100%' }}>
      <FTHeader theme={theme} user={data.user} onProfile={() => go('settings')}
        household={data.household} onMembers={() => go('settings')} />
      <AssetHeroA theme={theme} asset={data.assets} onTap={() => go('assets')} />
      <AssetBreakdown theme={theme} asset={data.assets} onTap={() => go('assets')} />
      <MonthStrip theme={theme} month={data.month} today={data.today} onAdd={() => go('add')} />
      <CardsPreview theme={theme} cards={data.cards} onTap={() => go('cards')} />
      <HealthSnapshot theme={theme} health={data.health} onTap={() => go('health')} />
      <CategoryStripA theme={theme} categories={data.categories} onTap={() => go('spend')} />
      <GoalsPreview theme={theme} goals={data.goals} onTap={() => go('goals')} />
      <RecentList theme={theme} expenses={data.expenses} onTap={() => go('expenses')} household={data.household} />
    </div>
  );
}

// ───── HOME LAYOUT B — Compact data-forward (private bank terminal vibe) ─────
function HomeB({ theme, data, go }) {
  const totalSpend = data.month.spend;
  const segments = data.categories.map(c => ({ id: c.id, value: c.value, color: c.color }));

  return (
    <div style={{ paddingBottom: 110, background: theme.bg, minHeight: '100%' }}>
      <FTHeader theme={theme} user={data.user} onProfile={() => go('settings')}
        household={data.household} onMembers={() => go('settings')} />

      {/* dense top: asset + small donut side by side */}
      <div style={{ padding: '0 22px 18px' }}>
        <Card theme={theme} onClick={() => go('assets')}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16 }}>
            <div style={{ flex: 1, minWidth: 0 }}>
              <Eyebrow theme={theme}>Total Aset</Eyebrow>
              <div className="ft-serif ft-fadeup" style={{ fontSize: 30, color: theme.ink, fontWeight: 500, marginTop: 6, letterSpacing: -0.8 }}>
                {fmtRp(data.assets.total, { compact: true })}
              </div>
              <div style={{ marginTop: 6, display: 'flex', gap: 6, alignItems: 'center' }}>
                <Chip color={theme.moss} theme={theme}>↗ +{data.assets.deltaPct}%</Chip>
                <span style={{ fontSize: 11, color: theme.ink3 }}>30 hari</span>
              </div>
              <div style={{ marginTop: 12 }}>
                <Sparkline data={[230,232,231,234,236,235,238,240,244,243,245,247,246,248,248.5]}
                  width={210} height={36} color={theme.moss} fill={theme.moss}/>
              </div>
            </div>
            <Donut segments={segments.slice(0, 5)} size={92} thickness={11}
              theme={theme} t={1} centerLabel="" centerValue=""/>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 16, paddingTop: 14, borderTop: `0.5px dashed ${theme.line}` }}>
            {data.assets.breakdown.map(b => (
              <div key={b.id}>
                <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>{b.label.split(' ')[0]}</div>
                <div className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 3 }}>
                  {fmtRp(b.value, { compact: true })}
                </div>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Spend vs income + health side by side */}
      <div style={{ padding: '0 22px 16px', display: 'grid', gridTemplateColumns: '1.3fr 1fr', gap: 12 }}>
        <Card theme={theme}>
          <Eyebrow theme={theme}>Pengeluaran</Eyebrow>
          <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
            {fmtRp(data.month.spend, { compact: true })}
          </div>
          <div style={{ fontSize: 11, color: theme.ink3, marginBottom: 8 }}>
            dari {fmtRp(data.month.income, { compact: true })} pendapatan
          </div>
          <Bar value={data.month.spend} max={data.month.income} color={theme.clay} track={theme.line} height={3}/>
          <button onClick={() => go('add')} style={{
            marginTop: 12, width: '100%', padding: '8px 0', borderRadius: 999,
            background: theme.ink, color: theme.bg, fontSize: 12, fontWeight: 500,
          }}>+ Catat pengeluaran</button>
        </Card>

        <Card theme={theme} onClick={() => go('health')}>
          <Eyebrow theme={theme}>Kesehatan</Eyebrow>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
            <span className="ft-serif" style={{ fontSize: 26, color: theme.ink, letterSpacing: -0.3 }}>{data.health.score}</span>
            <TrafficLight state={data.health.state} theme={theme} size={6}/>
          </div>
          <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{ {good:'Sehat',caution:'Perhatian',risk:'Berisiko'}[data.health.state] }</div>
          <div style={{ marginTop: 12, fontSize: 10, color: theme.ink2, lineHeight: 1.35 }}>
            {data.health.flags[0].msg}
          </div>
        </Card>
      </div>

      <CategoryStripA theme={theme} categories={data.categories} onTap={() => go('spend')} />
      <CardsPreview theme={theme} cards={data.cards} onTap={() => go('cards')} />
      <GoalsPreview theme={theme} goals={data.goals.slice(0, 2)} onTap={() => go('goals')} />
      <RecentList theme={theme} expenses={data.expenses} max={3} onTap={() => go('expenses')} household={data.household} />
    </div>
  );
}

Object.assign(window, { HomeA, HomeB, FTHeader, RecentList, Card, Bar });
