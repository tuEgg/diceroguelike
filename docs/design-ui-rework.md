# UI rework: design direction

Branch `feature/ui-rework` (off `dev`, 2026-11-19). Jared gave Claude a free hand to make the whole UI thematic, clear and
uncluttered. This is the direction, for approval before any screen changes.

**See it:** `docs/mockups/ui-style-tile.html` (open in a browser): a before/after of the combat screen, the palette,
type and components. It was reviewed once by a second designer pass (contrast, colour blindness, feasibility) and revised.

## What I read, and what I took from it

- **Balatro** is praised for being simple "from layout to wording", leaving white space, and for juicy feedback synced
  with sound; its one criticism is information it hides.
- **Slay the Spire**: a clutter-free screen and colour-coded cards that say their job at a glance; its devs spent days
  on single buttons. Polish lives in the small things.
- **Diegetic UI** (Inscryption, Dead Space, Outer Wilds): put information on things in the world, but sparingly, never at
  the cost of legibility; keep a plain fallback. Non-diegetic parts can still inherit the world's style.
- One palette, one style, consistently; check every colour for colour-blind players.

## The idea: the captain's logbook, on the chart table at dusk

- **The table** is the backdrop of a fight, dimmed and cooled toward dusk. Only the backdrop: you, the enemies, dice and
  paper keep full colour.
- **Paper** is anything you read or choose: slot tickets, intent tags, cards, panels, the book. Parchment, ink text, a
  torn edge, a soft shadow.
- **Slate** is the quick whisper: tooltips and the die tip. Dark ink-blue with a cream rule.
- **Ink** is the one magic: insight, the quill, the ink view. Gold ink only ever means insight.

## Rules

1. **The commit or advance action is bottom right** (End Turn, Embark, Continue, Take) and is the brightest paper on the
   screen in a brass frame. Choices that are equals (event options, cards) sit in the content, not as primaries.
2. **Numbers are the loudest thing.** Rolls, slot totals, intents, damage and HP in Lato Black at 20/32/48; words smaller.
3. **Per region, show only what you need without touching anything** (per enemy: figure, intent, HP; per slot: name,
   total, bonus, dice). Everything else waits for hover; the compact die tip is the model.
4. **Colour means one thing.** The four action pigments only mean their action; gold only means insight. "Can't" is shown
   with a glyph (padlock, strike) and ink, not with red.
5. **Every colour has a shape too.** Action glyphs (sword, shield, heart, eye) on dice, slots and intents. The pigments
   also step clearly in brightness, so they're distinct in greyscale.
6. **Four text sizes, three numeral sizes**, nothing in between and nothing under 14 (20 on the table) at 1080.
7. **Every interaction answers**: hover lifts, press sinks, stamps land, numbers count up, with a sound; one set of
   timings (0.12 / 0.25 / 0.5 s) everywhere.
8. **Never cover what you're pointing at**: tips open beside or above the thing, never over the hand or queue.

## Palette

| Role | Colour | Text on paper | Notes |
|---|---|---|---|
| Ink | `#2A1D12` | | text, outlines, routes |
| Parchment | `#E7D6B0` | | paper surfaces |
| Paper shade | `#C9B48A` | | edges, pressed |
| Slate | `#1A1E28` | | tooltips |
| Cream rule | `#E2D4B0` | | lines on slate |
| Brass | `#C9A060` | | the primary's frame, coins, play studs (not gold: gold is insight) |
| Attack | `#B33A22` | `#9A2E1C` | darkest pigment |
| Heal | `#3C9A68` | `#2C6E4A` | |
| Block | `#6FA8E8` | `#1F4F8F` | |
| Insight (gold ink) | `#F2D24A` | `#6E520A` | lightest pigment; bright gold only on slate or the table |
| Neutral (bone) | `#E9E0CC` | | told apart by material and ink outline |
| Danger | `#6E1E18` | | can't be undone, always with a glyph |

Light pigments (block, insight, bone) get ink pips; dark ones (attack, heal) get cream pips.

## Type

| Size | Font | Use |
|---|---|---|
| Title 48 | Charter | screen titles (rare) |
| Heading 24 | Charter | panel and card headings |
| Body 16 | Charter | most text |
| Small 14 | Charter | descriptions, tips (nothing smaller) |
| Numerals 48 / 32 / 20 | Lato Black | totals and intents / HP and gold / bonuses and counts |

