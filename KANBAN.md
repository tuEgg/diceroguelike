# Tides of Fortune: KANBAN

> Repo: `C:\Users\Jared\Projects\TidesOfFortune`, pushed to GitHub. **Branches:** `main` = live on itch.io (tag `v0.1.1`; hotfixes become v0.1.2...), `dev` = v0.2 in progress (see CLAUDE.md). `file:line` references on open cards come from the 2026-11-15 audit and may have drifted by a few lines.
> **Work order (agreed):** 1. bug-fix batches → 2. debug menu (done) → 3. finish the world-map rework → 4. revisit intel.
> **Workflow:** Claude batches fixes into commits with a test checklist. Jared play-tests, gives feedback and approves. Nothing is merged or pushed without approval.
> **Keeping this board current:** it is updated in the same commit as the work. A card stays in its bug or debt section while open, is listed in the IN TESTING table while its batch waits for a playtest, and moves to the DONE table once Jared approves the merge.
> Audit date: 2026-11-15. Tags: **[C]** = cause seen in code, **[L]** = likely, needs repro in-game.
> Size: S (< 1 session) · M (1–3 sessions) · L (a refactor arc).

**How to use:** move cards between the columns. IDs are stable, so commits can reference them (e.g. `fix B07`).

---

## 🔥 NOW: Housekeeping (before any code)

| ID | Task | Notes |
|---|---|---|
| H11 | **Reminder for Jared:** the shop's exit door is drawn twice (it's in the room background and is also the exit object's sprite). Remove it from the background. | Jared, art |
| H09 | **itch.io playtest build** live at https://tuegg.itch.io/tides-of-fortune (v0.1.1, tagged on main). Collecting feedback; fixes go out as hotfixes (v0.1.2...). | Jared, ongoing |

**Waiting for playtest feedback** (agreed 2026-11-17; on 2026-11-19 Jared started v0.2 on `dev` with items 1-4 below, now batch 17)
1. Game feel: room transitions (F65) and trigger animations (F40).
2. Content gaps: stub keepsakes (F22), stronger consumables (F24), Giant Conch (F20).
3. Between-pages choices, the rest of F02 (design talk first).
4. Tech debt: one effect dispatcher (T03), input out of Draw GUI (T06).

---

## 🧪 IN TESTING: waiting for Jared's playtest

| Batch | Cards | Branch / commit | Status |
|---|---|---|---|
| 19: rolled dice prototype (phase 1) | F79, F80 | `feature/rolled-dice` (off `fix/v02-feedback`) | **Ready to test. A prototype: don't merge until we've talked it through.** Dice roll when dealt and show their numbers; slots show live totals; take dice back; a free reroll and redraw each turn; End Turn discards everything; two empty starting slots; new slots from dice adding up to a number; the crew flees when an elite or boss falls. Rules in `docs/design-rolled-dice.md`. |
| 18: v0.2 feedback | B123, B124, F75, F76, F77, F78 | `fix/v02-feedback` (off dev) | **Ready to test.** Chainmaster's Anchor fix, a safety net for invisible dealt dice, debug runs start with 50 gold, normal enemies about 20% less health, used tools linger then grey out, bag view sort and filter. |
| 17: v0.2 depth and feel | H10, T03 (dice), F20, F21, F23, F24, F02, F65, F15, F40 | `dev` | **Ready to test.** Version number in the menus; one effect dispatcher for dice; Giant Conch moves; 3 new dice, 2 new events; stronger potions with how-to-use tooltips; spread end offers Heal plus two rolled choices; ink-wash room transitions; keepsakes and dice show when they fire. |

