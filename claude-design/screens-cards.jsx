// screens-cards.jsx — credit-card debt overview + per-card detail
// Also exports CardsPreview (a card for the Home dashboard).

// ───── HOME: cards preview card ─────
function CardsPreview({ theme, cards, onTap }) {
  const totalUsed = cards.reduce((s, c) => s + c.used, 0);
  const totalLimit = cards.reduce((s, c) => s + c.limit, 0);
  const totalMin = cards.reduce((s, c) => s + c.minPayment, 0);
  const totalAccum = cards.reduce((s, c) => s + (c.accumulatedMo || 0), 0);
  const soonest = cards.reduce((m, c) => !m || c.dueDate < m.dueDate ? c : m, null);

  return (
    <Card theme={theme} onClick={onTap} style={{ margin: '0 22px 16px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
        <Eyebrow theme={theme}>Kartu Kredit · Utang</Eyebrow>
        <Chip color={theme.plum} theme={theme}>+{fmtRp(totalAccum, { compact: true })} bulan ini</Chip>
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
        <span className="ft-serif" style={{ fontSize: 26, color: theme.ink, letterSpacing: -0.4 }}>
          {fmtRp(totalUsed, { compact: true })}
        </span>
        <span style={{ fontSize: 12, color: theme.ink3 }}>akumulasi tagihan</span>
      </div>

      <div style={{ marginTop: 12, display: 'flex', gap: 4 }}>
        {cards.map(c => {
          const w = (c.limit / totalLimit) * 100;
          const u = (c.used / c.limit) * 100;
          return (
            <div key={c.id} style={{
              flex: w, height: 6, borderRadius: 4, background: theme.line, overflow: 'hidden',
            }}>
              <div style={{ width: `${u}%`, height: '100%', background: theme[c.accent] }}/>
            </div>
          );
        })}
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 12, paddingTop: 12, borderTop: `0.5px dashed ${theme.line}` }}>
        <div>
          <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Jatuh tempo terdekat</div>
          <div style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 2 }}>
            {soonest.dueDate} · <span style={{ color: theme.ink3, fontWeight: 400 }}>{soonest.label.split(' ')[0]}</span>
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Min. bayar total</div>
          <div className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 2 }}>
            {fmtRp(totalMin, { compact: true })}
          </div>
        </div>
      </div>
    </Card>
  );
}

