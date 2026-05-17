// widgets.jsx — shared visual primitives for the financial tracker.
// Donut, ring, traffic light, progress bar, sparkline, allocation pie.

// ───── Donut chart (animated) ─────
function Donut({ segments, size = 200, thickness = 22, t = 1, centerLabel, centerValue, theme, gap = 2 }) {
  // segments: [{ id, value, color }]
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const total = segments.reduce((s, x) => s + x.value, 0) || 1;
  let offset = 0;
  return (
    <div style={{ position: 'relative', width: size, height: size }}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={theme.line} strokeWidth={thickness}/>
        {segments.map((s, i) => {
          const frac = (s.value / total) * t;
          const dash = frac * c;
          const el = (
            <circle key={s.id || i}
              cx={size/2} cy={size/2} r={r} fill="none"
              stroke={theme[s.color] || s.color}
              strokeWidth={thickness}
              strokeDasharray={`${Math.max(0, dash - gap)} ${c}`}
              strokeDashoffset={-offset}
              strokeLinecap="butt"
              style={{ transition: 'stroke-dasharray 600ms cubic-bezier(.2,.7,.3,1)' }}
            />
          );
          offset += dash;
          return el;
        })}
      </svg>
      {(centerLabel || centerValue) && (
        <div style={{
          position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
          alignItems: 'center', justifyContent: 'center', textAlign: 'center', gap: 4,
        }}>
          {centerLabel && <div style={{ fontSize: 11, letterSpacing: 0.8, textTransform: 'uppercase', color: theme.ink3 }}>{centerLabel}</div>}
          {centerValue && <div className="ft-serif" style={{ fontSize: 28, fontWeight: 500, color: theme.ink, letterSpacing: -0.5 }}>{centerValue}</div>}
        </div>
      )}
    </div>
  );
}

// ───── Score ring (single value, 0–100) ─────
function Ring({ value, max = 100, size = 120, thickness = 10, color, track, t = 1 }) {
  const r = (size - thickness) / 2;
  const c = 2 * Math.PI * r;
  const frac = (value / max) * t;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} style={{ transform: 'rotate(-90deg)' }}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={track} strokeWidth={thickness}/>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={thickness}
        strokeDasharray={`${frac * c} ${c}`} strokeLinecap="round"
        style={{ transition: 'stroke-dasharray 800ms cubic-bezier(.2,.7,.3,1)' }}
      />
    </svg>
  );
}

// ───── Progress bar ─────
function Bar({ value, max = 100, color, track, height = 6, overflowColor }) {
  const pct = Math.min(100, (value / max) * 100);
  const over = Math.max(0, (value / max) * 100 - 100);
  return (
    <div style={{ height, background: track, borderRadius: 999, overflow: 'hidden', position: 'relative' }}>
      <div style={{
        width: `${Math.min(100, pct)}%`, height: '100%', background: color, borderRadius: 999,
        transition: 'width 600ms cubic-bezier(.2,.7,.3,1)',
      }}/>
      {over > 0 && (
        <div style={{
          position: 'absolute', right: 0, top: 0, height: '100%',
          width: `${Math.min(30, over)}%`, background: overflowColor || color,
          borderRadius: 999, opacity: 0.85,
        }}/>
      )}
    </div>
  );
}

// ───── Traffic light health indicator ─────
function TrafficLight({ state, theme, size = 14, vertical = false }) {
  // state: 'good' | 'caution' | 'risk'
  const lights = [
    { id: 'good', color: theme.healthOk },
    { id: 'caution', color: theme.healthWarn },
    { id: 'risk', color: theme.healthBad },
  ];
  return (
    <div style={{
      display: 'flex', flexDirection: vertical ? 'column' : 'row',
      gap: 6, padding: vertical ? '8px 6px' : '6px 8px',
      background: theme.surfaceAlt, borderRadius: vertical ? 999 : 999,
      border: `0.5px solid ${theme.line}`,
    }}>
      {lights.map(l => {
        const on = l.id === state;
        return (
          <div key={l.id} style={{
            width: size, height: size, borderRadius: '50%',
            background: on ? l.color : `${l.color}24`,
            boxShadow: on ? `0 0 0 2px ${l.color}24, inset 0 1px 2px rgba(255,255,255,0.25)` : 'none',
            transition: 'all 240ms',
          }}/>
        );
      })}
    </div>
  );
}

// ───── Sparkline ─────
function Sparkline({ data, width = 80, height = 28, color, fill }) {
  const max = Math.max(...data);
  const min = Math.min(...data);
  const range = max - min || 1;
  const step = width / (data.length - 1);
  const pts = data.map((v, i) => [i * step, height - ((v - min) / range) * (height - 4) - 2]);
  const d = pts.map((p, i) => `${i === 0 ? 'M' : 'L'}${p[0].toFixed(1)} ${p[1].toFixed(1)}`).join(' ');
  const fd = fill ? `${d} L${width} ${height} L0 ${height} Z` : null;
  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`}>
      {fd && <path d={fd} fill={fill} opacity={0.18}/>}
      <path d={d} fill="none" stroke={color} strokeWidth={1.5} strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ───── Stacked monthly bars (mini) ─────
function MonthlyBars({ months, theme, height = 100 }) {
  // months: [{ label, total, segments: [{ color, value }] }]
  const max = Math.max(...months.map(m => m.total));
  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 10, height }}>
      {months.map((m, i) => {
        const barH = (m.total / max) * (height - 18);
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{
              width: '100%', height: barH, borderRadius: 4, overflow: 'hidden',
              display: 'flex', flexDirection: 'column-reverse', background: theme.line,
            }}>
              {m.segments.map((s, j) => (
                <div key={j} style={{
                  width: '100%',
                  height: `${(s.value / m.total) * 100}%`,
                  background: theme[s.color] || s.color,
                }}/>
              ))}
            </div>
            <div style={{ fontSize: 10, color: theme.ink3, letterSpacing: 0.3 }}>{m.label}</div>
          </div>
        );
      })}
    </div>
  );
}

// ───── Section card ─────
function Card({ theme, children, style = {}, padded = true, onClick }) {
  return (
    <div onClick={onClick}
      style={{
        background: theme.surface,
        borderRadius: 18,
        padding: padded ? 18 : 0,
        border: `0.5px solid ${theme.line}`,
        boxShadow: '0 0.5px 0 rgba(0,0,0,0.02)',
        cursor: onClick ? 'pointer' : 'default',
        ...style,
      }}>
      {children}
    </div>
  );
}

// ───── Status chip ─────
function Chip({ children, color, theme, soft = true }) {
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '3px 9px', borderRadius: 999, fontSize: 11, letterSpacing: 0.2,
      fontWeight: 500,
      background: soft ? `${color}1a` : color,
      color: soft ? color : '#fff',
      border: soft ? `0.5px solid ${color}33` : 'none',
    }}>{children}</span>
  );
}

// ───── Eyebrow label ─────
function Eyebrow({ children, theme, style = {} }) {
  return (
    <div style={{
      fontSize: 10, letterSpacing: 1.4, textTransform: 'uppercase',
      color: theme.ink3, fontWeight: 500, ...style,
    }}>{children}</div>
  );
}

Object.assign(window, {
  Donut, Ring, Bar, TrafficLight, Sparkline, MonthlyBars, Card, Chip, Eyebrow,
});
