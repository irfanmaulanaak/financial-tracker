# FinSist design rules

Read this before changing any screen. It records decisions that are already made, so nobody (human or AI) has to guess and ends up with the generic "AI-made" look.

Visual reference: the approved mockup of Beranda with Eling. Its source is in `/opt/data/cache/scratch/finsist-mockups/v3/` (`home.html`, `pangolin.js`, `moods.html`). Render it and compare against your result before calling a screen done.

## 1. Who it is for, and the feeling

- Two people (Irfan and Nadhifa) who share one household budget. They open the app to answer one question: "how much can we spend today?"
- Feeling: friendly and calm, like a family app. It is not a bank dashboard.
- The one memorable thing is **Eling** walking the **payday path**. Everything else on the screen stays quiet.

## 2. Color

The default palette is **Daun**. The other palettes stay as options in Settings.

| Role | Light | Dark | Used for |
|---|---|---|---|
| bg | `#FFFFFF` | `#0F1512` | page |
| hero | `#EEF7F1` | `#14251C` | top scene of Beranda only |
| ink | `#18231D` | `#EAF2EC` | main text |
| ink2 | `#47574D` | `#B9C7BE` | supporting text |
| ink3 | `#67756C` | `#8D9C93` | captions |
| line | `#EDF1EE` | `#24302A` | hairlines between rows |
| accent (clay) | `#1F8A5B` | `#4CC38A` | the single action color: links, active tab, progress |
| fab | `#F7BE34` | `#F7BE34` | the Catat button only |
| danger | `#B3261E` | `#FF8A80` | over budget, overdue |
| warn tile | `#FFF3D1` / ink `#8A5212` | `#3A2F16` / `#F7D489` | due-date tiles |

Rules:
- Color carries meaning, not decoration. Red means over budget or overdue. The accent means "you can tap this" or "progress".
- The hero scene colors come from the palette: sky = `hero`, hill = `hero` mixed 12% with the accent, empty path = `hero` mixed 30% with the accent, filled path = the accent. Every palette keeps working.
- Member colors (Irfan, Nadhifa) come from `household.members[].color`. They are used only for the avatar circles.
- No gradients, no glow, no colored shadows.

## 3. Type

