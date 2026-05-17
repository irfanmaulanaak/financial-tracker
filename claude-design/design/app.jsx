// app.jsx — main app: tab bar, router, tweaks, design canvas layout.

// ───── Bottom tab bar (floating glass pill) ─────
function TabBar({ theme, route, go }) {
  const tabs = [
    { id: 'home', icon: 'home', label: 'Beranda' },
    { id: 'spend', icon: 'chart', label: 'Pengeluaran' },
    { id: 'assets', icon: 'pie', label: 'Aset' },
    { id: 'goals', icon: 'target', label: 'Tujuan' },
    { id: 'cards', icon: 'bank', label: 'Utang' },
  ];

  const active = ['home','spend','assets','goals','cards'].includes(route)
    ? route
    : (route === 'category' ? 'spend' : route === 'goalDetail' ? 'goals' : route === 'expenses' ? 'home' : route === 'health' ? 'home' : route === 'settings' ? 'home' : route === 'invest' ? 'assets' : 'home');

  return (
    <div style={{
      position: 'absolute', left: 12, right: 12, bottom: 22, zIndex: 60,
      borderRadius: 28, padding: 6,
      background: theme.name === 'dark' ? 'rgba(36,32,26,0.85)' : 'rgba(251,248,241,0.85)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      border: `0.5px solid ${theme.lineStrong}`,
      boxShadow: theme.name === 'dark'
        ? '0 8px 24px rgba(0,0,0,0.4), 0 0 0 0.5px rgba(255,255,255,0.06)'
        : '0 8px 24px rgba(0,0,0,0.08), 0 1px 0 rgba(255,255,255,0.6) inset',
      display: 'flex',
    }}>
      {tabs.map(t => {
        const on = active === t.id;
        return (
          <button key={t.id} onClick={() => go(t.id)} style={{
            flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
            gap: 2, padding: '8px 0', borderRadius: 22,
            background: on ? (theme.name === 'dark' ? theme.surface : theme.bg) : 'transparent',
            color: on ? theme.ink : theme.ink3,
            transition: 'all 200ms',
          }}>
            <Icon name={t.icon} size={20} color={on ? theme.ink : theme.ink3} stroke={on ? 1.8 : 1.4}/>
            <span style={{ fontSize: 9.5, fontWeight: on ? 600 : 500, letterSpacing: 0.2 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ───── App router ─────
function FinancialApp({ initialRoute = 'home', initialTheme = 'light', interactive = true, frameOnly = false }) {
  const [themeName, setThemeName] = React.useState(initialTheme);
  const [route, setRoute] = React.useState(initialRoute);
  const [routeParam, setRouteParam] = React.useState(null);
  const [extraExpenses, setExtraExpenses] = React.useState([]);
  const [cardDebt, setCardDebt] = React.useState({}); // { cardId: extraAmount }
  const [extraInstallments, setExtraInstallments] = React.useState({}); // { cardId: [{...}] }
  const theme = FT_THEMES[themeName];

  function go(r, param) {
    if (!interactive) return;
    setRoute(r);
    setRouteParam(param);
  }

  function commitExpense({ amount, cat, note, method, payType, cardId, planId }) {
    const cd = FT_DATA.categories.find(c => c.id === cat);
    setExtraExpenses(prev => [{
      id: Date.now(),
      date: '16 Mei',
      time: new Date().toTimeString().slice(0,5),
      cat, label: note || cd.label, amount, method,
    }, ...prev]);
    if (payType === 'credit' && cardId) {
      setCardDebt(prev => ({ ...prev, [cardId]: (prev[cardId] || 0) + amount }));
      const plan = FT_DATA.installmentPlans.find(p => p.id === planId);
      if (plan && plan.months > 1) {
        const monthly = Math.round((amount * (1 + plan.apr/100 * plan.months / 12)) / plan.months);
        setExtraInstallments(prev => ({
          ...prev,
          [cardId]: [
            { id: 'live-' + Date.now(), label: note || cd.label, total: amount, monthly, monthsTotal: plan.months, monthsPaid: 0, started: 'Mei 2026' },
            ...(prev[cardId] || []),
          ],
        }));
      }
    }
  }

  // merged data including new expenses + card debt updates
  const data = React.useMemo(() => {
    const merged = { ...FT_DATA };
    merged.expenses = [...extraExpenses, ...FT_DATA.expenses];
    if (extraExpenses.length) {
      const extra = extraExpenses.reduce((s, e) => s + e.amount, 0);
      merged.month = { ...FT_DATA.month, spend: FT_DATA.month.spend + extra };
      merged.today = { ...FT_DATA.today, spend: FT_DATA.today.spend + extra, txnCount: FT_DATA.today.txnCount + extraExpenses.length };
    }
    if (Object.keys(cardDebt).length || Object.keys(extraInstallments).length) {
      merged.cards = FT_DATA.cards.map(c => ({
        ...c,
        used: c.used + (cardDebt[c.id] || 0),
        installments: [...(extraInstallments[c.id] || []), ...c.installments],
      }));
    }
    return merged;
  }, [extraExpenses, cardDebt, extraInstallments]);

  let screen;
  if (route === 'home')    screen = <Home theme={theme} data={data} go={go}/>;
  else if (route === 'add')        screen = <AddExpenseScreen theme={theme} data={data} go={go} onCommit={commitExpense}/>;
  else if (route === 'expenses')   screen = <ExpensesScreen theme={theme} data={data} go={go} extraExpenses={extraExpenses}/>;
  else if (route === 'spend')      screen = <SpendScreen theme={theme} data={data} go={go}/>;
  else if (route === 'category')   screen = <CategoryScreen theme={theme} data={data} catId={routeParam} go={go}/>;
  else if (route === 'goals')      screen = <GoalsScreen theme={theme} data={data} go={go}/>;
  else if (route === 'goalDetail') screen = <GoalDetailScreen theme={theme} data={data} goalId={routeParam} go={go}/>;
  else if (route === 'health')     screen = <HealthScreen theme={theme} data={data} go={go}/>;
  else if (route === 'invest' || route === 'assets') screen = <AssetsScreen theme={theme} data={data} go={go}/>;
  else if (route === 'cards')      screen = <CardsScreen theme={theme} data={data} go={go}/>;
  else if (route === 'settings')   screen = <SettingsScreen theme={theme} data={data} go={go}
                                       themeName={themeName} onSetTheme={setThemeName}/>;
  else screen = <Home theme={theme} data={data} go={go}/>;

  const body = (
    <div className="ft" style={{
      background: theme.bg, color: theme.ink,
      height: '100%', position: 'relative', overflow: 'hidden',
    }}>
      <div style={{ height: '100%', overflow: 'auto' }} className="ft-scroll">
        {screen}
      </div>
      {route !== 'add' && <TabBar theme={theme} route={route} go={go}/>}
    </div>
  );

  return (
    <IOSDevice dark={themeName === 'dark'} width={402} height={874}>
      {body}
    </IOSDevice>
  );
}

// ───── Tweaks panel (live prototype) ─────
function FinancialAppWithTweaks() {
  const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
    "themeName": "light"
  }/*EDITMODE-END*/;

  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);
  const [route, setRoute] = React.useState('home');
  const [routeParam, setRouteParam] = React.useState(null);
  const [extraExpenses, setExtraExpenses] = React.useState([]);
  const [extraIncomes, setExtraIncomes] = React.useState([]);
  const [extraGoals, setExtraGoals] = React.useState([]);
  const [cardDebt, setCardDebt] = React.useState({});
  const [cardPaid, setCardPaid] = React.useState({});
  const [extraInstallments, setExtraInstallments] = React.useState({});
  const [assetOverrides, setAssetOverrides] = React.useState({}); // { [kind:id]: newValue }
  const [chooserOpen, setChooserOpen] = React.useState(false);
  const [editAsset, setEditAsset] = React.useState(null);   // { item, kind }
  const [inviteOpen, setInviteOpen] = React.useState(false);
  const [extraMembers, setExtraMembers] = React.useState([]);
  const [sharedWallet, setSharedWallet] = React.useState(true);
  const [payCard, setPayCard] = React.useState(null);
  const [removedMembers, setRemovedMembers] = React.useState([]);
  const [userOverride, setUserOverride] = React.useState(null);

  const theme = FT_THEMES[t.themeName];

  // Intercept 'add' → open chooser; addCredit → expense w/ credit preset; everything else routes normally.
  function go(r, param) {
    if (r === 'add') { setChooserOpen(true); return; }
    if (r === 'addCredit') { setChooserOpen(false); setRoute('addExpense'); setRouteParam('credit'); return; }
    setChooserOpen(false);
    setRoute(r);
    setRouteParam(param);
  }
  // Chooser uses this to bypass the intercept.
  function goDirect(r, param) {
    setChooserOpen(false);
    setRoute(r);
    setRouteParam(param);
  }

  function commitExpense({ amount, cat, note, method, payType, cardId, planId }) {
    const cd = FT_DATA.categories.find(c => c.id === cat);
    setExtraExpenses(prev => [{
      id: Date.now(), date: '16 Mei', time: new Date().toTimeString().slice(0,5),
      cat, label: note || cd.label, amount, method,
    }, ...prev]);
    if (payType === 'credit' && cardId) {
      setCardDebt(prev => ({ ...prev, [cardId]: (prev[cardId] || 0) + amount }));
      const plan = FT_DATA.installmentPlans.find(p => p.id === planId);
      if (plan && plan.months > 1) {
        const monthly = Math.round((amount * (1 + plan.apr/100 * plan.months / 12)) / plan.months);
        setExtraInstallments(prev => ({
          ...prev,
          [cardId]: [
            { id: 'live-' + Date.now(), label: note || cd.label, total: amount, monthly, monthsTotal: plan.months, monthsPaid: 0, started: 'Mei 2026' },
            ...(prev[cardId] || []),
          ],
        }));
      }
    }
  }

  function commitIncome({ amount, source, account, note, label, recurring }) {
    setExtraIncomes(prev => [{
      id: Date.now(), date: '16 Mei', time: new Date().toTimeString().slice(0,5),
      source, label, amount, account, recurring,
    }, ...prev]);
    // bump destination cash account
    const key = `cash:${account}`;
    const acc = FT_DATA.cashAccounts.find(a => a.id === account);
    const current = assetOverrides[key] ?? acc.value;
    setAssetOverrides(prev => ({ ...prev, [key]: current + amount }));
  }

  function handleSaveAsset(id, newValue, kind) {
    setAssetOverrides(prev => ({ ...prev, [`${kind}:${id}`]: newValue }));
  }

  function commitGoal(g) {
    setExtraGoals(prev => [...prev, { id: 'g-' + Date.now(), ...g }]);
  }

  function handlePayCard(cardId, amount) {
    setCardPaid(prev => ({ ...prev, [cardId]: (prev[cardId] || 0) + amount }));
  }

  function handleKickOrCancel(memberId) {
    setRemovedMembers(prev => [...prev, memberId]);
  }

  function handleSaveUser(u) {
    setUserOverride(u);
  }

  function handleInvite({ name, contact, role }) {
    const initials = name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();
    const colors = ['moss', 'plum', 'sky', 'clay', 'ochre'];
    setExtraMembers(prev => [...prev, {
      id: 'm-' + Date.now(),
      name, initials, role, status: 'pending',
      color: colors[prev.length % colors.length],
      joinedAt: 'Baru saja',
    }]);
  }

  const data = React.useMemo(() => {
    const merged = { ...FT_DATA };
    merged.expenses = [...extraExpenses, ...FT_DATA.expenses];
    merged.incomes = [...extraIncomes, ...FT_DATA.incomes];

    const extraSpend = extraExpenses.reduce((s, e) => s + e.amount, 0);
    const extraIncome = extraIncomes.reduce((s, i) => s + i.amount, 0);
    merged.month = {
      ...FT_DATA.month,
      spend: FT_DATA.month.spend + extraSpend,
      income: FT_DATA.month.income + extraIncome,
    };
    merged.today = {
      ...FT_DATA.today,
      spend: FT_DATA.today.spend + extraSpend,
      txnCount: FT_DATA.today.txnCount + extraExpenses.length,
    };

    if (Object.keys(cardDebt).length || Object.keys(cardPaid).length || Object.keys(extraInstallments).length) {
      merged.cards = FT_DATA.cards.map(c => ({
        ...c,
        used: Math.max(0, c.used + (cardDebt[c.id] || 0) - (cardPaid[c.id] || 0)),
        installments: [...(extraInstallments[c.id] || []), ...c.installments],
      }));
    }

    // apply asset overrides per-account
    const applyOverride = (list, kind) => list.map(it => {
      const k = `${kind}:${it.id}`;
      return k in assetOverrides ? { ...it, value: assetOverrides[k] } : it;
    });
    merged.cashAccounts = applyOverride(FT_DATA.cashAccounts, 'cash');
    merged.savingsAccounts = applyOverride(FT_DATA.savingsAccounts, 'savings');
    merged.investments = applyOverride(FT_DATA.investments, 'inv');

    // recompute totals
    const cashTotal = merged.cashAccounts.reduce((s, a) => s + a.value, 0);
    const savingsTotal = merged.savingsAccounts.reduce((s, a) => s + a.value, 0);
    const invTotal = merged.investments.reduce((s, a) => s + a.value, 0);
    const newTotal = cashTotal + savingsTotal + invTotal;
    const origTotal = FT_DATA.assets.total;
    merged.assets = {
      ...FT_DATA.assets,
      total: newTotal,
      deltaMo: FT_DATA.assets.deltaMo + (newTotal - origTotal),
      breakdown: [
        { ...FT_DATA.assets.breakdown.find(b => b.id === 'cash'),    value: cashTotal },
        { ...FT_DATA.assets.breakdown.find(b => b.id === 'savings'), value: savingsTotal },
        { ...FT_DATA.assets.breakdown.find(b => b.id === 'inv'),     value: invTotal },
      ],
    };

    merged.goals = [...extraGoals, ...FT_DATA.goals];

    return merged;
  }, [extraExpenses, extraIncomes, extraGoals, cardDebt, cardPaid, extraInstallments, assetOverrides]);

  // merge in invited members + drop kicked/cancelled + apply user override
  const dataWithMembers = React.useMemo(() => {
    const baseUser = userOverride ? { ...data.user, ...userOverride } : data.user;
    const baseMembers = [...data.household.members, ...extraMembers]
      .filter(m => !removedMembers.includes(m.id))
      .map(m => m.isMe && userOverride ? { ...m, name: userOverride.name, initials: userOverride.initials, color: userOverride.color, email: userOverride.email, phone: userOverride.phone } : m);
    return {
      ...data,
      user: baseUser,
      household: {
        ...data.household,
        sharedWallet,
        members: baseMembers,
      },
    };
  }, [data, extraMembers, sharedWallet, removedMembers, userOverride]);

  let screen;
  if (route === 'home')    screen = <Home theme={theme} data={dataWithMembers} go={go}/>;
  else if (route === 'addExpense') screen = <AddExpenseScreen theme={theme} data={dataWithMembers} go={goDirect} onCommit={commitExpense} initialPayType={routeParam === 'credit' ? 'credit' : 'cash'}/>;
  else if (route === 'addIncome')  screen = <AddIncomeScreen  theme={theme} data={dataWithMembers} go={goDirect} onCommit={commitIncome}/>;
  else if (route === 'addGoal')    screen = <AddGoalScreen    theme={theme} data={dataWithMembers} go={goDirect} onCommit={commitGoal}/>;
  else if (route === 'expenses')   screen = <ExpensesScreen theme={theme} data={dataWithMembers} go={go} extraExpenses={extraExpenses}/>;
  else if (route === 'spend')      screen = <SpendScreen theme={theme} data={dataWithMembers} go={go}/>;
  else if (route === 'category')   screen = <CategoryScreen theme={theme} data={dataWithMembers} catId={routeParam} go={go}/>;
  else if (route === 'goals')      screen = <GoalsScreen theme={theme} data={dataWithMembers} go={go}/>;
  else if (route === 'goalDetail') screen = <GoalDetailScreen theme={theme} data={dataWithMembers} goalId={routeParam} go={go}/>;
  else if (route === 'health')     screen = <HealthScreen theme={theme} data={dataWithMembers} go={go}/>;
  else if (route === 'notifications') screen = <NotificationsScreen theme={theme} data={dataWithMembers} go={go}/>;
  else if (route === 'editProfile') screen = <EditProfileScreen theme={theme} data={dataWithMembers} go={goDirect} onSave={handleSaveUser}/>;
  else if (route === 'memberDetail') screen = <MemberDetailScreen theme={theme} data={dataWithMembers} memberId={routeParam} go={goDirect}
                                       onKick={handleKickOrCancel}
                                       onCancelInvite={handleKickOrCancel}
                                       onResend={() => {}}/>;
  else if (route === 'invest' || route === 'assets') screen = <AssetsScreen theme={theme} data={dataWithMembers} go={go} onEditAsset={(item, kind) => setEditAsset({ item, kind })}/>;
  else if (route === 'cards')      screen = <CardsScreen theme={theme} data={dataWithMembers} go={go} onPay={(c) => setPayCard({ card: c })}/>;
  else if (route === 'settings')   screen = <SettingsScreen theme={theme} data={dataWithMembers} go={go}
                                       themeName={t.themeName} onSetTheme={v => setTweak('themeName', v)}
                                       onInviteMember={() => setInviteOpen(true)}
                                       sharedWallet={sharedWallet}
                                       onToggleShared={setSharedWallet}
                                       onMember={(m) => goDirect('memberDetail', m.id)}
                                       onEdit={() => goDirect('editProfile')}/>;
  else screen = <Home theme={theme} data={dataWithMembers} go={go}/>;

  const isEntryScreen = route === 'addExpense' || route === 'addIncome' || route === 'addGoal' || route === 'editProfile';

  const body = (
    <div className="ft" style={{ background: theme.bg, color: theme.ink, height: '100%', position: 'relative', overflow: 'hidden' }}>
      <div style={{ height: '100%', overflow: 'auto' }} className="ft-scroll">{screen}</div>
      {!isEntryScreen && <TabBar theme={theme} route={route} go={go}/>}

      {/* action chooser overlay */}
      <ActionChooserSheet theme={theme} open={chooserOpen}
        onClose={() => setChooserOpen(false)}
        go={(r) => { if (r === 'add') goDirect('addExpense'); else if (r === 'addIncome') goDirect('addIncome'); else goDirect(r); }}/>

      {/* edit asset overlay */}
      <EditAssetSheet theme={theme} open={!!editAsset}
        onClose={() => setEditAsset(null)}
        item={editAsset?.item} kind={editAsset?.kind}
        onSave={handleSaveAsset}/>

      {/* invite member overlay */}
      <InviteMemberSheet theme={theme} open={inviteOpen}
        onClose={() => setInviteOpen(false)}
        onInvite={handleInvite}/>

      {/* pay card overlay */}
      <PayCardSheet theme={theme} open={!!payCard}
        onClose={() => setPayCard(null)}
        card={payCard?.card}
        onPay={handlePayCard}/>
    </div>
  );

  return (
    <>
      <IOSDevice dark={t.themeName === 'dark'} width={402} height={874}>{body}</IOSDevice>
      <TweaksPanel title="Tweaks">
        <TweakSection label="Tampilan">
          <TweakRadio label="Tema" value={t.themeName} options={[
            { value: 'light', label: 'Terang' },
            { value: 'dark', label: 'Gelap' },
          ]} onChange={v => setTweak('themeName', v)}/>
        </TweakSection>
        <TweakSection label="Navigasi cepat">
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 6 }}>
            {[
              ['home','Beranda'],['add','Catat (chooser)'],['addExpense','+ Pengeluaran'],['addIncome','+ Pendapatan'],
              ['addGoal','+ Tujuan'],['notifications','Notifikasi'],
              ['expenses','Log'],['spend','Pengeluaran'],['category','Kategori'],['assets','Aset'],
              ['goals','Tujuan'],['cards','Utang/CC'],['health','Kesehatan'],['settings','Profil'],
            ].map(([r, l]) => (
              <button key={r} onClick={() => { if (r === 'category') { goDirect('category', 'shopping'); } else if (r === 'add') { setChooserOpen(true); } else { goDirect(r); } }}
                style={{
                  padding: '8px 10px', borderRadius: 8,
                  background: route === r ? '#1a1814' : '#f1ede4',
                  color: route === r ? '#f1ede4' : '#1a1814',
                  border: '0.5px solid rgba(0,0,0,0.1)', fontSize: 11, fontWeight: 500,
                  cursor: 'pointer',
                }}>{l}</button>
            ))}
          </div>
        </TweakSection>
      </TweaksPanel>
    </>
  );
}

window.FinancialApp = FinancialApp;
window.FinancialAppWithTweaks = FinancialAppWithTweaks;
window.TabBar = TabBar;
