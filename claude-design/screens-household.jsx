// screens-household.jsx — Members avatar stack, members section in settings,
// invite-member bottom sheet, member chip + filter for expenses.

// ───── Tiny avatar circle ─────
function MemberAvatar({ member, theme, size = 28, ring = false }) {
  const color = theme[member.color] || theme.clay;
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: member.status === 'pending' ? `${color}33` : color,
      color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontFamily: "'Newsreader', serif", fontSize: size * 0.42, fontWeight: 500,
      letterSpacing: 0.3,
      border: ring ? `2px solid ${theme.bg}` : 'none',
      opacity: member.status === 'pending' ? 0.7 : 1,
      flexShrink: 0,
    }}>{member.initials}</div>
  );
}

// ───── Avatar stack (overlapping) for home header ─────
function MemberStack({ members, theme, onTap, size = 28 }) {
  return (
    <button onClick={onTap} style={{
      display: 'flex', alignItems: 'center',
      padding: '4px 6px', borderRadius: 999,
      background: theme.surface, border: `0.5px solid ${theme.line}`,
      cursor: 'pointer',
    }}>
      <div style={{ display: 'flex' }}>
        {members.map((m, i) => (
          <div key={m.id} style={{ marginLeft: i === 0 ? 0 : -8 }}>
            <MemberAvatar member={m} theme={theme} size={size} ring/>
          </div>
        ))}
      </div>
      <span style={{ fontSize: 10, color: theme.ink3, marginLeft: 6, marginRight: 4, letterSpacing: 0.3, fontWeight: 500 }}>
        {members.length}
      </span>
    </button>
  );
}

// ───── Compact member chip (for expense rows) ─────
function MemberChip({ memberId, members, theme }) {
  const m = members.find(x => x.id === memberId);
  if (!m) return null;
  const color = theme[m.color] || theme.clay;
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '2px 7px 2px 3px', borderRadius: 999,
      background: `${color}1a`, border: `0.5px solid ${color}33`,
      fontSize: 10, color: theme.ink2, fontWeight: 500,
    }}>
      <div style={{
        width: 14, height: 14, borderRadius: '50%', background: color, color: '#fff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontFamily: "'Newsreader', serif", fontSize: 8, fontWeight: 500,
      }}>{m.initials[0]}</div>
      {m.isMe ? 'Saya' : m.name.split(' ')[0]}
    </div>
  );
}

