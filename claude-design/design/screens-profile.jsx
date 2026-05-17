// screens-profile.jsx — EditProfileScreen + MemberDetailScreen + helpers.

// ───── Confirmation sheet (small) ─────
function ConfirmSheet({ theme, open, onClose, title, body, destructive = false, confirmLabel, cancelLabel = 'Batal', onConfirm }) {
  if (!open) return null;
  return (
    <BottomSheet theme={theme} open={open} onClose={onClose}>
      <div style={{ padding: '8px 24px 20px', textAlign: 'center' }}>
        <div className="ft-serif" style={{ fontSize: 19, color: theme.ink, fontWeight: 500, letterSpacing: -0.3 }}>
          {title}
        </div>
        <div style={{ fontSize: 13, color: theme.ink3, marginTop: 8, lineHeight: 1.5 }}>
          {body}
        </div>
      </div>
      <div style={{ padding: '0 22px 0', display: 'flex', gap: 10 }}>
        <button onClick={onClose} style={{
          flex: 1, padding: '14px 0', borderRadius: 12,
          background: theme.surface, border: `0.5px solid ${theme.line}`,
          color: theme.ink, fontSize: 13, fontWeight: 500,
        }}>{cancelLabel}</button>
        <button onClick={() => { onConfirm(); onClose(); }} style={{
          flex: 1, padding: '14px 0', borderRadius: 12,
          background: destructive ? theme.danger : theme.ink,
          color: destructive ? '#fff' : theme.bg,
          fontSize: 13, fontWeight: 500,
        }}>{confirmLabel}</button>
      </div>
    </BottomSheet>
  );
}