// ───── CARDS SCREEN — all credit cards + installments ─────
function CardsScreen({ theme, data, go }) {
  const cards = data.cards;
  const totalUsed = cards.reduce((s, c) => s + c.used, 0);
  const totalLimit = cards.reduce((s, c) => s + c.limit, 0);
  const totalMin = cards.reduce((s, c) => s + c.minPayment, 0);
  const totalAccum = cards.reduce((s, c) => s + (c.accumulatedMo || 0), 0);
  const totalMonthly = cards.reduce((s, c) => s + c.installments.reduce((a, i) => a + i.monthly, 0), 0);

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Utang & Kartu Kredit" onBack={() => go('home')}/>

      {/* hero */}
      <div style={{ padding: '14px 22px 0' }}>
        <Card theme={theme}>
          <Eyebrow theme={theme}>Akumulasi Tagihan</Eyebrow>
          <div className="ft-serif ft-fadeup" style={{ fontSize: 36, color: theme.ink, letterSpacing: -1, marginTop: 4, lineHeight: 1 }}>
            {fmtRp(totalUsed, { compact: true })}
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginTop: 8 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, color: theme.plum, fontSize: 12, fontWeight: 500 }}>
              <Icon name="arrowUp" size={12} color={theme.plum} stroke={2}/>
              {fmtRp(totalAccum, { compact: true })}
            </span>
            <span style={{ fontSize: 11, color: theme.ink3 }}>terakumulasi bulan ini</span>
          </div>

          <div style={{ marginTop: 14 }}>
            <Bar value={totalUsed} max={totalLimit} color={theme.plum} track={theme.line} height={6}/>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 10, marginTop: 16, paddingTop: 14, borderTop: `0.5px dashed ${theme.line}` }}>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Min. bayar</div>
              <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500, marginTop: 3 }}>
                {fmtRp(totalMin, { compact: true })}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Cicilan/bln</div>
              <div className="ft-mono" style={{ fontSize: 13, color: theme.ink, fontWeight: 500, marginTop: 3 }}>
                {fmtRp(totalMonthly, { compact: true })}
              </div>
            </div>
            <div>
              <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Beban utang</div>
              <div style={{ marginTop: 4 }}>
                <TrafficLight state={totalUsed / data.month.income > 0.4 ? 'caution' : 'good'} theme={theme} size={6}/>
              </div>
            </div>
          </div>
        </Card>
      </div>

      {/* per-card list */}
      <div style={{ padding: '18px 22px 0' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Kartu Aktif</Eyebrow>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {cards.map(c => {
            const u = (c.used / c.limit) * 100;
            const accent = theme[c.accent];
            const ciclanMonthly = c.installments.reduce((s, i) => s + i.monthly, 0);
            return (
              <Card key={c.id} theme={theme} padded={false}>
                {/* card visual */}
                <div style={{
                  margin: 14, padding: 16, borderRadius: 14,
                  background: `linear-gradient(135deg, ${accent} 0%, ${theme[c.accent === 'plum' ? 'sky' : 'plum']} 100%)`,
                  color: '#fff', position: 'relative', overflow: 'hidden',
                  minHeight: 130,
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div>
                      <div style={{ fontSize: 10, opacity: 0.7, letterSpacing: 1.2, textTransform: 'uppercase' }}>{c.label}</div>
                      <div className="ft-mono" style={{ fontSize: 14, marginTop: 6, letterSpacing: 2 }}>•••• {c.last4}</div>
                    </div>
                    <Icon name="bank" size={20} color="#fff"/>
                  </div>
                  <div style={{ position: 'absolute', bottom: 14, left: 16, right: 16 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
                      <span className="ft-serif" style={{ fontSize: 20, letterSpacing: -0.3 }}>
                        {fmtRp(c.used, { compact: true })}
                      </span>
                      <span style={{ fontSize: 10, opacity: 0.8 }}>dari {fmtRp(c.limit, { compact: true })}</span>
                    </div>
                    <div style={{ height: 3, background: 'rgba(255,255,255,0.25)', borderRadius: 2, overflow: 'hidden' }}>
                      <div style={{ width: `${u}%`, height: '100%', background: '#fff' }}/>
                    </div>
                  </div>
                </div>

                {/* details row */}
                <div style={{
                  display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 4,
                  padding: '0 16px 14px',
                }}>
                  <div>
                    <div style={{ fontSize: 10, color: theme.ink3 }}>Jatuh tempo</div>
                    <div style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{c.dueDate}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: 10, color: theme.ink3 }}>Min. bayar</div>
                    <div className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{fmtRp(c.minPayment, { compact: true })}</div>
                  </div>
                  <div>
                    <div style={{ fontSize: 10, color: theme.ink3 }}>Bunga</div>
                    <div className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500, marginTop: 3 }}>{c.apr}%</div>
                  </div>
                </div>

                {/* installments */}
                {c.installments.length > 0 && (
                  <div style={{ borderTop: `0.5px solid ${theme.line}`, padding: '12px 16px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                      <span style={{ fontSize: 11, color: theme.ink3, letterSpacing: 1, textTransform: 'uppercase', fontWeight: 500 }}>
                        Cicilan Aktif
                      </span>
                      <span className="ft-mono" style={{ fontSize: 11, color: theme.ink2 }}>
                        {fmtRp(ciclanMonthly, { compact: true })}/bln
                      </span>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                      {c.installments.map(i => {
                        const pct = (i.monthsPaid / i.monthsTotal) * 100;
                        return (
                          <div key={i.id}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                              <span style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>{i.label}</span>
                              <span className="ft-mono" style={{ fontSize: 11, color: theme.ink3 }}>
                                {i.monthsPaid}/{i.monthsTotal} ×
                              </span>
                            </div>
                            <div style={{ marginTop: 6 }}>
                              <Bar value={pct} max={100} color={accent} track={theme.line} height={2.5}/>
                            </div>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 5 }}>
                              <span className="ft-mono" style={{ fontSize: 10, color: theme.ink3 }}>
                                {fmtRp(i.monthly, { compact: true })}/bln
                              </span>
                              <span style={{ fontSize: 10, color: theme.ink3 }}>
                                Sisa {fmtRp(i.monthly * (i.monthsTotal - i.monthsPaid), { compact: true })}
                              </span>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {/* actions */}
                <div style={{ display: 'flex', gap: 8, padding: '12px 16px 16px', borderTop: `0.5px solid ${theme.line}` }}>
                  <button style={{ flex: 1, padding: '10px 0', borderRadius: 10, background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`, color: theme.ink, fontSize: 12, fontWeight: 500 }}>Bayar minimum</button>
                  <button style={{ flex: 1, padding: '10px 0', borderRadius: 10, background: theme.ink, color: theme.bg, fontSize: 12, fontWeight: 500 }}>Bayar penuh</button>
                </div>
              </Card>
            );
          })}
        </div>
      </div>

      {/* tips */}
      <div style={{ padding: '18px 22px 0' }}>
        <Card theme={theme} style={{ background: theme.surfaceAlt }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 6 }}>
            <Icon name="sparkle" size={14} color={theme.clay}/>
            <Eyebrow theme={theme}>Saran</Eyebrow>
          </div>
          <div className="ft-serif" style={{ fontSize: 14, color: theme.ink, lineHeight: 1.5 }}>
            Total cicilan bulanan mencapai {fmtRp(totalMonthly, { compact: true })} ({Math.round((totalMonthly/data.month.income)*100)}% dari pendapatan). Idealnya di bawah 30% — pertimbangkan untuk menyelesaikan cicilan iPhone lebih awal.
          </div>
        </Card>
      </div>
    </div>
  );
}

window.CardsPreview = CardsPreview;
window.CardsScreen = CardsScreen;
