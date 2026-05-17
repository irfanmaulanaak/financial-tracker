// screens-rest.jsx — Goals, Health detector, Investments, Settings

// ───── GOALS SCREEN ─────
function GoalsScreen({ theme, data, go }) {
  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Tujuan Finansial" onBack={() => go('home')}
        action={<button onClick={() => go('addGoal')} style={{ width: 34, height: 34, borderRadius: '50%', background: theme.ink, color: theme.bg, display:'flex', alignItems:'center', justifyContent:'center' }}><Icon name="plus" size={16} color={theme.bg} stroke={2}/></button>}/>

      <div style={{ padding: '14px 22px 0', display: 'flex', flexDirection: 'column', gap: 12 }}>
        {data.goals.map(g => {
          const pct = (g.current / g.target) * 100;
          const remaining = g.target - g.current;
          const monthsLeft = Math.ceil(remaining / g.monthly);
          const onTrack = pct >= 50 || monthsLeft <= 6;
          return (
            <Card key={g.id} theme={theme} onClick={() => go('goalDetail', g.id)}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 52, height: 52, borderRadius: 14,
                  background: `${theme[g.tone]}1a`, border: `0.5px solid ${theme[g.tone]}33`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><Icon name={g.icon} size={22} color={theme[g.tone]}/></div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span className="ft-serif" style={{ fontSize: 16, color: theme.ink, fontWeight: 500 }}>{g.label}</span>
                    <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>
                      {Math.round(pct)}%
                    </span>
                  </div>
                  <div style={{ marginTop: 8 }}>
                    <Bar value={pct} max={100} color={theme[g.tone]} track={theme.line} height={4}/>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
                    <span className="ft-mono" style={{ fontSize: 11, color: theme.ink2 }}>
                      {fmtRp(g.current, { compact: true })} <span style={{ color: theme.ink4 }}>/ {fmtRp(g.target, { compact: true })}</span>
                    </span>
                    <span style={{ fontSize: 11, color: theme.ink3 }}>
                      {g.due} · {fmtRp(g.monthly, { compact: true })}/bln
                    </span>
                  </div>
                </div>
              </div>
              {!onTrack && (
                <div style={{ marginTop: 10, padding: 10, borderRadius: 8, background: `${theme.ochre}10`, border: `0.5px solid ${theme.ochre}33`, fontSize: 11, color: theme.ink2 }}>
                  <Icon name="info" size={11} color={theme.ochre} style={{ display: 'inline', verticalAlign: 'middle', marginRight: 4 }}/>
                  Naikkan setoran ke {fmtRp(Math.round(remaining/6), { compact: true })}/bln agar tercapai tepat waktu.
                </div>
              )}
            </Card>
          );
        })}
      </div>
    </div>
  );
}