// ───── Edit Profile screen ─────
function EditProfileScreen({ theme, data, go, onSave }) {
  const [name, setName] = React.useState(data.user.name);
  const [email, setEmail] = React.useState(data.user.email);
  const [phone, setPhone] = React.useState(data.user.phone);
  const [initials, setInitials] = React.useState(data.user.initials);
  const [color, setColor] = React.useState(data.user.color || 'clay');
  const [dirty, setDirty] = React.useState(false);

  const colors = ['clay', 'sage', 'sky', 'plum', 'ochre', 'moss'];

  React.useEffect(() => {
    const i = name.split(' ').map(w => w[0]).slice(0, 2).join('').toUpperCase();
    if (i) setInitials(i);
  }, [name]);

  function handleSave() {
    onSave({ name, email, phone, initials, color });
    go('settings');
  }

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', background: theme.bg }}>
      <SubHeader theme={theme} title="Edit Profil" onBack={() => go('settings')}
        action={
          <button onClick={handleSave} disabled={!dirty}
            style={{
              padding: '0 14px', height: 34, borderRadius: 999,
              background: dirty ? theme.ink : theme.surfaceAlt,
              color: dirty ? theme.bg : theme.ink3,
              opacity: dirty ? 1 : 0.7,
              fontSize: 12, fontWeight: 500, cursor: dirty ? 'pointer' : 'default',
            }}>Simpan</button>
        }/>

      <div style={{ flex: 1, overflow: 'auto', paddingBottom: 40 }} className="ft-scroll">
        {/* Avatar preview */}
        <div style={{ padding: '24px 22px 14px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{
            width: 96, height: 96, borderRadius: '50%',
            background: theme[color], color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: "'Newsreader', serif", fontSize: 40, fontWeight: 500,
            letterSpacing: 1, boxShadow: `0 8px 28px ${theme[color]}33`,
            transition: 'all 240ms',
          }}>{initials}</div>
          <button style={{
            marginTop: 14, padding: '7px 14px', borderRadius: 999,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            color: theme.clay, fontSize: 12, fontWeight: 500,
          }}>Ubah Foto</button>
        </div>

        {/* Accent color */}
        <div style={{ padding: '0 22px 18px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Aksen Warna</Eyebrow>
          <div style={{ display: 'flex', gap: 10 }}>
            {colors.map(c => {
              const on = color === c;
              return (
                <button key={c} onClick={() => { setColor(c); setDirty(true); }} style={{
                  width: 38, height: 38, borderRadius: '50%',
                  background: theme[c],
                  border: on ? `2px solid ${theme.ink}` : `2px solid transparent`,
                  boxShadow: on ? `inset 0 0 0 2px ${theme.bg}` : 'none',
                  cursor: 'pointer', flexShrink: 0,
                  transition: 'all 200ms',
                }}/>
              );
            })}
          </div>
        </div>

        {/* Inputs */}
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Informasi Pribadi</Eyebrow>
          <Card theme={theme} padded={false}>
            {[
              { label: 'Nama', value: name, set: setName, type: 'text', placeholder: 'Nama lengkap' },
              { label: 'Email', value: email, set: setEmail, type: 'email', placeholder: 'email@contoh.com' },
              { label: 'No. Telepon', value: phone, set: setPhone, type: 'tel', placeholder: '+62 812-XXXX-XXXX' },
            ].map((f, i) => (
              <div key={f.label} style={{
                padding: '12px 16px',
                borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              }}>
                <div style={{ fontSize: 11, color: theme.ink3, letterSpacing: 0.3, marginBottom: 4 }}>{f.label}</div>
                <input value={f.value} type={f.type} placeholder={f.placeholder}
                  onChange={e => { f.set(e.target.value); setDirty(true); }}
                  style={{
                    width: '100%', border: 'none', background: 'transparent',
                    color: theme.ink, fontSize: 14, fontFamily: 'inherit', outline: 'none',
                    padding: 0,
                  }}/>
              </div>
            ))}
          </Card>
        </div>

        {/* Settings rows */}
        <div style={{ padding: '14px 22px 0' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Keamanan</Eyebrow>
          <Card theme={theme} padded={false}>
            {[
              { label: 'Ubah kata sandi', detail: 'Terakhir 4 bulan lalu', icon: 'shield' },
              { label: 'Autentikasi dua faktor', detail: 'Aktif · WhatsApp', icon: 'pulse' },
              { label: 'Sesi aktif', detail: '2 perangkat', icon: 'bank' },
            ].map((row, i) => (
              <button key={row.label} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
                width: '100%', textAlign: 'left',
                borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: 10,
                  background: theme.surfaceAlt, border: `0.5px solid ${theme.line}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}><Icon name={row.icon} size={14} color={theme.ink2}/></div>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{row.label}</div>
                  <div style={{ fontSize: 11, color: theme.ink3, marginTop: 2 }}>{row.detail}</div>
                </div>
                <Icon name="forward" size={12} color={theme.ink4}/>
              </button>
            ))}
          </Card>
        </div>

        <div style={{ padding: '18px 22px 0' }}>
          <button style={{
            width: '100%', padding: '14px 0', borderRadius: 12,
            background: theme.surface, border: `0.5px solid ${theme.line}`,
            color: theme.danger, fontSize: 13, fontWeight: 500,
          }}>Hapus Akun</button>
        </div>
      </div>
    </div>
  );
}

// ───── Member Detail screen ─────
function MemberDetailScreen({ theme, data, memberId, go, onKick, onCancelInvite, onResend }) {
  const member = data.household.members.find(m => m.id === memberId);
  const [confirmOpen, setConfirmOpen] = React.useState(false);
  if (!member) return <div/>;

  const color = theme[member.color];
  const pending = member.status === 'pending';
  const isMe = !!member.isMe;

  const accessLabel = {
    full: 'Akses Penuh',
    limited: 'Akses Terbatas',
    view: 'Lihat Saja',
  }[member.access || 'full'];
  const accessDetail = {
    full: 'Lihat & catat semua transaksi, saldo, tujuan, dan utang',
    limited: 'Hanya bisa mencatat pengeluaran sendiri',
    view: 'Hanya melihat ringkasan',
  }[member.access || 'full'];

  return (
    <div style={{ background: theme.bg, minHeight: '100%', paddingBottom: 110 }}>
      <SubHeader theme={theme} title="Detail Anggota" onBack={() => go('settings')}
        action={!isMe && !pending ? (
          <button style={{ width: 34, height: 34, borderRadius: '50%', background: theme.surface, border: `0.5px solid ${theme.line}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Icon name="more" size={16} color={theme.ink2}/>
          </button>
        ) : null}/>

      {/* Avatar hero */}
      <div style={{ padding: '24px 22px 16px', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <div style={{
          width: 96, height: 96, borderRadius: '50%',
          background: pending ? `${color}33` : color, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: "'Newsreader', serif", fontSize: 40, fontWeight: 500, letterSpacing: 1,
          boxShadow: pending ? 'none' : `0 8px 28px ${color}33`,
          opacity: pending ? 0.85 : 1,
        }}>{member.initials}</div>
        <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, fontWeight: 500, marginTop: 12, letterSpacing: -0.3 }}>
          {member.name}{isMe ? ' · Anda' : ''}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
          <span style={{ fontSize: 12, color: theme.ink3 }}>{member.role}</span>
          {pending && (
            <span style={{
              fontSize: 9, padding: '2px 8px', borderRadius: 999,
              background: `${theme.ochre}1a`, color: theme.ochre,
              border: `0.5px solid ${theme.ochre}33`, fontWeight: 500, letterSpacing: 0.4,
            }}>MENUNGGU KONFIRMASI</span>
          )}
          {!pending && !isMe && (
            <span style={{
              fontSize: 9, padding: '2px 8px', borderRadius: 999,
              background: `${theme.moss}1a`, color: theme.moss,
              border: `0.5px solid ${theme.moss}33`, fontWeight: 500, letterSpacing: 0.4,
            }}>AKTIF</span>
          )}
        </div>
      </div>

      {/* Pending hint */}
      {pending && (
        <div style={{ padding: '0 22px 14px' }}>
          <Card theme={theme} style={{ background: `${theme.ochre}10`, border: `0.5px solid ${theme.ochre}33` }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10 }}>
              <Icon name="info" size={16} color={theme.ochre} style={{ marginTop: 1 }}/>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>Undangan sedang menunggu</div>
                <div style={{ fontSize: 11, color: theme.ink3, marginTop: 4, lineHeight: 1.45 }}>
                  Dikirim via <span style={{ color: theme.ink2, fontWeight: 500 }}>{member.invitedVia || 'Email'}</span> pada {member.joinedAt}. Akan kedaluwarsa otomatis dalam 7 hari.
                </div>
              </div>
            </div>
          </Card>
        </div>
      )}

      {/* Info card */}
      <div style={{ padding: '0 22px 14px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Informasi Kontak</Eyebrow>
        <Card theme={theme} padded={false}>
          {[
            { label: 'Email', value: member.email, icon: 'sparkle' },
            { label: 'No. Telepon', value: member.phone, icon: 'pulse' },
            { label: pending ? 'Diundang' : 'Bergabung', value: member.joinedAt, icon: 'house' },
          ].map((row, i) => (
            <div key={row.label} style={{
              display: 'flex', alignItems: 'center', gap: 12, padding: '12px 16px',
              borderTop: i > 0 ? `0.5px solid ${theme.line}` : 'none',
            }}>
              <Icon name={row.icon} size={14} color={theme.ink3}/>
              <span style={{ flex: 1, fontSize: 12, color: theme.ink3 }}>{row.label}</span>
              <span className="ft-mono" style={{ fontSize: 12, color: theme.ink, fontWeight: 500 }}>{row.value}</span>
            </div>
          ))}
        </Card>
      </div>

      {/* Access card */}
      <div style={{ padding: '0 22px 14px' }}>
        <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Tingkat Akses</Eyebrow>
        <Card theme={theme}>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 10,
              background: `${color}1a`, border: `0.5px solid ${color}33`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              flexShrink: 0,
            }}><Icon name="shield" size={16} color={color}/></div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, color: theme.ink, fontWeight: 500 }}>{accessLabel}</div>
              <div style={{ fontSize: 11, color: theme.ink3, marginTop: 4, lineHeight: 1.45 }}>{accessDetail}</div>
            </div>
            {!isMe && !pending && (
              <button style={{ fontSize: 12, color: theme.clay, fontWeight: 500 }}>Ubah</button>
            )}
          </div>
        </Card>
      </div>

      {/* Activity stats (active only) */}
      {!pending && (
        <div style={{ padding: '0 22px 14px' }}>
          <Eyebrow theme={theme} style={{ marginBottom: 8 }}>Aktivitas Bulan Ini</Eyebrow>
          <Card theme={theme}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
              <div>
                <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Pengeluaran</div>
                <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
                  {fmtRp(member.monthSpend || 0, { compact: true })}
                </div>
              </div>
              <div>
                <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>Jumlah Transaksi</div>
                <div className="ft-serif" style={{ fontSize: 22, color: theme.ink, marginTop: 4, letterSpacing: -0.3 }}>
                  {member.txnCount || 0}<span style={{ fontSize: 13, color: theme.ink3, marginLeft: 4 }}>tx</span>
                </div>
              </div>
            </div>
            {!isMe && (
              <button onClick={() => go('expenses')} style={{
                marginTop: 14, paddingTop: 14, borderTop: `0.5px dashed ${theme.line}`,
                width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                fontSize: 12, color: theme.ink2, fontWeight: 500,
              }}>
                Lihat semua transaksi
                <Icon name="forward" size={12} color={theme.ink4}/>
              </button>
            )}
          </Card>
        </div>
      )}

      {/* Destructive actions */}
      {!isMe && (
        <div style={{ padding: '14px 22px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          {pending ? (
            <>
              <button onClick={() => onResend(member)} style={{
                width: '100%', padding: '14px 0', borderRadius: 12,
                background: theme.surface, border: `0.5px solid ${theme.line}`,
                color: theme.ink, fontSize: 13, fontWeight: 500,
                display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              }}>
                <Icon name="sparkle" size={14} color={theme.ink2}/>
                Kirim ulang undangan
              </button>
              <button onClick={() => setConfirmOpen(true)} style={{
                width: '100%', padding: '14px 0', borderRadius: 12,
                background: theme.surface, border: `0.5px solid ${theme.line}`,
                color: theme.danger, fontSize: 13, fontWeight: 500,
              }}>
                Batalkan undangan
              </button>
            </>
          ) : (
            <button onClick={() => setConfirmOpen(true)} style={{
              width: '100%', padding: '14px 0', borderRadius: 12,
              background: theme.surface, border: `0.5px solid ${theme.line}`,
              color: theme.danger, fontSize: 13, fontWeight: 500,
            }}>
              Keluarkan dari keluarga
            </button>
          )}
        </div>
      )}

      {isMe && (
        <div style={{ padding: '14px 22px 0' }}>
          <button onClick={() => go('editProfile')} style={{
            width: '100%', padding: '14px 0', borderRadius: 12,
            background: theme.ink, color: theme.bg, fontSize: 13, fontWeight: 500,
          }}>
            Edit Profil Saya
          </button>
        </div>
      )}

      <ConfirmSheet theme={theme} open={confirmOpen}
        onClose={() => setConfirmOpen(false)}
        destructive
        title={pending ? 'Batalkan undangan?' : `Keluarkan ${member.name.split(' ')[0]}?`}
        body={pending
          ? `${member.name} tidak akan dapat lagi menerima undangan ke ${data.household.name}. Anda bisa mengundang ulang kapan saja.`
          : `${member.name} akan kehilangan akses ke seluruh data ${data.household.name}, termasuk pengeluaran, saldo, tujuan, dan utang. Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel={pending ? 'Ya, batalkan' : 'Ya, keluarkan'}
        onConfirm={() => {
          if (pending) onCancelInvite(member.id);
          else onKick(member.id);
          go('settings');
        }}/>
    </div>
  );
}

Object.assign(window, { ConfirmSheet, EditProfileScreen, MemberDetailScreen });
