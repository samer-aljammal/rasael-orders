# Rasael Orders — Design Direction

Written before the first screen. The reference every screen is held to.

---

## 1. What this is

Rasael sells personalised Arabic gift pages (love letters, birthday pages,
wedding invitations…) through Instagram. A customer fills an order form, a
WhatsApp message arrives, the page gets built, a preview goes out, the
customer pays, the link is delivered. Same day.

Rasael Orders is the tool that runs that loop. It is used **by one person,
many times a day, mostly on a phone**, between DMs. The web build is the same
app on a bigger screen.

> **An order book, not a CRM.**
> It should feel like a well-kept stationer's ledger: paper, ink, one wine
> red seal. Fast to scan, quiet when nothing is wrong.

Three rules that settle most decisions:

1. **Attention is the hero.** The first thing on screen is what needs doing
   now: late orders, orders due today, previews waiting on payment. Orders
   that are on track are quiet.
2. **Colour means attention.** Wine is the brand and the primary action.
   Amber (due today) and vermilion (late) are the only status colours. A
   delivered order is ink, not green; nothing celebrates being normal.
3. **Arabic first, not translated.** RTL is the layout, not a mirror of an
   English one. Copy is short and in the studio's own voice.

---

## 2. Pipeline

The order of stages follows how Rasael actually works (the customer pays
*after* seeing the first version):

```
جديد  →  قيد التنفيذ  →  بانتظار الدفع  →  مدفوع  →  تم التسليم
new      in progress     preview sent       paid      delivered
                                     ↘ ملغى (cancelled, from any open stage)
```

Stage is a label, not a colour. Attention is computed on top of it:

| Attention | Rule | Colour |
|---|---|---|
| Late | has a deadline, it has passed, not delivered | vermilion |
| Due today | deadline is today, not delivered | amber |
| Follow up | preview sent more than 48h ago, still unpaid | amber, text says why |
| — | everything else | none |

Every attention badge carries words, never colour alone.

---

## 3. Colour

The brand palette is wine `#561A27`, cream `#FBF1E6` and pink `#F07C8C`.
The app takes the wine and the paper, and keeps the pink for the seal mark
only — a pink UI reads as a gift shop, not a tool.

### Light — "paper"

| Token | Value | Use |
|---|---|---|
| `background` | `#F7F2EA` | Page. Cream, desaturated so long lists don't tint everything |
| `surface` | `#FFFCF7` | Cards, sheets |
| `surfaceAlt` | `#EFE8DD` | Wells, input fills, chips |
| `surfaceInverse` | `#2A1A1E` | The one hero block per screen |
| `border` / `borderStrong` | `#E6DDD0` / `#CDBFAE` | Hairlines |
| `ink` / `inkSecondary` / `inkTertiary` | `#21161A` / `#5E5157` / `#776A6E` | Warm ink ramp; tertiary clears 4.5:1 on background |
| `accent` | `#561A27` | Wine. Primary actions, selection |
| `seal` | `#F07C8C` | Brand mark only |

### Dark — "ink well"

Not inverted. A wine-black ground, and the accent is re-mixed: wine
disappears on dark, so it becomes a dusty rose.

| Token | Value |
|---|---|
| `background` | `#141011` |
| `surface` | `#1C1618` |
| `surfaceAlt` | `#251E20` |
| `border` | `#31282B` |
| `ink` / `inkSecondary` / `inkTertiary` | `#F4EDE6` / `#B9ADA8` / `#958985` |
| `accent` | `#E8919C` |

### Attention

| | Light | Dark |
|---|---|---|
| Due today / follow up | `#8A5A00` on `#F6EBD3` | `#D9A84E` on `#2C2414` |
| Late | `#B4400F` on `#F8E4D8` | `#EE8A5F` on `#2E1C14` |

Vermilion was chosen over red so "late" never reads as the wine brand colour.

---

## 4. Typography

- **IBM Plex Sans Arabic** for everything a person reads and every figure.
  Designed as a UI face, with a matching Latin, real tabular figures and
  enough x-height to stay readable at 12px. Chosen over Cairo and Tajawal,
  which are the default of a great deal of generated Arabic UI.
- **El Messiri** for the wordmark only, matching the Rasael logo.

| Role | Size / Weight | Use |
|---|---|---|
| Display | 40 / 600 | Hero figures (income, counts) |
| Headline | 26 / 600 | Screen titles |
| Title | 18 / 600 | Card and sheet titles |
| Subtitle | 15 / 600 | Names on an order row |
| Body | 15 / 400, 1.6 | Reading text |
| Label | 13 / 500 | Field labels, metadata |
| Caption | 12 / 500 | Supporting metadata |
| Section | 13 / 600, tertiary | Section headers |

Arabic-specific rules:

- **Never letter-space Arabic.** Tracking breaks the joins between letters.
  There is no uppercase either, so section headers are distinguished by
  weight and colour, not by an "overline" style.
- **Line height 1.6 for body.** Arabic has tall ascenders and deep
  descenders (ي، ج، ع); 1.4 clips diacritics.
- **Western digits, tabular.** Prices, codes and phone numbers are data;
  `R-K3F9A` and `9639…` are copied into WhatsApp as-is. Every figure that is
  compared uses `FontFeature.tabularFigures()`.
- **Codes and phone numbers are LTR islands** inside RTL text, wrapped so
  `R-K3F9A` never renders as `K3F9A-R`.

---

## 5. Space, shape, motion

Shared with Drivio on purpose: one person's portfolio should feel like one
hand made it.

- **4pt grid.** Screens inset 20; cards pad 16; sections separated by 28.
- **Radius 8 / 12 / 16 / 20.** Cards 16. Pills only for badges.
- **Flat surfaces, hairline borders.** Shadows only on things that float.
- **No ink ripples.** Spring press on cards and buttons, a quiet highlight
  on rows.

### Motion

| Rule | In practice |
|---|---|
| Springs for anything the finger touches | `Pressable`: critically damped press, 12% bounce release, reverses mid-gesture |
| Ease-out for anything arriving | Material 3 emphasized decelerate; exits shorter |
| Short | press 120 · state 200 · move 320 · enter 420 |
| Once | `Reveal` entrance plays on first build only |
| Meaningful | Moving an order to the next stage visibly moves it: the row slides out of its tab, the counts roll |
| Optional | Every primitive respects the OS "remove animations" setting |

---

## 6. Self-review checklist

- [ ] Exactly one dominant element on the screen?
- [ ] Is anything coloured that is not attention or the primary action?
- [ ] Loading / empty / error / content all built?
- [ ] Empty states say what to do next?
- [ ] Figures tabular, codes and numbers LTR?
- [ ] Any letter-spacing on Arabic text?
- [ ] Holds at 320px wide and 200% text scale?
- [ ] Dark mode designed, not inverted?