- **Fredoka 600** only for the big hero number (and Eling's "z z"). `Rp` and `rb`/`jt` are smaller (26px, weight 500) next to a 58px number.
- **Plus Jakarta Sans** for everything else.
- Three sizes do almost everything: 17px w700 section titles, 15px body (w600 for row titles), 13px captions. Big number is the only exception.
- Sentence case everywhere. **No ALL-CAPS labels. No letter-spaced eyebrow labels.**
- Money uses tabular figures and Indonesian format: `Rp89,1 jt`, `−Rp133.100`.

## 4. Shape and space

- Spacing on a 4px grid. Screen side padding 22px. Section gap 28px.
- Radius: 10px small tiles, 12px inputs and sheets, 16px the speech bubble, full circle for avatars and the Catat button. Nothing else is rounded.
- **Cards only for things you tap as one object.** Lists are plain rows split by a 1px `line` hairline. No card around a whole section, no card inside a card.
- No icons inside colored squares or circles as decoration. A tile is allowed only when it shows data (the due-date tile shows "20 Okt"; the ratio ring shows "42%").
- No status dots. If something needs a status, write it in words.

## 5. Copy

- Indonesian, plain, short, like a person talking. "Sisa Rp5,8 jt dibagi 14 hari sampai gajian."
- No formulas (`=`, `÷`, `×`), no em dashes, no middle-dot separators (`A · B`) in UI text.
- Every warning says what to do next, and it never blames.

## 6. Eling, the mascot

A trenggiling (pangolin) whose scales are gold coins. Drawn in code (CustomPainter), never a bitmap. Geometry: port `pangolin.js` from the mockup folder.

Moods (pick the first that applies):
1. **Bobo**: 21:00 to 04:59 local time. Curled ball, blue nightcap, "z z".
2. **Ngirit dulu** (`tipis`): the household has a budget and the money left today is low: `remaining <= 0`, or `perDay * cycleLength < 0.5 * monthlyBudgetTotal`. Curled ball, worried face peeking out, sweat drop.
3. **Hore**: nothing was spent yesterday (`noSpendYesterday`). Standing, one paw up holding a coin, confetti.
4. **Senang**: everything else. Standing, calm.

Eling always says one short line in a speech bubble:
- The daily insight if there is one.
- Otherwise a mood line: Senang "Hari ini masih aman.", Ngirit "Pelan-pelan dulu ya, sisa anggaran tinggal sedikit.", Bobo "Selamat istirahat. Besok kita cek lagi.", Hore "Kemarin nggak ada jajan. Mantap!"
- After a tap: "Hihi, geli!" plus the money left today, for example "Hihi, geli! Hari ini masih aman, Rp414 rb lagi ya."

## 7. Motion

Motion is for delight and for showing what changed. It is never decoration that loops forever.

- **Entrance** (once per app session, the first time Beranda opens): the number counts up from 0 (950ms), Eling rolls as a ball from the cycle start to today along the path while the green line follows (1500ms, ease out), then unrolls and stands with a small overshoot (350ms), then the bubble pops in (350ms, back-out). Coming back to the tab later shows the final state with no entrance.
- **Idle**: a gentle breathe and a blink every 4 to 6 seconds, for 10 seconds after the entrance, then everything stops. No endless animation.
- **Tap Eling**: light haptic, he curls into a ball with a small wobble, pops back out, three small hearts float up beside him, and the bubble switches to the tap line for 1.5s.
- **Reduce motion** (`MediaQuery.disableAnimations`): no entrance, no idle, no wobble. Eling is drawn in his final pose, and a tap only changes the bubble text.
- Wrap the scene in a `RepaintBoundary`. Use one `AnimationController` per sequence and dispose it. Do not use `Ticker`s that keep running after the motion ends.

## 8. Layout of Beranda

From top to bottom:
1. Header: overlapping member avatars, "Selamat pagi, Irfan" (pagi before 11:00, siang before 15:00, sore before 18:00, malam after), bell, and the existing ⋯ menu.
2. Hero scene (hero color, full width): "Aman dibelanjakan hari ini", the big number, one plain sentence, then the hill with the payday path from the cycle start date to "Gajian <date>" with a small house at the end, Eling at today's spot, and his bubble.
3. Onboarding checklist (only while active).
4. "Perlu dibereskan": due bills with a date tile, and the DSR warning with a small ring showing the percent. Hidden when empty.
5. Activity grouped by day ("Hari ini", "Kemarin, 15 Okt", "Selasa, 14 Okt"), 5 latest items, then "Lihat semua".

Only in **Lengkap** (the Ringkas setting stops after item 4):

6. "Anggaran bulan ini": the top 4 categories as plain rows with one thin bar each (accent, red when over).
7. "Kekayaan bersih": one row with the value and its 2-week change. Tap it to open Aset.
8. "Tujuan": up to 3 goals as plain rows with a thin bar.

## 9. Banned (the AI-default look)

Do not ship any of these unless this file is changed first:
- Purple or blue-to-purple gradients, gradient text, glow, neon on dark.
- Cream background with a terracotta accent as the default look.
- Everything in identical rounded cards with the same soft shadow, or cards inside cards.
- ALL-CAPS letter-spaced labels, a label above every block, numbered "01 / 02" markers that are not real steps.
- A big number with a small label, a progress bar and two stat chips under it, as a reflex.
- Icons in colored circles or squares as decoration. Emoji as icons.
- Status dots without words.
- Middle-dot meta strings, `→` appended to links, em dashes in UI text.
- Fade-in on every section, hover or bounce effects on everything, animation that never stops.

## 10. How to work

1. Change one screen at a time.
2. Build it, open it at 393x852 with real data, and compare with the reference and this file.
3. Check light, dark, reduce motion, and an empty household.
4. Send before and after screenshots. Nothing is pushed before the owner says OK.
