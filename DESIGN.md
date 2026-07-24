# FinSist Design System

## Product character

FinSist is a shared household financial tool. It should feel calm, precise,
and trustworthy: closer to a clean bank statement than a lifestyle dashboard.
The interface serves numbers and decisions. Decoration stays quiet.

The visual direction combines:

- Coinbase-style financial clarity: white canvas, restrained blue, calm type.
- IBM Carbon-style structure: flat surfaces, hairlines, data-first grouping.
- Apple-style hierarchy: bold left alignment, predictable controls, glass only
  as a floating functional layer.

This is inspiration, not brand imitation. FinSist keeps its own Indonesian,
household-first voice.

## Core principles

1. Show the useful number first.
2. One screen should be scannable without swiping hidden dashboard cards.
3. Group related rows with spacing and dividers before adding another card.
4. Blue means action or selection. Green/red/yellow mean financial state only.
5. Liquid Glass belongs to navigation and transient controls, never content.
6. Motion confirms cause and effect. Nothing moves merely to look alive.

## Color roles

### Light

| Role | Hex | Use |
|---|---:|---|
| Canvas | `#F6F7F9` | App background |
| Canvas alternate | `#F0F2F5` | Grouped background |
| Surface | `#FFFFFF` | Rows, cards, inputs |
| Surface alternate | `#F2F4F7` | Selected/secondary fill |
| Ink | `#0A0B0D` | Main text and numbers |
| Ink secondary | `#3F4652` | Body copy |
| Ink muted | `#68707D` | Labels and metadata |
| Hairline | `#E2E6EC` | Dividers and borders |
| Action blue | `#0052FF` | Primary action, link, selection |
| Positive | `#087A46` | Income, safe, healthy |
| Negative | `#C9363E` | Expense, debt risk, destructive |
| Warning | `#B76E00` | Due soon and attention |

### Dark

| Role | Hex |
|---|---:|
| Canvas | `#0A0B0D` |
| Canvas alternate | `#111419` |
| Surface | `#16181D` |
| Surface alternate | `#20242B` |
| Ink | `#F7F9FC` |
| Ink secondary | `#C7CDD6` |
| Ink muted | `#9098A5` |
| Hairline | `#2A3038` |
| Action blue | `#5C86FF` |
| Positive | `#43C982` |
| Negative | `#FF6B73` |
| Warning | `#F3B340` |

Category colors may vary for charts. They do not become page accents.

## Typography

- Family: Inter across Android, iOS, and web.
- Display/financial totals: weight 600, tight tracking, tabular figures.
- Section title: 16–20, weight 600.
- Body: 14–16, weight 400, line height about 1.45.
- Label/caption: 10.5–12, weight 400–600.
- Never use serif display type, decorative uppercase eyebrows, or weight 800/900.
- Rupiah columns and changing balances use tabular figures.

## Layout

- Base rhythm: 4 px. Structural spacing: 8, 12, 16, 20, 24, 32.
- Mobile horizontal gutter: 22 px.
- Touch target: minimum 44 × 44 px when practical.
- Prefer one bordered group containing related rows over several floating cards.
- Content cards: 12 px radius, 1 px hairline, no decorative shadow.
- Inputs/buttons: 12 px radius. Pills only for compact status or floating chrome.
- Keep primary facts visible. Do not put essential data behind carousels.

## Components

### Financial summary

- Label above or beside value.
- Value is the strongest element.
- One short annotation explains source, time range, or next action.
- Positive/negative color applies to the status, not the whole page.

### Ledger group

- White/dark solid surface.
- Rows separated by inset hairlines.
- Leading symbol, central label/value/detail, optional trailing trend/action.
- Entire row can be tappable; avoid multiple competing controls.

### Buttons

- Primary: action blue fill, white label.
- Secondary: solid surface, hairline, ink label.
- Destructive: negative fill or negative text depending on consequence.
- Use verb labels. One primary action per view or sheet.

### Charts

- Charts explain a nearby number; they are not decoration.
- Use one highlighted series and muted tracks by default.
- Category charts can use multiple colors only when a legend is present.
- Always show the underlying value or percentage in text.

## Liquid Glass

Liquid Glass is an optional functional layer. It appears only on:

- bottom navigation;
- side navigation;
- action sheets and transient floating controls.

It never appears on dashboard cards, forms, tables, or long-list rows.

### Optical recipe

- Real backdrop blur: 18 sigma.
- Mild saturation lift: about 1.18.
- Surface tint: about 12% light, 18% dark.
- Fine specular rim; cool blue reflection is subtle.
- Refraction is stronger at the edge than the center.
- Selected nav lens remains translucent; it is never an opaque inner pill.
- Background content must remain recognizable through the material.

### Motion

- Background drift: 20-second seamless loop rendered around 12 fps.
- Press response starts within 80 ms and settles around 220 ms.
- No elastic wobble, perpetual sweep, or decorative pulse.
- Respect Reduce Motion, Increased Contrast, and lifecycle pause.

### Performance contract

- One shared low-resolution `ui.Image` per drift step, about 0.35 MP maximum.
- Background and lenses use `drawImageRect`; do not repaint procedural blobs in
  every glass surface.
- Never use a vsync ticker for the idle wallpaper.
- Never attach pointer-move listeners to every content card.
- Stop the timer when Liquid is off, motion is reduced, or the app is paused.
- Keep blur count limited to visible chrome.

## Voice

- Indonesian, direct, non-judgmental.
- State the fact, then the next useful action.
- Avoid motivational filler, marketing language, and blame.
- Labels should name financial concepts users already know.

## Do

- Use spacing and hairlines to create hierarchy.
- Put household decisions and exceptions near the affected number.
- Make empty states explain the first useful action.
- Keep light and dark roles semantically identical.

## Do not

- Do not use warm cream, terracotta, sage, and serif as a default aesthetic.
- Do not stack rounded cards inside rounded cards.
- Do not add gradients to content cards.
- Do not use several accent colors on one control group.
- Do not hide core metrics behind dots or swipe-only navigation.
- Do not apply glass because a surface looks empty.
