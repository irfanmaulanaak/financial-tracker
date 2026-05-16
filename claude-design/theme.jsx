// theme.jsx — design tokens for the financial tracker
// Warm editorial / premium quiet aesthetic. Two themes.

const FT_THEMES = {
  light: {
    name: 'light',
    bg: '#f1ede4',           // warm cream paper
    bgAlt: '#e9e4d7',        // deeper cream for chips
    surface: '#fbf8f1',      // card surface
    surfaceAlt: '#f6f2e8',
    ink: '#1a1814',          // near-black, warm
    ink2: '#4b463d',         // body
    ink3: '#807868',         // secondary
    ink4: '#b8b0a0',         // tertiary
    line: 'rgba(26,24,20,0.08)',
    lineStrong: 'rgba(26,24,20,0.16)',

    // Editorial accent palette
    clay: '#c4612a',         // primary warm accent
    sage: '#5e7a64',         // green / positive
    moss: '#2d5040',         // deep positive
    plum: '#7a3f4e',         // accent
    ochre: '#b89030',        // warning amber
    danger: '#9a2f2f',
    sky: '#3a6075',

    // Health traffic light
    healthOk: '#5e7a64',
    healthWarn: '#b89030',
    healthBad: '#9a2f2f',

    // Category palette (for donut)
    catFood: '#c4612a',
    catTransport: '#5e7a64',
    catBills: '#b89030',
    catShopping: '#7a3f4e',
    catEntertainment: '#3a6075',
    catHealth: '#2d5040',
    catOther: '#a89880',

    chrome: 'transparent',   // device chrome bg (inside iOS frame body)
    glassPillDark: false,
  },
  dark: {
    name: 'dark',
    bg: '#14130f',
    bgAlt: '#1c1a15',
    surface: '#1f1d18',
    surfaceAlt: '#26231d',
    ink: '#f1ede4',
    ink2: '#c8c0b0',
    ink3: '#8a8272',
    ink4: '#56514a',
    line: 'rgba(241,237,228,0.08)',
    lineStrong: 'rgba(241,237,228,0.16)',

    clay: '#e08a4a',
    sage: '#8aab92',
    moss: '#6ea088',
    plum: '#b56f80',
    ochre: '#d4ab55',
    danger: '#d56a6a',
    sky: '#7aa3bd',

    healthOk: '#8aab92',
    healthWarn: '#d4ab55',
    healthBad: '#d56a6a',

    catFood: '#e08a4a',
    catTransport: '#8aab92',
    catBills: '#d4ab55',
    catShopping: '#b56f80',
    catEntertainment: '#7aa3bd',
    catHealth: '#6ea088',
    catOther: '#807668',

    chrome: 'transparent',
    glassPillDark: true,
  },
};

// IDR formatting — Indonesian uses '.' as thousands separator
function fmtRp(n, { compact = false, sign = false } = {}) {
  const abs = Math.abs(n);
  let s;
  if (compact && abs >= 1_000_000_000) s = (abs / 1_000_000_000).toFixed(1).replace(/\.0$/, '') + ' M';
  else if (compact && abs >= 1_000_000) s = (abs / 1_000_000).toFixed(1).replace(/\.0$/, '') + ' jt';
  else if (compact && abs >= 1_000) s = (abs / 1_000).toFixed(0) + 'rb';
  else s = abs.toLocaleString('id-ID');
  const prefix = sign ? (n < 0 ? '−' : '+') : (n < 0 ? '−' : '');
  return `${prefix}Rp ${s}`;
}

// Inject base typography + reset once
function injectFTStyles() {
  if (document.getElementById('ft-styles')) return;
  const s = document.createElement('style');
  s.id = 'ft-styles';
  s.textContent = `
    @import url('https://fonts.googleapis.com/css2?family=Newsreader:opsz,wght@6..72,300;6..72,400;6..72,500;6..72,600&family=Geist:wght@300;400;500;600;700&family=Geist+Mono:wght@400;500&display=swap');

    .ft-serif { font-family: 'Newsreader', 'Times New Roman', serif; font-feature-settings: 'kern' on, 'liga' on; }
    .ft-sans { font-family: 'Geist', -apple-system, system-ui, sans-serif; font-feature-settings: 'ss01' on; }
    .ft-mono { font-family: 'Geist Mono', ui-monospace, monospace; font-variant-numeric: tabular-nums; }

    .ft * { box-sizing: border-box; }
    .ft { font-family: 'Geist', -apple-system, system-ui, sans-serif; -webkit-font-smoothing: antialiased; }
    .ft button { font-family: inherit; cursor: pointer; border: 0; background: none; padding: 0; color: inherit; }

    /* number ticker animation */
    @keyframes ft-fadeup { from { opacity:0; transform: translateY(6px); } to { opacity:1; transform: none; } }
    .ft-fadeup { animation: ft-fadeup 360ms cubic-bezier(.2,.7,.3,1) both; }

    @keyframes ft-pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: .55; transform: scale(.95); }
    }
    .ft-pulse { animation: ft-pulse 2.4s ease-in-out infinite; }

    /* scrollbar hide for inner scroll areas */
    .ft-scroll { scrollbar-width: none; }
    .ft-scroll::-webkit-scrollbar { display: none; }
  `;
  document.head.appendChild(s);
}

Object.assign(window, { FT_THEMES, fmtRp, injectFTStyles });