// ───── GOAL DETAIL SCREEN ─────
function GoalDetailScreen({ theme, data, goalId, go }) {
  const g = data.goals.find(x => x.id === goalId) || data.goals[0];
  const pct = (g.current / g.target) * 100;
  const remaining = g.target - g.current;
  const monthsLeft = Math.ceil(remaining / g.monthly);

  // monthly contrib mock
  const contribs = [3.2, 2.8, 4.5, 3.0, 2.5, 4.0, 2.2, 3.5];

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title={g.label} onBack={() => go('goals')}/>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '12px 0' }}>
            <Ring value={pct} max={100} size={140} thickness={10} color={theme[g.tone]} track={theme.line}/>
            <div style={{ marginTop: -100, textAlign: 'center' }}>
              <Eyebrow theme={theme}>Tercapai</Eyebrow>
              <div className="ft-serif" style={{ fontSize: 38, color: theme.ink, letterSpacing: -1, lineHeight: 1, marginTop: 2 }}>{Math.round(pct)}%</div>
              <div className="ft-mono" style={{ fontSize: 11, color: theme.ink3, marginTop: 4 }}>
                {fmtRp(g.current, { compact: true })} / {fmtRp(g.target, { compact: true })}
              </div>
            </div>
            <div style={{ height: 60 }}/>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, paddingTop: 14, borderTop: `0.5px dashed ${theme.line}` }}>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Sisa</div>
              <div className="ft-mono" style={{ fontSize: 14, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{fmtRp(remaining, { compact: true })}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Setoran/bln</div>
              <div className="ft-mono" style={{ fontSize: 14, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{fmtRp(g.monthly, { compact: true })}</div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Target</div>
              <div style={{ fontSize: 14, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{g.due}</div>
            </div>
          </div>
        </Card>
      </div>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <Eyebrow theme={theme} style={{ marginBottom: 12 }}>Setoran 8 Bulan Terakhir</Eyebrow>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 80 }}>
            {contribs.map((v, i) => {
              const h = (v / Math.max(...contribs)) * 70 + 6;
              return (
                <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                  <div style={{ width: '100%', height: h, borderRadius: 4, background: i === contribs.length - 1 ? theme[g.tone] : `${theme[g.tone]}66` }}/>
                  <span style={{ fontSize: 9, color: theme.ink3 }}>{['Okt','Nov','Des','Jan','Feb','Mar','Apr','Mei'][i]}</span>
                </div>
              );
            })}
          </div>
        </Card>
      </div>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <Eyebrow theme={theme} style={{ marginBottom: 10 }}>Proyeksi</Eyebrow>
          <div style={{ fontSize: 13, color: theme.ink2, lineHeight: 1.5 }}>
            Dengan rata-rata setoran {fmtRp(g.monthly, { compact: true })} per bulan, tujuan ini tercapai dalam <span className="ft-serif" style={{ color: theme.ink, fontSize: 16 }}>{monthsLeft} bulan</span>. Anda di jalur yang tepat.
          </div>
        </Card>
      </div>

      <div style={{ padding: '14px 22px 0', display: 'flex', gap: 10 }}>
        <button style={{ flex: 1, padding: '14px 0', borderRadius: 12, background: theme.surface, border: `0.5px solid ${theme.line}`, color: theme.ink, fontSize: 13, fontWeight: 500 }}>Sesuaikan</button>
        <button style={{ flex: 1, padding: '14px 0', borderRadius: 12, background: theme.ink, color: theme.bg, fontSize: 13, fontWeight: 500 }}>+ Setor Sekarang</button>
      </div>
    </div>
  );
}

// ───── HEALTH DETECTOR SCREEN ─────
function HealthScreen({ theme, data, go }) {
  const h = data.health;
  const stateLabel = { good: 'Sehat', caution: 'Perlu Perhatian', risk: 'Berisiko' }[h.state];
  const stateColor = { good: theme.healthOk, caution: theme.healthWarn, risk: theme.healthBad }[h.state];

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Kesehatan Finansial" onBack={() => go('home')}/>

      {/* Hero — big traffic light */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
            {/* vertical traffic light visual */}
            <div style={{
              padding: 10, borderRadius: 18, background: theme.surfaceAlt,
              border: `0.5px solid ${theme.line}`,
              display: 'flex', flexDirection: 'column', gap: 8,
            }}>
              {['good','caution','risk'].map(s => {
                const on = h.state === s;
                const c = { good: theme.healthOk, caution: theme.healthWarn, risk: theme.healthBad }[s];
                return (
                  <div key={s} style={{
                    width: 28, height: 28, borderRadius: '50%',
                    background: on ? c : `${c}22`,
                    boxShadow: on ? `0 0 12px ${c}88, inset 0 1px 3px rgba(255,255,255,0.3)` : 'none',
                    transition: 'all 300ms',
                  }}/>
                );
              })}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <Eyebrow theme={theme}>Status Bulan Ini</Eyebrow>
              <div className="ft-serif" style={{ fontSize: 24, color: stateColor, fontWeight: 500, marginTop: 4, letterSpacing: -0.3 }}>
                {stateLabel}
              </div>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 4 }}>
                <span className="ft-serif" style={{ fontSize: 38, color: theme.ink, letterSpacing: -1, lineHeight: 1 }}>{h.score}</span>
                <span style={{ fontSize: 12, color: theme.ink3 }}>/ 100</span>
              </div>
            </div>
          </div>

          <div style={{ marginTop: 14, padding: 12, borderRadius: 10, background: `${stateColor}10`, border: `0.5px solid ${stateColor}33` }}>
            <div style={{ fontSize: 12, color: theme.ink2, lineHeight: 1.55 }}>
              {h.summary}
            </div>
          </div>
        </Card>
      </div>

      {/* Factor breakdown */}
      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Komponen Skor</Eyebrow>
        <Card theme={theme} padded={false}>
          {h.factors.map((f, i) => {
            const c = { good: theme.healthOk, caution: theme.healthWarn, risk: theme.healthBad }[f.state];
            return (
              <div key={f.id} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
                borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              }}>
                <Ring value={f.score} size={42} thickness={4} color={c} track={theme.line}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{f.label}</span>
                    <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>{f.score}</span>
                  </div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2, lineHeight: 1.4 }}>{f.note}</div>
                </div>
                <div style={{ fontSize: 10, color: theme.ink4 }}>{f.weight}%</div>
              </div>
            );
          })}
        </Card>
      </div>

      {/* Flagged categories — breakdown leading into category detail */}
      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Temuan Pengeluaran</Eyebrow>
        <Card theme={theme} padded={false}>
          {h.flags.map((f, i) => {
            const pos = f.delta > 0;
            const c = pos ? (f.delta > 20 ? theme.danger : theme.ochre) : theme.healthOk;
            const cat = data.categories.find(x => x.label.toLowerCase().startsWith(f.cat.toLowerCase().slice(0, 4)));
            return (
              <button key={i}
                onClick={() => cat && go('category', cat.id)}
                style={{
                  width: '100%', textAlign: 'left',
                  display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
                  borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
                }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: `${c}1a`, border: `0.5px solid ${c}33`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name={pos ? 'arrowUp' : 'arrowDown'} size={16} color={c} stroke={2}/>
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                    <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{f.cat}</span>
                    <span className="ft-mono" style={{ fontSize: 12, color: c, fontWeight: 500 }}>
                      {pos ? '+' : ''}{f.delta}%
                    </span>
                  </div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2, lineHeight: 1.4 }}>{f.msg}</div>
                </div>
                <Icon name="forward" size={14} color={theme.ink4}/>
              </button>
            );
          })}
        </Card>
      </div>

      {/* Suggested actions */}
      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Rekomendasi</Eyebrow>
        <Card theme={theme} padded={false}>
          {[
            { icon: 'leaf', label: 'Tetapkan ulang anggaran Belanja', detail: 'Kurangi Rp 200rb · alokasi ulang ke Dana Darurat' },
            { icon: 'pulse', label: 'Tinjau langganan aktif', detail: '5 langganan · Rp 320rb/bln' },
            { icon: 'pie', label: 'Lihat rekomendasi investasi', detail: 'Diversifikasi global', onTap: () => go('invest') },
          ].map((r, i) => (
            <button key={i} onClick={r.onTap}
              style={{
                width: '100%', textAlign: 'left',
                display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
                borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              }}>
              <div style={{
                width: 32, height: 32, borderRadius: 10,
                background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><Icon name={r.icon} size={16} color={theme.ink2}/></div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{r.label}</div>
                <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{r.detail}</div>
              </div>
              <Icon name="forward" size={14} color={theme.ink4}/>
            </button>
          ))}
        </Card>
      </div>
    </div>
  );
}