**Batch 19 test list (`feature/rolled-dice`, the prototype)** The guided first fight is off on this branch (it teaches the old rules); a one-time tip explains the new ones in your first fight. Dice and keepsakes haven't been reworked for the new rules yet (that's phase 2), so judge the feel of the loop more than any one die.
- F79 Dice in hand show the number they rolled (big, in the middle; keyword icons move small to the bottom edge). Hover: the title says "rolled N" with its range. Accurate dice have already rolled twice and kept the higher.
- F79 (round 3) In fights, dice are drawn in code with real pips, keeping a shape per size: coin a circle, d4 a triangle, d6 a square, d8 a diamond, d10 a pentagon, d12 a hexagon. 1-9 show as pips, 10 and up (and 0) as a numeral. Light pips on red, dark on yellow/green/blue/grey. Keyword icons sit small just above a die in hand. The bag view, shop, workbench and rewards still use the old sprites.
- F79 (round 3) As each die is dealt it tumbles while it flies out of the bag, faces flicking, then lands square on its roll with a pop. A reroll tumbles in place. A die taken back from a slot doesn't tumble (same roll). The row above the bag is gone.
- F79 (round 3) Dice in slots and on the new-slot tile are small pip dice too (a little further apart). The corner badge now includes keepsake bonuses as well as slot bonuses, so pips + badge = what it does. Once a die has resolved, its pips show what it did.
- F79 (round 2) No size rule: any die can join a slot of its type (a d4 after a d6). Coins have no special case any more (they're still free to play).
- F79 Fights start with two empty slots. The first coloured die played into one picks its type for the turn; after End Turn both are empty again.
- F79 A slot shows its exact total once its dice are in (with keepsake and slot bonuses), not a range. Each die icon above it shows its number with bonuses. At End Turn the dice do exactly those numbers (unless a keepsake makes a die roll twice, like Navigation Chart: it rolls once more and keeps the higher).
- F79 Click a die you played this turn (in a slot) to take it back: it flies to your hand with the same number and you get the play back. Taking the only coloured die out of a starting slot also returns any generic dice in it. Dice with their own "when played" effect (Invisible, Deepdiver, Echo, Harvest) can't be taken back (hover says why). Playing a die again after taking it back doesn't fire "when played" keepsakes twice (Protective Rigging, Eye patch).
- F79 Right-click a die in hand: it rerolls, once per turn ("Reroll used" if you try again). The first die you drop on the discard pile each turn draws a new one; later discards just discard. Both show above the discard pile and grey out when used.
- F79 End Turn: everything you played goes to the discard pile, except sticky dice.
- F79 The new-slot tile says "New slot", what its dice add up to and what they need ("5 / 6"), with "2+ dice" under it. Dropping a die there uses a play (coins free). Its dice sit above it with their numbers; click one to take it back. With 2 or more dice adding up to the number (slot 3: 6, slot 4: 9, slot 5: 12...; Cursed Heart +3), the slot is built: it keeps all their types (red + blue = an Attack/Block slot, right-click switches), and those dice go to the discard pile. "When sacrificed" dice effects fire then (Bolster, Barrel...). Dice left on the tile at End Turn are discarded.
- F80 Elite fights: kill the elite and the others flee (fade away, no gold), and you win. In a kill/spare elite fight only the elite gets the choice. Boss fight: the boss falling makes any others flee too.
- Things to tell me: does the turn feel like more decisions? Is 6 / 9 / 12 the right cost for new slots? Is a reroll plus a redraw each turn too generous? Do you miss dice staying in slots?

**Batch 18 test list (`fix/v02-feedback`)**
- B124 Chainmaster's Anchor with a Tidebreaker die: in the first slot (no block slot before it) the Anchor doesn't pop and nothing doubles. After a block slot, Tidebreaker's +2 becomes +4 (once per turn; the Anchor pops then). Other keepsake bonuses (Weapon Polish...) are no longer doubled with it.
- B123 Dealt dice always show. If a die ever ends up off screen, or hasn't settled 3 seconds after being dealt, it's put back in the hand area. (Tell me if a hand ever goes missing again: which turn, which enemies, and where the dice flew from when you ended the turn.)
- F75 A debug run (F6) starts with 50 gold like any other (F1 > Run still adds gold).
- F76 Normal enemies have about 20% less health (Ruffian 18, Deckhand 23, Thug 28, Kraken 20...). Elites and the boss are unchanged. Early fights should end a turn or two sooner.
- F77 Workbench: after a tool crafts, it stays in your hand for half a second in its last pose (drill down, hammer mid-smash, cutters closed), then slides back to its spot greyed out. It can't be picked up again (hover says "(used)"); the Craft button doesn't shake while you're still holding. A core still can't be picked back up mid-drill.
- F78 Bag view (the bag, the discard pile, and the dice picker): above the panel on the right, filters with counts (All, Attack, Block, Heal, Insight, Generic; multitype dice count in each of their types) and a "Sort:" button cycling Bag order, Type, Size (biggest first), Rarity (rarest first), Name. Clicking them doesn't close the bag; scrolling resets to the top. A long picker title on the left doesn't overlap them.

**Batch 17 test list (on `dev`, v0.2.0-dev)**
- H10 Main menu: "v0.2.0-dev" small and faint in the bottom-right corner (not overlapping anything; hidden under Settings). Pause menu: the same in the panel's top-right corner, clear of "Paused" and the buttons.
- T03 Dice effects behave exactly as before: Warrior, Reed snap, Bilge, Squall, Tidepusher, Harvest (gold when played or ejected), Deepdiver (only when it's the die played), Echo, Invisible, Lead Line (sacrifice twice). None of them fire for other dice.
- F20 Giant Conch (F1 > Fight builder, or Elite 2): turn 1 Siren Hum (Overwhelm, your insight drops and target locks), then Shell Slam, Echo (copies your last action type: hover says what), Retreat Inward (block), sometimes Siren Hum again. 55 HP, its layers still soak 2 per hit and break with stun. Quill can reroll or halve its moves (not the first).
- F21 New dice (F1 > Dice to grab them): Gunpowder (d4 attack): when it rolls in an attack slot, every other enemy takes 2 (with one enemy, nothing extra). Tidecaller (d6 heal): a 5+ also gives 3 block and pops "Tidecaller!". Ballast (d8 block): never rolls below 4 in a fight (hover a slot with it: range 4-8).
- F23 New events (F1 > Events): "A floating crate" (60 gold, or heal 20%); "The tattooist" (40 gold: a die gains +1 min roll, refused with a message when you're short; 3 alignment; or decline).
- F24 Potions: Rigger's Tonic +2 (was +1), Corsair's Gambit at least +2 plays, Grog of Grit and Captain's Brew +3, Navigator's Brew also gives a play in a fight, Healing Flask 40%. Hover a potion in the top bar: the tooltip ends "Click it to use it" or "Drag it onto a slot in a fight to use it".
- F02 End of a spread: three choices on one panel: Heal X HP (left, always), plus two of: Gain a core, Remove a die, +1 min roll, Gain 50 gold (different each spread end), and Continue below. Greyed ones say why on hover (full health, item slots full, bag of 6 or fewer). Remove a die / +1 min roll open the bag to choose, over the new pages; the pages can't be clicked until you choose.
- F65 Every room starts under dark ink that sweeps off to the right in under half a second (map, fights, shop, events, workbench, main menu). The cursor stays visible on top. It shouldn't slow anything down.
- F15 When a keepsake fires (Looking Glass at a fight's start, Rigger, Bandage...), its name floats up yellow under its icon and fades. A summon intent (Pirate Captain's Open Barrel) shows the plain icon in orange, not the attack icon.
- F40 Dice effects that fire after a roll pop the die's name over its slot ("Reed snap die!", "Bilge die!").

## 🐞 BUGS: P0 crashes, softlocks, lost runs

| ID | Bug | Where | Size |
|---|---|---|---|

All known P0 bugs are fixed, see DONE.

## 🐞 BUGS: P1 rules behave wrongly

**Combat core**
| ID | Bug | Where | Size |
|---|---|---|---|
| B36 | `"None!"` in `get_slot_stats` makes its condition always true. Left alone on purpose: it looks like a deliberate switch-off, and removing it would change how neutral dice count in a slot. Needs Jared's call. (The doubled `is_slot_exclusive` check was fixed in batch 2.) | `scCombatScripts.gml` | S [C] |

**Dice / keepsakes / items**
| ID | Bug | Where | Size |
|---|---|---|---|

**Map / events / bounty / workbench**
| ID | Bug | Where | Size |
|---|---|---|---|

**Save / load**
| ID | Bug | Size |
|---|---|---|

## 🐞 BUGS: P2 UI / polish

| ID | Bug | Where |
|---|---|---|
| B82 | `draw_outline_text` coloured mode wraps every word and ignores halign/alpha. `queue_tooltip` changes the caller's font | `scHelpers.gml:290-426` |
| B118 | **Parked (2026-11-17).** Web build: shapes drawn in code (button panels, pips, badges, icon outlines) have jagged edges. The browser canvas is smaller than the 1920x1080 layout, so the GUI is drawn shrunk, and a web build can't turn on anti-aliasing from inside the game (desktop is fixed, B117). Fixes, best first: real art for buttons and panels (sprites are smoothed when scaled; comes with F50), or drawing the UI to a 2x surface and shrinking it with smoothing (costly, and surfaces have misbehaved on web before). | `scDisplay`, `draw_wonky_rectangle`, UI kit |

---

## 🧱 TECH DEBT / REFACTORS (highest-payoff first)

| ID | Refactor | Fixes | Size |
|---|---|---|---|
| T02 | **Buff system v2**: instances keyed by (id, permanent); a buff scales *either* stacks *or* duration (the GDD already plans this); tick once per event, outside the effect loop; source-tagged slot modifiers instead of `bonus_amount` | B21, B22, B29, B30 | M |
| T03 | **One effect dispatcher**: dice, keepsakes, items and debuffs register `handlers[$ event]`; the dispatcher does the `owner_only` uid check; fresh uid on clone | B26, B27, B43, perf | M |
| T05 | **`run` struct**: one object owns gold, HP, bag, keepsakes, items, tools, alignment and pools; `new_run()`/`end_run()` create and free everything; the save serialises this one struct with a version + RNG state | B70–72, leaks, 130 globals | L |
| T06 | **Split input/state from Draw GUI** (update in Step, render in Draw). The code currently relies on draw order for clicks and on positions computed a frame late | B63, ordering bugs | L (incremental, room by room) |
| T07 | **UI kit**: one markup format + one colour table; cached outlined text; shared `draw_die`, panel, button, scrollbar and exit-button widgets on `global.gui`; fix the `draw_wonky_rectangle` surface leak (new surfaces every frame while hovering) | B80–83, perf | M |
| T09 | **Enums instead of strings** for action types, permanence and node types (`"BLK"` vs `"BLOCK"` bugs go away) | B64, B36 | M |
| T10 | **Data tables**: `register_die()`, a cores table, an encounters table, a bounty table, `spawn_die()`, `pick_from_pool()` with empty-pool guards, an `oTool` parent for Hammer/Cutters/Drill | B07, B40, duplication | M |
| T11 | Memory hygiene (enemy lists in combat done in batch 2): CleanUp for oShopManager, treasure, bounty, world (`room_enemies`, page node lists), combat (action queue + slot lists, enemy move_history/debuffs, feed lists), oRunManager lists, event option lists | leaks | S–M |
| T12 | Per-frame performance: map `path_add` every frame; `settings.json` parsed every frame while settings is open; `clone_die` per frame in hover/workbench; `get_slot_stats`/`get_action_name` per slot per frame; 1,300 particle *instances* (Dutchman) → part system | perf | S–M |
| T13 | Delete dead code: `parse_text`, `room_to_gui_*`, ~~`add_debug_entry`~~ (removed 2026-11-16), `draw_dice_history`, `roll_id`, `global.enemy_debuffs`, `tool_list`, the deprecated "All" slot type, and the redundant deep copy in `clone_die` | | S |

---

## ✨ FEATURES: proposed vertical slice (⚠️ NOT agreed yet, see Open Questions)

Pulled from the GDD's 0.1 goals plus the playtest notes. To be cut down in discussion.

**Core loop**
- F02 **Rethink what happens between pages (Jared, 2026-11-17).** Workbench part done in batch 12 (At sea). Still open: the spread-end choices themselves. Built version (2026-11-17): the workbench becomes an "At sea" step between pages (after a page's island is done, before the next), replacing the map button. You choose which dice to take from your bag (not dealt at random), up to one per tool you own (plus a core for the Drill); each tool can be used once per visit and goes back in the toolbag after. "Sail on" skips it. Like FTL's ship upgrades between jumps, or the Slay the Spire campfire, but more often and smaller. Today a finished spread offers "heal 25% or gain a core" (the design doc says 20% heal), and the workbench can be visited after every node from a map button. Jared wants to improve the between-page choices and decide whether the always-available workbench should stay as it is. Design not started.
- F03 Elite/boss chest reward
- F05 Die roll-history stats page (death/win screens and the run summary were done in batch 10)
- F06 Chapters, what's left: real art for the chapter tab, a second boss (chapter 2 reuses Barnacle Titan), a story tie-in for the chapter break, and balancing the chapter difficulty growth (+50% health, +3 attack and block per chapter, macros in scMap).

**Combat clarity** (the most common playtest feedback)
- F14 Colour-blind-safe palette (Jack can't tell the blues apart). Action icons on dice are done (batch 12, Settings > Display); a palette change is still open
- F15 Summon intent icon, buff animation, clearer "Nav Chart fired" feedback

**Content**
- F20 Enemies: 17 now (Giant Conch is a stub) → target ~15 normals + 2 elites + 2 bosses that *work*
- F21 Dice: 37 now → target? (GDD says 100 for 0.1; the playtest list says +30)
- F22 Keepsakes: 42 now (25 rollable) → finish the stubs (Deep Lens, Bandage, Lucky Coin, Crossword)
- F23 Events: 16 now → 25; "craft your own die" event
- F24 Consumables: 10 now; make them stronger (Molly didn't use any)
- F25 New debuffs from the notes: Salt Spray, Undertow, Encumbered, Rust, Frozen, Chained

**Systems**
- F30 Shop reroll + die-removal service
- F31 Workbench: choose which dice to draw; Dye tool; multiple crafts per visit?
- F32 Alignment/compass effects that actually matter mid-run
- F33 Rarity on every item + rolled offers
- F65 **Room transitions (idea, 2026-11-17).** Today rooms cut straight over. Common choices: a quick fade through black (0.2 to 0.4 s; Slay the Spire-style, cheap and clear), a themed wipe (an ink wash or blot spreading across the page, or a page turn, fits the logbook), or a short slide. Suggestion: an ink-wash wipe into map/rooms and a fast page flip for chapter changes, both under half a second so play stays quick.
- F60 **Outguess as a class idea (parked 2026-11-17).** Jared still likes Outguess (insight rolled this turn that beats your target's number halves its move, cut from batch 8 as too complex for everyone). Keep it for a future class built around reading enemies. Classes are cut for now (2026-11-15), so don't start.

**Juice**
- F40 Individual Balatro-style trigger animations per die
- F41 Room transitions, death animation, enemy sprites, particles for coins/potions/sacrifice
- F42 **Unique sprite per die** (Jared, 2026-11-19): every die gets its own sprite, keeping roughly the same silhouette per size with different textures and details. Part of the art pass (F50).

**Art direction (parked, Jared wants to discuss later)**
- F50 Decide an art style for the game. Jared isn't an artist and wants to explore AI-assisted art workflows (he's been following r/aigamedev). Covers dice, enemies, map/book, UI and backgrounds. Don't start until he raises it. Includes real sprites for the insight states (placeholders drawn by `draw_insight_icon` in scHelpers, F51).

---

## ❓ OPEN QUESTIONS (design decisions blocking work)

- Q1 What is "done" for the friends-and-family build? Leaning towards 1 act + boss, but deck evolution over 3 acts (like Slay the Spire) matters to the feel. Scope may grow now that Claude is helping. *Open.*
- Q7 Resolution targets: settled by B83 (batch 12): the game is laid out at 1920x1080 and scaled to any 16:9 window, so new resolutions only need adding to the list.
- Q8 Between pages: what should the choices be? (The workbench is now an At sea stop between pages, F02.)

## 📌 DECISIONS

- 2026-11-15 **Action queue:** settled as "permanent dice eject on their second turn". Other ideas stay in the notes.
- 2026-11-15 **Map lock stays.** It's a design pillar: "pick 1, lose 1, gain the last" choices like the rewards. Look for more places to use it.
- 2026-11-15 **Scope cuts:** no four Act III regions, no 3 classes (F04 classes removed). **Alignment stays** in this build (F32).
- 2026-11-15 **Platform:** a web build on itch.io for early playtests (keep exe as the dev/reference build); Steam is the long-term goal. See H07.
- 2026-11-16 **Bounty board:** two bounties are offered, on purpose (Jared likes the choice). The potion on the bounty board is free.
- 2026-11-16 **Intel rework:** enemy intents are always shown. On screen intel is called **Insight** (Ink was tried and felt unclear); the code keeps INTEL. Three states, named like reading an old logbook: **Faded** (0+, see ranges), **Legible** (5+, exact numbers), **Quill** (10+, rewrite one intent per turn; you choose to change it, the enemy picks the move). Below 0 (Overwhelm) the page is **Blotted** and intents are hidden. Insight dice roll in the queue and count next turn (a this-turn-only version was tried and reverted: dice could never reach Legible or Quill in time). Outguess (a this-turn effect: beat your target's number to halve its move) was built and cut: too complex. Rolling on play was tried and reverted. You can always change target, except while Overwhelmed.

---

## ✅ DONE

**Fixed, play-tested by Jared, merged to `main` and pushed**

| ID | Bug or task | Batch | Merged |
|---|---|---|---|
| B01 | **Pressing R restarts the game in release builds** | Batch 1: crashes and softlocks | 2026-11-15 |
| B02 | Dying outside combat crashes: events take HP with no floor, then the code reads `oCombat.state` when no oCombat exists | Batch 1: crashes and softlocks | 2026-11-15 |
| B03 | Deleting an item in the workbench crashes: `items[i] = undefined` is followed by a read of `items[i].type` | Batch 1: crashes and softlocks | 2026-11-15 |
| B04 | Flying Dutchman softlock: swapped shop nodes aren't in `all_nodes`, so the next node is unreachable | Batch 1: crashes and softlocks | 2026-11-15 |
| B05 | Barnacle Titan's Barnacle Bind move has no `duration`/`amount`, but the DEBUFF case reads them | Batch 1: crashes and softlocks | 2026-11-15 |
| B06 | Sirens: nested `fail_sirens` is probably not visible from the option methods | Batch 1: crashes and softlocks | 2026-11-15 |
| B07 | Reward generators can loop forever when a filtered pool is empty (core+rare, coin) | Batch 1: crashes and softlocks | 2026-11-15 |
| B08 | Encounter pools never refill, and a bounty shrinks `possible_elites` to 1, so you can get empty fights | Batch 1: crashes and softlocks | 2026-11-15 |
| B09 | Leaving the workbench with a core in slot 2 deletes the core | Batch 1: crashes and softlocks | 2026-11-15 |
| B10 | Persistent coin/alignment particles outlive the run → crash on `oRunManager.credits` | Batch 1: crashes and softlocks | 2026-11-15 |
| M01 | Islands are now saved with each page (Continue would have crashed). | World-map save fixes | 2026-11-15 |
| M02 | Saves carry a version number; older saves are ignored so Continue never loads an incompatible file. Pages/spreads cleared and the book's page art are saved, and the book shows already open when resuming. | World-map save fixes | 2026-11-15 |
| M03 | The book holds on its last spread instead of crashing past spread 8 (stop-gap until acts exist, see F06). | World-map save fixes | 2026-11-15 |
| M04 | Island surfaces are freed on cleanup and rebuilt when the resolution changes. | World-map save fixes | 2026-11-15 |
| T14 | **Seeded debug harness**: start any fight/event/shop with chosen dice and keepsakes from a debug menu. This is the main thing that makes Claude-driven fixes verifiable | Debug menu | 2026-11-16 |
| T01 | **Per-fight enemy instances**: deep-copy the enemy and its moves in `add_enemy_to_fight`, never write to templates | Batch 2: combat rules | 2026-11-16 |
| B20 | **Enemy templates are shared, not copied per fight.** Shiny Scales does `owner.data.moves[ | Batch 2: combat rules | 2026-11-16 |
| B21 | Debuff duration ticks and removal happen *inside* the per-effect loop: a debuff with 2 effects ticks twice, and can delete its neighbour | Batch 2: combat rules | 2026-11-16 |
| B22 | `apply_buff` merges by `_id` only, so temporary Might merged into permanent Might becomes permanent (and vice versa). Re-applying doesn't refresh `remove_next_turn` | Batch 2: combat rules | 2026-11-16 |
| B23 | Code writes `remove_next_turn` onto the shared move.debuff template | Batch 2: combat rules | 2026-11-16 |
| B24 | Enemy Might never applies (the `owner != target` gate fails for enemy rolls). Captain's "Command" (target other) buffs itself. Elizabeak's −2 Might on the player shows as a Might icon with no number ("player gains Might" report) | Batch 2: combat rules | 2026-11-16 |
| B25 | Block absorbs the raw `amount` instead of the post-modifier `final_damage` | Batch 2: combat rules | 2026-11-16 |
| B26 | Cloned dice keep the same `uid`, so duplicates (Echo, Mirage, a second purchase) double-fire Squall, Reed Snap, etc. | Batch 2: combat rules | 2026-11-16 |
| B27 | Warrior die's `after_roll_die` has no uid check: *any* die that rolls its minimum becomes its maximum | Batch 2: combat rules | 2026-11-16 |
| B28 | "Hit all enemies" loops index `room_enemies` by `enemies_left_this_combat`, so they hit corpses and skip living enemies | Batch 2: combat rules | 2026-11-16 |
| B31 | Enemy pseudo-random move picker: the `all_same` loop only compares the last item, and 1 move of history counts as "all same" | Batch 2: combat rules | 2026-11-16 |
| B32 | Target failsafe uses `>` instead of `>=`. An EXIT enemy doesn't shift `enemy_target_index` when target > e | Batch 2: combat rules | 2026-11-16 |
| B40 | **Accurate and Splash dice are never offered** (Echo and Last Stand are registered twice instead) | Batch 2: combat rules | 2026-11-16 |
| H06 | Sign in to GitHub on the first push | Housekeeping | 2026-11-15 |
| B30 | Reserve and Barnacle Bind *assign* `bonus_dice`, which wipes Pickled Cucumber, Kraken's Grasp and Medallion | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B43 | Lead Line re-fires the full dispatcher, so *all* keepsakes double-trigger | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B44 | Chainmaster's `first_die` is never reset | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B45 | Crossword Puzzle is dead (checks the slot type for "None"). Lucky Coin compares a number to `"2"` | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B46 | Cannon Splitter fires on enemy attacks and per die rather than per slot | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B47 | Consumables: Artisan's Ember picks no die with chance 1/(N+1); Mirage Brew is off by one; Navigator's Brew reads oCombat in the workbench; Bilge-Purge uses `=` not `+=` | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B48 | Dome core is named "Binary Core", which also restores the wrong core on load | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B49 | `oRunManager.turn_count` is stuck at 1, so Squall, Fogcaller and Invisible always draw Favourites first | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B50 | Room-start temp-die cleanup deletes while iterating forward and skips dice | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B52 | Assassin's description ("+1 min") doesn't match the code (flat bonus) | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B61 | Can't take the bounty potion: the price check is invisible, with no error and no full-slot message | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B62 | Duplicate keepsakes: the bounty reward stays in the pool, and owned keepsakes are never filtered out (shop, rewards, after Continue) | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B64 | Sirens "Block your ears" checks `"BLOCK"`, but dice use `"BLK"` | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B65 | Broken Sails "Repair" deletes `items[rand]` instead of `items[item_pool[rand]]` (free keepsake) | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B66 | Shipwright gives a duplicate tool (not removed from `master_tool_list`) | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| B68 | Wrong arguments: `clamp(0,x,100)`, `object_exists(oCombat)`, `room = rmMainMenu` | Batch 3: keepsakes, consumables, events, bounty | 2026-11-16 |
| F01 | Boss node and boss reward: boss on the 8th spread of each chapter, choice of boss keepsakes | Chapter ending | 2026-11-16 |
| M05 | Islands and node icons turn with the page: the right-hand page squashes in towards the spine as it lifts, and the left-hand page is covered as the turned page comes down. | Page-turn polish | 2026-11-17 |
| M07 | The boat's position is saved, so Continue puts it back where it was moored. | Page-turn polish | 2026-11-17 |
| B73 | Continue rerolled the node you were in: nodes now remember their fight or event, and the game saves as you enter a node | Continue fix | 2026-11-17 |
| B74 | Shops, treasure rooms and the bounty board rerolled on Continue: they now roll once and are saved | Continue fix (rooms) | 2026-11-17 |
| B70 | Run state that wasn't saved (luck, Dutchman, voyage, bonus dice, draft on offer, seen events, keepsake and tool pools) is now saved | Save gaps | 2026-11-17 |
| B71 | Continue carries on the random sequence (each save reseeds and stores the seed) | Save gaps | 2026-11-17 |
| B72 | Save file fixes: duplicate keys, load guards, Toolbelt item slots | Save gaps | 2026-11-17 |
| H05 | Old debug letter keys use `DEBUG_TOOLS`, so they work whenever run from GameMaker | Tabs, hotkeys, intro | 2026-11-17 |
| B29 | Slot bonuses overwrote each other: now separate bonuses tagged by source | Slot bonuses | 2026-11-17 |
| B75 | Slot bonus per die vs per slot: every die unless the description says otherwise; Repeater Rail first die only; labels show true totals | Slot bonuses | 2026-11-17 |
| F16 | Slot bonuses shown on the dice as a "+N" badge (simple version) | Slot bonuses | 2026-11-17 |
| B34 | Negative intel draws an almost-full ring. Intel above 12 overflows it | Batch 4: quick bug sweep | 2026-11-17 |
| B51 | Multitype dice don't show their colours in the bag, shop, particles or combat tiles (callers pass `action_type`) | Batch 4: quick bug sweep | 2026-11-17 |
| B60 | (Two bounties is intended, decided 2026-11-16.) Reroll doesn't clear `active_bounty`. "Elite 3" is labelled "Unfinished Elite" | Batch 4: quick bug sweep | 2026-11-17 |
| B63 | Workbench drop doesn't register: a die already in a slot is rejected, and the hover flags lag a frame (set in Draw, read in Step) | Batch 4: quick bug sweep | 2026-11-17 |
| B67 | Albatross text says −7 alignment, the code applies −4. 29 options still say "Result" | Batch 4: quick bug sweep | 2026-11-17 |
| B80 | Bag hover box uses `bag_h` for its width. Bag text offsets switch on the wrong `image_index`. The rarity colour is overwritten | Batch 4: quick bug sweep | 2026-11-17 |
| B81 | Scrollbar drag sticks (room vs GUI y, `m_grab_y` never reset) | Batch 4: quick bug sweep | 2026-11-17 |
| B84 | Rest heals with `round()`, potion uses `ceil()`, so they're inconsistent | Batch 4: quick bug sweep | 2026-11-17 |
| B41 | Hover descriptions are wrong after upgrades: static text, the hover preview uses slot −1 (type bonuses never show), duplicated oDice fields drift, and `get_dice_output(read_only=false)` runs every frame and fires keepsake side-effects | Batch 5: dice text from data | 2026-11-17 |
| B42 | `string_has_keyword` is fragile (colons, single sentences, the "Favourite." prefix). `get_keywords_in_string` doesn't trim at all, so Offhand/Balanced show the wrong icons | Batch 5: dice text from data | 2026-11-17 |
| T04 | **Keywords and descriptions as data**: a `keywords: []` field on dice; descriptions generated from templates (`"+{min} min"`) so upgrades update the text | Batch 5: dice text from data | 2026-11-17 |
| T08 | One placement rule, `slot_placement_check`, returning ok, action and a reason | Batch 6: placement rule | 2026-11-17 |
| B35 | Slot highlight and real placement disagreed: both now use the one rule | Batch 6: placement rule | 2026-11-17 |
| F12 | Placement feedback: a tooltip says why a die can't go in a slot, and the hint says what placing will do | Batch 6: placement rule | 2026-11-17 |
| F10 | Enemy intents always shown; insight sharpens the numbers (range when Faded, exact when Legible) | Batch 7: intel rework | 2026-11-16 |
| B33 | Intel timing settled: insight dice roll in the queue and count next turn (instant rolling and this-turn-only were tried and reverted) | Batch 7: intel rework | 2026-11-16 |
| F17 | Next-turn intents: built, then cut (removed the reason to play insight next turn) | Batch 7: intel rework | 2026-11-16 |
| F18 | Quill (10+ insight): rewrite one enemy intent per turn; rewritable intents pulse, glow and show a quill | Batch 7: intel rework | 2026-11-16 |
| F19 | ~~Outguess~~ (cut 2026-11-16 in batch 8: too complex, a minigame of its own): insight rolled this turn that beats your target's number halves its move; outguess bar under the target's intent | Batch 7: intel rework | 2026-11-16 |
| F52 | Intel is called Insight on screen; logbook states Blotted/Faded/Legible/Quill; placeholder page icons; compact panel | Batch 7: intel rework | 2026-11-16 |
| F53 | Overwhelm stays on you for your turn, lowers insight and locks your target | Batch 7: intel rework | 2026-11-16 |
| H07 | Web build: fits the browser at 16:9 on a dark page, no Exit/Resolution/double-Escape in the browser; `docs/web-build.md`, `docs/itch-launch.md` | Batch 8: web build | 2026-11-16 |
| H08 | Sounds compressed to Ogg (were ~20 MB of WAV) | Batch 8: web build | 2026-11-16 |
| F51 | Insight state icons, placeholders drawn in code without the paper (spill, outlined drop, filled drop, quill); real sprites wait for F50 | Batch 8: web build | 2026-11-16 |
| B85 | Web build went black starting a second fight: `ds_exists(undefined)` throws in HTML5; `ds_safe_exists` everywhere | Batch 8: web build | 2026-11-16 |
| B86 | Tooltips drawn in Draw GUI End, above the event window and every other window | Batch 8: web build | 2026-11-16 |
| F04 | New runs start by choosing a die + core pair again | Batch 8: web build | 2026-11-16 |
| F54 | Tutorial: progress.json, map notes, two-turn guided first fight with Skip, one-time tips, Settings > Gameplay > Tutorial next run | Batch 9: tutorial | 2026-11-16 |
| B69 | The intro plays once ever (progress.json), not every new voyage | Batch 9: tutorial | 2026-11-16 |
| B87 | Discard bag opens from the bag itself, not the top right corner | Batch 9: tutorial | 2026-11-16 |
| B88 | Tutorial End Turn outline sits round the button | Batch 9: tutorial | 2026-11-16 |
| B89 | Insight hover panel draws over tutorial notes and tips | Batch 9: tutorial | 2026-11-16 |
| B90 | Cores drop into the workbench's middle slot reliably and draw on top while carried | Batch 9: tutorial | 2026-11-16 |
| F55 | Runs start with only the Drill; the Hammer and Cutters are bought in shops | Batch 9: tutorial | 2026-11-16 |
| B91 | Deepdiver fires only when it is the die played, not for every die after it | Batch 9: tutorial | 2026-11-16 |
| F35 | Pause menu on Escape (Resume, Settings, Save and quit); freezes the fight; Settings returns to it and lost its Main Menu button | Batch 10: playtest-ready | 2026-11-16 |
| F05 | Death and victory show a voyage summary: cause, chapter and spread, run stats (saved with the run). Fixed a crash on death in the web build | Batch 10: playtest-ready | 2026-11-16 |
| F13 | Settings > Gameplay > Combat speed: Slow, Normal, Fast, Fastest | Batch 10: playtest-ready | 2026-11-16 |
| B92 | Main menu drew over Settings; it now hides while Settings is open | Batch 10: playtest-ready | 2026-11-16 |
| B93 | Navigation Chart crashed (web black screen) when the next slot was empty; Rusty Rudder could hit a dead enemy | Batch 11: keepsake crash | 2026-11-17 |
| F56 | Quill rerolls or halves an intent; intent hover says what the enemy does in words | Batch 12: playtest notes | 2026-11-17 |
| F57 | Targeting: red Target marker, click-to-target hint, first multi-enemy tip; alignment and kill/spare tips and tooltips | Batch 12: playtest notes | 2026-11-17 |
| F11 | Enemy targeting indicator (the Target marker, F57) | Batch 12: playtest notes | 2026-11-17 |
| F58 | Roll feedback: "Warrior!", roll-twice shows both rolls | Batch 12: playtest notes | 2026-11-17 |
| F59 | Workbench: Cutters layout (Dice = Basic coin + Remainder), core loss warning, tidy names and distributions, tool mouse hints, step-by-step first-visit tips | Batch 12: playtest notes | 2026-11-17 |
| F02 | At sea workbench: earned per page, choose your dice, each tool once per visit, several crafts per visit (spread-end choices still open) | Batch 12: playtest notes | 2026-11-17 |
| F61 | Spread end: page turn, then Heal X HP / Gain a random core / Continue, with reasons when unavailable | Batch 12: playtest notes | 2026-11-17 |
| F62 | Custom logbook cursor (Settings > Display) | Batch 12: playtest notes | 2026-11-17 |
| F63 | Top bar stays lit under dimming; Embark glows when ready; chosen draft pages outlined in green | Batch 12: playtest notes | 2026-11-17 |
| F64 | UI phase 1: button colours by role, main menu buttons, writing pass, logbook tooltips | Batch 12: playtest notes | 2026-11-17 |
| F66 | Tooltips sit beside the hovered thing (below the top bar for its items), keyword boxes stacked tight | Batch 12: playtest notes | 2026-11-17 |
| F67 | Shop explains failed purchases; End Turn green and breathing when your hand is empty | Batch 12: playtest notes | 2026-11-17 |
| F69 | UI kit: ui_panel, ui_divider, ui_button (shadow, press, disabled reason), Exits and Confirm on the kit, padding | Batch 12: playtest notes | 2026-11-17 |
| F70 | Plays left shown as a label and pips | Batch 12: playtest notes | 2026-11-17 |
| F14 | Action icons on dice (accessibility option); palette change still open | Batch 12: playtest notes | 2026-11-17 |
| F51 | Insight icons redrawn: dry brush, ink-loaded brush, feather quill | Batch 12: playtest notes | 2026-11-17 |
| B83 | Layout stays 1920x1080 at every resolution, so 1440p matches 1080p | Batch 12: playtest notes | 2026-11-17 |
| B94 | Enemies re-centre and glide after deaths | Batch 12: playtest notes | 2026-11-17 |
| B95 | Dealt dice never overlap | Batch 12: playtest notes | 2026-11-17 |
| B96 | A die's range shows in its tooltip title, not over its keyword icons | Batch 12: playtest notes | 2026-11-17 |
| B97 | Warrior check made sturdier (cause of a rolled 1 not found) | Batch 12: playtest notes | 2026-11-17 |
| B98 | Rigger's Tonic and Bilge-Purge drop onto slots reliably, slots pulse while carried | Batch 12: playtest notes | 2026-11-17 |
| B99 | Single Focus is first die only | Batch 12: playtest notes | 2026-11-17 |
| B100 | Bilge Die checks the total with bonuses | Batch 12: playtest notes | 2026-11-17 |
| B101 | Debug coordinates beside enemies turned off | Batch 12: playtest notes | 2026-11-17 |
| B102 | Button surfaces no longer churn (and drawn without surfaces since) | Batch 12: playtest notes | 2026-11-17 |
| B103 | Tooltip boxes measured exactly | Batch 12: playtest notes | 2026-11-17 |
| B104 | Rigger's Tonic crash after use | Batch 12: playtest notes | 2026-11-17 |
| B105 | Enemy hover keeps the intent icon; name replaces Target while hovered | Batch 12: playtest notes | 2026-11-17 |
| B106 | Die name hides on hover; compact keyword boxes | Batch 12: playtest notes | 2026-11-17 |
| B107 | Buff and debuff tooltips tidied | Batch 12: playtest notes | 2026-11-17 |
| B108 | Black flash when taking a reward die (particle created mid-draw) | Batch 12: playtest notes | 2026-11-17 |
| B109 | Workbench crash with too few dice in the bag | Batch 12: playtest notes | 2026-11-17 |
| B110 | Buttons and draft pages drawing black (panels drawn without surfaces) | Batch 12: playtest notes | 2026-11-17 |
| B111 | Splash Die never rolls below 0 | Batch 12: playtest notes | 2026-11-17 |
| B112 | Dimming lines up with the top bar; reward names wrap | Batch 12: playtest notes | 2026-11-17 |
| B113 | Bag view and dice picker draw above every window | Batch 12: playtest notes | 2026-11-17 |
| B114 | Chosen draft page outline follows the paper | Batch 12: playtest notes | 2026-11-17 |
| B115 | Exclusive dice eject whatever is in a slot | Batch 12: playtest notes | 2026-11-17 |
| B116 | Bag icon drawn above the map | Batch 12: playtest notes | 2026-11-17 |
| B117 | Smooth edges on desktop (anti-aliasing, rounder circles, minimum icon strokes) | Batch 12: playtest notes | 2026-11-17 |
| F71 | Settings, bag view, Kill/Spare and Embark on the logbook kit; buttons keep their shape while growing | Batch 13: UI polish | 2026-11-17 |
| F72 | Workbench asks you to open the bag to choose dice (prompt, bag icon, first-visit tip); top bar hoverable with the bag open; finished dice go to the bag | Batch 14: workbench bag | 2026-11-17 |
| F73 | New intro: four lines of text fading in on black (silent for now); Settings > Gameplay > Intro next run; never in a debug run | Batch 14: workbench bag | 2026-11-17 |
| B119 | Black screen drilling a Loaded core into a Harvest Die (gone after the workbench changes) | Batch 14: workbench bag | 2026-11-17 |
| B120 | Core distribution previews ignore keepsakes | Batch 14: workbench bag | 2026-11-17 |
| B121 | Cursor drawn last of all (above the bag and its darkening) | Batch 15: cursor and menu | 2026-11-17 |
| F74 | Menu cog at the top right and Tab open the pause menu (Escape stays the browser's in fullscreen) | Batch 15: cursor and menu | 2026-11-17 |
| B122 | Drilling a core crashed: the used-up Drill let the held mouse pick the core back up; cores now return only on a fresh click, crafts check their ingredients | Batch 16: drill crash | 2026-11-17 |

**Milestones**

- 2026-11-15 Full code audit; this board created.
- 2026-11-15 H01 leaked SSH key deleted on GitHub · H02/H03 repo moved off Google Drive to `C:\Users\Jared\Projects\TidesOfFortune` (Drive copy left as a backup) · H04 `.gitignore` covers keys and builds · world-map WIP saved to `wip/world-map`.
- (Healing potion rounding: already `ceil` in fddd600.)
- 2026-11-16 **Chapters (F06 core):** 7 drafted spreads then a boss spread, ribbon bookmark on the boss page, boss keepsake reward, "chapter complete" screen, chapter 2 with tougher enemies. Deep Lens replaces Looking Glass in place. Alt debug panels retired, map odds moved to the F1 Rooms tab.
- 2026-11-17 **Page-turn polish:** islands and icons turn with the page, boat position saved. A dotted route (M06) was tried and removed at Jared's request.
- 2026-11-17 **Chapter tab and debug additions:** the boss page carries a "Chapter 2" divider tab out of the side of the book (replacing the ribbon); F1 menu gains "Complete this spread" and closes with Escape.
- 2026-11-17 **Three-chapter voyage and testing tools:** a divider tab and a short page stack for every chapter still to come (Chapter 2 teal, Chapter 3 violet); the open spread stays still while turned pages build up on the left; a voyage progress track under the book (a marker per spread, a diamond per boss); beating chapter 3 ends the run with "Voyage complete"; testing hotkeys (Space kills all, H, D, N, Backspace) with an F1 Hotkeys tab; the intro is skipped when run from GameMaker, with a toggle.
- 2026-11-17 **Slot bonuses and testing tools:** tagged slot bonuses (each die or first die), hover breakdown and die badges; Rigger's Tonic is +1 per die; F2/F3/F4 game speed; F1 lists show tooltips on hover.
- 2026-11-17 **Context docs:** root `CLAUDE.md` (workflow, code map, gotchas) and `docs/context/*.md`, one per system, to orient future sessions quickly. Kept up to date in the same commit as code changes.
- 2026-11-17 **Dice as data:** every die has a keywords list that all keyword rules, icons and tooltips read; descriptions show the die's current numbers; the Coin keyword follows die size on every upgrade; hover previews show real ranges.