// ───── Members section (for Settings) ─────
function MembersSection({ theme, household, onInvite, onMember, sharedWallet, onToggleShared }) {
  return (
    <div style={{ padding: '18px 22px 0' }}>
      <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Anggota Keluarga</Eyebrow>
      <Card theme={theme} padded={false}>
        {/* shared wallet toggle */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 14, padding: '14px 16px',
          borderBottom: `0.5px solid ${theme.line}`,
        }}>
          <Icon name="house" size={18} color={theme.ink2}/>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>Dompet Bersama</div>
            <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2, lineHeight: 1.4 }}>
              Semua transaksi anggota digabung ke dalam laporan {household.name}
            </div>
          </div>
          <button onClick={() => onToggleShared(!sharedWallet)} style={{
            width: 42, height: 24, borderRadius: 999, padding: 2,
            background: sharedWallet ? theme.moss : theme.line,
            transition: 'background 200ms', flexShrink: 0,
          }}>
            <div style={{
              width: 20, height: 20, borderRadius: '50%', background: '#fff',
              transform: sharedWallet ? 'translateX(18px)' : 'translateX(0)',
              transition: 'transform 200ms',
            }}/>
          </button>
        </div>

        {/* members */}
        {household.members.map((m, i) => (
          <button key={m.id} onClick={() => onMember && onMember(m)} style={{
            display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
            width: '100%', textAlign: 'left',
            borderTop: i === 0 ? 'none' : `0.5px solid ${theme.line}`,
            cursor: onMember ? 'pointer' : 'default',
          }}>
            <MemberAvatar member={m} theme={theme} size={36}/>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                <span style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>
                  {m.name}{m.isMe ? ' · Saya' : ''}
                </span>
                {m.status === 'pending' && (
                  <span style={{
                    fontSize: 9, padding: '2px 6px', borderRadius: 999,
                    background: `${theme.ochre}1a`, color: theme.ochre,
                    border: `0.5px solid ${theme.ochre}33`, fontWeight: 500, letterSpacing: 0.3,
                  }}>MENUNGGU</span>
                )}
              </div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>
                {m.role} · Bergabung {m.joinedAt}
              </div>
            </div>
            <Icon name="forward" size={12} color={theme.ink4}/>
          </button>
        ))}

        {/* invite cta */}
        <button onClick={onInvite} style={{
          display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
          width: '100%', textAlign: 'left',
          borderTop: `0.5px solid ${theme.line}`,
          color: theme.clay, cursor: 'pointer',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50%',
            background: `${theme.clay}1a`, border: `0.5px dashed ${theme.clay}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><Icon name="plus" size={16} color={theme.clay} stroke={2}/></div>
          <div style={{ fontSize: 13, fontWeight: 500 }}>Undang Anggota Keluarga</div>
        </button>
      </Card>
      <div style={{ fontSize: 10, color: theme.ink3, marginTop: 8, lineHeight: 1.5, paddingLeft: 4 }}>
        Anggota dengan akses penuh dapat mencatat pengeluaran, melihat saldo,
        dan menerima notifikasi anggaran bersama.
      </div>
    </div>
  );
}

// ───── Invite-member bottom sheet ─────
function InviteMemberSheet({ theme, open, onClose, onInvite }) {
  const [name, setName] = React.useState('');
  const [contact, setContact] = React.useState('');
  const [role, setRole] = React.useState('Suami');
  const [access, setAccess] = React.useState('full');

  React.useEffect(() => {
    if (open) { setName(''); setContact(''); setRole('Suami'); setAccess('full'); }
  }, [open]);

  const roles = ['Suami', 'Istri', 'Anak', 'Orang Tua', 'Lainnya'];

  function handleSend() {
    if (!name || !contact) return;
    onInvite({ name, contact, role, access });
    onClose();
  }

  return (
    <BottomSheet theme={theme} open={open} onClose={onClose}>
      <div style={{ padding: '6px 22px 14px' }}>
        <Eyebrow theme={theme}>Undang Anggota</Eyebrow>
        <div className="ft-serif" style={{ fontSize: 19, color: theme.ink, fontWeight: 500, marginTop: 4, letterSpacing: -0.3 }}>
          Tambah ke Keluarga Andini
        </div>
        <div style={{ fontSize: 11, color: theme.ink3, marginTop: 4, lineHeight: 1.4 }}>
          Kami akan mengirim undangan ke email atau nomor WhatsApp mereka. Setelah diterima, transaksi akan tergabung otomatis.
        </div>
      </div>

      <div style={{ padding: '0 22px 12px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 6 }}>Nama lengkap</Eyebrow>
        <input value={name} onChange={e => setName(e.target.value)}
          placeholder="Misal: Aditya Pratama"
          style={{
            width: '100%', padding: '12px 14px', borderRadius: 12,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            color: theme.ink, fontSize: 13, fontFamily: 'inherit', outline: 'none',
          }}/>
      </div>

      <div style={{ padding: '0 22px 12px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 6 }}>Email atau No. WhatsApp</Eyebrow>
        <input value={contact} onChange={e => setContact(e.target.value)}
          placeholder="aditya@email.com  /  +62 812-3456-7890"
          style={{
            width: '100%', padding: '12px 14px', borderRadius: 12,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            color: theme.ink, fontSize: 13, fontFamily: 'inherit', outline: 'none',
          }}/>
      </div>

      <div style={{ padding: '0 22px 12px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 6 }}>Peran</Eyebrow>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {roles.map(r => {
            const on = role === r;
            return (
              <button key={r} onClick={() => setRole(r)} style={{
                padding: '7px 12px', borderRadius: 999, fontSize: 12, fontWeight: 500,
                background: on ? theme.ink : theme.surface,
                color: on ? theme.bg : theme.ink2,
                border: `0.5px solid ${on ? theme.ink : theme.line}`,
              }}>{r}</button>
            );
          })}
        </div>
      </div>

      <div style={{ padding: '0 22px 12px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 6 }}>Tingkat akses</Eyebrow>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          {[
            { id: 'full',   label: 'Akses Penuh',     detail: 'Lihat & catat semua transaksi, saldo, tujuan, dan utang.' },
            { id: 'limited', label: 'Akses Terbatas', detail: 'Hanya bisa mencatat pengeluaran sendiri. Tidak lihat saldo.' },
            { id: 'view',   label: 'Lihat Saja',      detail: 'Hanya melihat ringkasan bulanan. Tidak dapat mencatat.' },
          ].map(a => {
            const on = access === a.id;
            return (
              <button key={a.id} onClick={() => setAccess(a.id)} style={{
                display: 'flex', gap: 12, alignItems: 'flex-start',
                padding: '12px 14px', borderRadius: 12, textAlign: 'left',
                background: on ? `${theme.moss}10` : theme.surface,
                border: `0.5px solid ${on ? theme.moss : theme.line}`,
                cursor: 'pointer',
              }}>
                <div style={{
                  width: 16, height: 16, borderRadius: '50%',
                  border: `1.5px solid ${on ? theme.moss : theme.lineStrong}`,
                  background: on ? theme.moss : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, marginTop: 1,
                }}>
                  {on && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#fff' }}/>}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{a.label}</div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2, lineHeight: 1.4 }}>{a.detail}</div>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <div style={{ padding: '8px 22px 0', display: 'flex', gap: 10 }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '14px 0', borderRadius: 12,
          background: theme.surface, border: `0.5px solid ${theme.line}`,
          color: theme.ink, fontSize: 13, fontWeight: 500,
        }}>Batal</button>
        <button onClick={handleSend} disabled={!name || !contact}
          style={{
            flex: 2, padding: '14px 0', borderRadius: 12,
            background: theme.ink, color: theme.bg, fontSize: 13, fontWeight: 500,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            opacity: (!name || !contact) ? 0.4 : 1,
          }}>
          <Icon name="sparkle" size={14} color={theme.bg}/> Kirim Undangan
        </button>
      </div>
    </BottomSheet>
  );
}

Object.assign(window, { MemberAvatar, MemberStack, MemberChip, MembersSection, InviteMemberSheet });