// ───── INVESTMENT RECOMMENDATIONS SCREEN ─────
function InvestScreen({ theme, data, go }) {
  const [view, setView] = React.useState('target'); // 'current' | 'target'
  const alloc = view === 'target' ? data.allocation.target : data.allocation.current;
  const segments = alloc.map(a => ({ id: a.label, value: a.pct, color: a.color }));

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Rekomendasi Investasi" onBack={() => go('home')}/>

      {/* Market context */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme} style={{ background: theme.surfaceAlt }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <Icon name="sparkle" size={14} color={theme.clay}/>
            <Eyebrow theme={theme}>Kondisi Global</Eyebrow>
            <span style={{ fontSize: 10, color: theme.ink4, marginLeft: 'auto' }}>{data.allocation.asOf}</span>
          </div>
          <div className="ft-serif" style={{ fontSize: 15, color: theme.ink, lineHeight: 1.4, fontWeight: 400 }}>
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
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
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

      <div style={{ padding: '18px 22px 0', display: 'flex', gap: 10 }}>
        <button style={{ flex: 1, padding: '14px 0', borderRadius: 12, background: theme.surface, border: `0.5px solid ${theme.line}`, color: theme.ink, fontSize: 13, fontWeight: 500 }}>Simpan Rencana</button>
        <button style={{ flex: 1, padding: '14px 0', borderRadius: 12, background: theme.ink, color: theme.bg, fontSize: 13, fontWeight: 500 }}>Mulai Rebalancing</button>
      </div>

      <div style={{ padding: '14px 22px 0', fontSize: 10, color: theme.ink4, textAlign: 'center', lineHeight: 1.4 }}>
        Rekomendasi bersifat indikatif. Bukan saran investasi.<br/>
        Konsultasi dengan penasihat sebelum mengambil keputusan.
      </div>
    </div>
  );
}

