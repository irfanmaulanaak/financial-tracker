// icons.jsx — line icons, 24px stroked. Premium-quiet feel: 1.5 stroke, thin.

function Icon({ name, size = 22, color = 'currentColor', stroke = 1.5, fill = 'none' }) {
  const p = { stroke: color, strokeWidth: stroke, fill, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const paths = {
    // navigation
    home:       <><path d="M3 11L12 4l9 7" {...p}/><path d="M5 10v9h14v-9" {...p}/></>,
    chart:      <><path d="M4 19V5M4 19h16" {...p}/><path d="M8 15l3-4 3 2 4-6" {...p}/></>,
    plus:       <><path d="M12 5v14M5 12h14" {...p}/></>,
    target:     <><circle cx="12" cy="12" r="8" {...p}/><circle cx="12" cy="12" r="4" {...p}/><circle cx="12" cy="12" r="1" fill={color} stroke="none"/></>,
    user:       <><circle cx="12" cy="8" r="3.5" {...p}/><path d="M5 20c1.5-3.5 4-5 7-5s5.5 1.5 7 5" {...p}/></>,

    // utility
    back:       <><path d="M15 5l-7 7 7 7" {...p}/></>,
    forward:    <><path d="M9 5l7 7-7 7" {...p}/></>,
    down:       <><path d="M5 9l7 7 7-7" {...p}/></>,
    up:         <><path d="M5 15l7-7 7 7" {...p}/></>,
    close:      <><path d="M6 6l12 12M18 6L6 18" {...p}/></>,
    more:       <><circle cx="5" cy="12" r="1.3" fill={color} stroke="none"/><circle cx="12" cy="12" r="1.3" fill={color} stroke="none"/><circle cx="19" cy="12" r="1.3" fill={color} stroke="none"/></>,
    search:     <><circle cx="11" cy="11" r="6" {...p}/><path d="M15.5 15.5L20 20" {...p}/></>,
    filter:     <><path d="M4 6h16M7 12h10M10 18h4" {...p}/></>,
    settings:   <><circle cx="12" cy="12" r="2.5" {...p}/><path d="M19 12a7 7 0 00-.1-1.2l2-1.5-2-3.4-2.3.9a7 7 0 00-2-1.2L14 3h-4l-.6 2.6a7 7 0 00-2 1.2l-2.3-.9-2 3.4 2 1.5A7 7 0 005 12c0 .4 0 .8.1 1.2l-2 1.5 2 3.4 2.3-.9a7 7 0 002 1.2L10 21h4l.6-2.6a7 7 0 002-1.2l2.3.9 2-3.4-2-1.5a7 7 0 00.1-1.2z" {...p}/></>,
    check:      <><path d="M5 12l5 5 9-11" {...p}/></>,
    bell:       <><path d="M6 17V11a6 6 0 1112 0v6l1.5 2H4.5L6 17z" {...p}/><path d="M10 21a2 2 0 004 0" {...p}/></>,
    sparkle:    <><path d="M12 4l1.6 4.4L18 10l-4.4 1.6L12 16l-1.6-4.4L6 10l4.4-1.6L12 4z" {...p}/><path d="M19 14l.7 1.9 1.9.7-1.9.7L19 19l-.7-1.7-1.9-.7 1.9-.7L19 14z" {...p}/></>,
    info:       <><circle cx="12" cy="12" r="8" {...p}/><path d="M12 10v6M12 7.5v.5" {...p}/></>,
    arrowUp:    <><path d="M12 19V5M5 12l7-7 7 7" {...p}/></>,
    arrowDown:  <><path d="M12 5v14M5 12l7 7 7-7" {...p}/></>,

    // categories
    fork:       <><path d="M8 4v8a2 2 0 002 2v6M8 4v3M11 4v3M16 4c-1.5 0-2 1.5-2 4s.5 4 2 4v8" {...p}/></>,
    bag:        <><path d="M6 8h12l-1 12H7L6 8z" {...p}/><path d="M9 8V6a3 3 0 016 0v2" {...p}/></>,
    car:        <><path d="M4 17v-3l2-5h12l2 5v3M4 17h16M4 17v2h3v-2M17 17v2h3v-2" {...p}/><circle cx="8" cy="14" r="1" fill={color} stroke="none"/><circle cx="16" cy="14" r="1" fill={color} stroke="none"/></>,
    bolt:       <><path d="M13 3L5 14h6l-1 7 8-11h-6l1-7z" {...p}/></>,
    play:       <><circle cx="12" cy="12" r="8" {...p}/><path d="M10 9l5 3-5 3V9z" fill={color} stroke="none"/></>,
    heart:      <><path d="M12 20s-7-4.5-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.5-7 10-7 10z" {...p}/></>,
    dots:       <><circle cx="6" cy="12" r="1.5" fill={color} stroke="none"/><circle cx="12" cy="12" r="1.5" fill={color} stroke="none"/><circle cx="18" cy="12" r="1.5" fill={color} stroke="none"/></>,

    // goal icons
    shield:     <><path d="M12 3l8 3v6c0 4.5-3.5 8-8 9-4.5-1-8-4.5-8-9V6l8-3z" {...p}/></>,
    wave:       <><path d="M3 12c2-2 4-2 6 0s4 2 6 0 4-2 6 0M3 17c2-2 4-2 6 0s4 2 6 0 4-2 6 0" {...p}/></>,
    laptop:     <><rect x="4" y="5" width="16" height="11" rx="1.5" {...p}/><path d="M2 19h20" {...p}/></>,
    house:      <><path d="M4 11l8-7 8 7" {...p}/><path d="M6 10v9h12v-9" {...p}/><path d="M10 19v-5h4v5" {...p}/></>,

    // misc
    cash:       <><rect x="3" y="7" width="18" height="10" rx="1.5" {...p}/><circle cx="12" cy="12" r="2.5" {...p}/></>,
    bank:       <><path d="M3 10L12 5l9 5M5 10v8M19 10v8M9 10v8M15 10v8M3 19h18" {...p}/></>,
    pie:        <><path d="M12 4v8h8a8 8 0 11-8-8z" {...p}/><path d="M14 4a8 8 0 016 6h-6V4z" {...p}/></>,
    leaf:       <><path d="M20 4c0 8-5 14-13 16C7 14 13 8 20 4z" {...p}/><path d="M14 10c-3 2-5 5-7 10" {...p}/></>,
    flame:      <><path d="M12 21c4 0 7-2.5 7-6.5 0-3-2-5-3-6 0 2-1.5 3-3 3 0-3-1-5-3-7 0 4-5 5-5 10 0 4 3 6.5 7 6.5z" {...p}/></>,
    pulse:      <><path d="M3 12h4l2-5 3 10 2-5h7" {...p}/></>,
    trend:      <><path d="M3 17l6-6 4 4 8-9" {...p}/><path d="M14 6h7v7" {...p}/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block', flexShrink: 0 }}>
      {paths[name] || null}
    </svg>
  );
}

window.Icon = Icon;