`ftBig` (20), `ftBiggest` (32), `ftDescriptions` (12), `ftSmall` and `ftTiny` (Lato 10 and 8) go. Fonts are re-made as
SDF fonts so the sizes stay crisp when the game is scaled to a small window.

## Components (`scUI`, grown from combat, not built in the abstract)

- **Paper panel**: a nine-slice parchment sprite with a torn edge, plus a pre-blurred nine-slice shadow (procedural torn
  edges every frame would be costly and inconsistent). Parchment grain is a tiled sprite.
- **Button**: paper with an ink border; the primary is the brightest paper in a brass frame; danger is dark red with a
  glyph. States: idle, hover (lift), pressed (sink), disabled (faded, its reason on hover), selected, locked (padlock).
- **Ticket** (slot), **tag** (intent), **card** (die, keepsake, potion, offer: one layout everywhere), **tip** (slate),
  **roundel** (keywords, keepsakes, glyphs), **stamp** (Taken, Built, Victory: ink on paper, lands with a thud).
- **Tween timers** for lifts, stamps and count-ups (a small helper in `scUI`).

## Resolution and builds

- Laid out at 1920x1080, scaled to the window (as now); 1280x720 is the smallest we design for: nothing on the table under
  20 px at 1080 so it stays readable there.
- Dimming and desaturating the backdrop is a shader on the background layer (the `shInk` set-up shows the way); checked
  in the HTML5 export, with a plain darkening fallback.
- Every before/after gets a greyscale and a deuteranopia check.

## Order (each step a commit with before/after screenshots; the branch stays mergeable)

1. **Combat as the vertical slice**: palette and type tokens, then ticket, tag, tip, button and die glyphs, built into
   `scUI` as combat needs them. The backdrop shader, HP bars, top bar, tray, satchels, End Turn bottom right.
2. **Cards everywhere**: bag, shop shelf, rewards, the quartermaster and the bounty board on one card.
3. **Map**: top bar, draft heading, strait labels and stops in the same paper and ink.
4. **Rooms**: events as a logbook entry with inked choices; shop as a counter; workbench; treasure.
5. **Menus**: main menu, pause, settings, voyage summary on paper.

## Signature moments (where the logbook becomes literal)

One polished moment beats uniform tidiness. Candidates, after the slice: the queue resolving writes itself in ink with
numbers counting up; victory is a stamp on the day's log entry; the ink view bleeding across the table (already built).

## Out of scope for now

New art for dice, enemies and backgrounds (F50, F42), and sound design. Hooks left for both.

## Progress

- **Combat, part 1 (F130):** palette and glyphs (`scUI`), dimmed backdrop and felt tray (oBackgrounds), slot tickets, the new-slot place, intent tags, HP bars, End Turn bottom right, discard pile beside the draw bag.
- **Combat, part 2 (F131):** the top bar as a dark logbook strip (health, gold, item wells; the voyage label and pages counter dropped), the inkwell beside the player.
- **Cards (F132):** one paper card for the bag, dice picker, quartermaster and fight dice rewards (`draw_bag_card`, `offering_card_draw`); `ui_paper_text` and `ui_text_on_paper` for ink text with dark colour-coded words; ink distributions.
- **Map (F133):** the draft heading on a paper label (`ui_label`), Embark as the bottom-right commit (`ui_primary`, which wraps `ui_primary_button` with input), inked sea-stop names, the chapter end on a paper page.
- **Rooms (F134):** events as a logbook entry (paper page, inked heading and choices); every room's way out is the bottom-right `ui_primary` "Continue". The shop shelf keeps its dice on the shelf art (cards would not fit the shelves).
- **Menus (F135):** every kit button is paper and ink (`ui_button`, and `draw_gui_button` hands kit-coloured buttons to it): paper for plain choices, a brass-framed bright paper for the primary, dark red for danger, slate for quiet. Decision: windows (settings, pause, bag view, voyage summary) stay slate like the tooltips: paper is for what you read in the world (cards, pages, tickets, tags), slate for the game's own chrome. The dice picker's Confirm is bottom right.
- **Still to do:** Small 14 and the numeral fonts (IDE, below).
- **Needs Jared in the IDE (fonts can't be made outside it):** set `ftDescriptions` to 14, add Lato Black numeral fonts at 20, 32 and 48, and tick SDF on the Charter and Lato fonts so they stay crisp in small windows. Until then `ui_numeral` scales ftDamage.