// ───── SETTINGS / PROFILE SCREEN ─────
function SettingsScreen({ theme, data, go, themeName, onSetTheme, onInviteMember, onToggleShared, sharedWallet, onMember, onEdit }) {
  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Profil" onBack={() => go('home')}/>

      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <button onClick={onEdit} style={{
              width: 56, height: 56, borderRadius: '50%',
              background: theme[data.user.color || 'clay'], color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontFamily: "'Newsreader', serif", fontSize: 22, fontWeight: 500, letterSpacing: 0.5,
              cursor: 'pointer',
            }}>{data.user.initials}</button>
            <div style={{ flex: 1 }}>
              <div className="ft-serif" style={{ fontSize: 18, color: theme.ink, fontWeight: 500 }}>{data.user.name}</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{data.user.memberSince}</div>
            </div>
            <button onClick={onEdit} style={{
              padding: '7px 12px', borderRadius: 999,
              background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
              color: theme.clay, fontSize: 12, fontWeight: 500,
              display: 'inline-flex', alignItems: 'center', gap: 4,
            }}>Edit</button>
          </div>
        </Card>
      </div>

      {data.household && (
        <MembersSection
          theme={theme}
          household={{ ...data.household, sharedWallet }}
          onInvite={onInviteMember}
          onMember={onMember}
          sharedWallet={sharedWallet}
          onToggleShared={onToggleShared}/>
      )}

      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Tampilan</Eyebrow>
        <Card theme={theme} padded={false}>
          <div style={{ padding: '14px 16px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
              <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>Tema</span>
              <span style={{ fontSize: 11, color: theme.ink3 }}>{themeName === 'dark' ? 'Gelap' : 'Terang'}</span>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              {['light','dark'].map(t => (
                <button key={t} onClick={() => onSetTheme(t)} style={{
                  flex: 1, padding: '10px 0', borderRadius: 10, fontSize: 12, fontWeight: 500,
                  background: themeName === t ? theme.ink : theme.surfaceAlt,
                  color: themeName === t ? theme.bg : theme.ink2,
                  border: `0.5px solid ${themeName === t ? theme.ink : theme.line}`,
                }}>{t === 'dark' ? 'Gelap' : 'Terang'}</button>
              ))}
            </div>
          </div>
        </Card>
      </div>

      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Akun & Keamanan</Eyebrow>
        <Card theme={theme} padded={false}>
          {[
            { label: 'Mata uang', detail: 'IDR · Rupiah' },
            { label: 'Akun bank terhubung', detail: '3 akun' },
            { label: 'Anggaran bulanan', detail: fmtRp(data.month.budget, { compact: true }) },
            { label: 'Pemberitahuan', detail: 'Aktif' },
            { label: 'Privasi & data', detail: '' },
            { label: 'Bantuan & dukungan', detail: '' },
          ].map((row, i) => (
            <div key={row.label} style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              padding: '14px 16px',
              borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
            }}>
              <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{row.label}</span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: theme.ink3 }}>
                {row.detail}
                <Icon name="forward" size={12} color={theme.ink4}/>
              </span>
            </div>
          ))}
        </Card>
      </div>

      <div style={{ padding: '18px 22px 0' }}>
        <button style={{ width: '100%', padding: '14px 0', borderRadius: 12, background: theme.surface, border: `0.5px solid ${theme.line}`, color: theme.danger, fontSize: 13, fontWeight: 500 }}>
          Keluar
        </button>
      </div>
    </div>
  );
}

window.GoalsScreen = GoalsScreen;
window.GoalDetailScreen = GoalDetailScreen;
window.HealthScreen = HealthScreen;
window.InvestScreen = InvestScreen;
window.SettingsScreen = SettingsScreen;
