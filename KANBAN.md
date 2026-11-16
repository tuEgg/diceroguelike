# Tides of Fortune: KANBAN

> Repo: `C:\Users\Jared\Projects\TidesOfFortune`, branch `main`, pushed to GitHub. `file:line` references on open cards come from the 2026-11-15 audit and may have drifted by a few lines.
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
| H07 | **Web build smoke test**: export HTML5/GX, upload privately to itch.io, list what breaks | Surfaces (`draw_wonky_rectangle`), shaders, file saves, fonts and resolution are the usual web trouble spots. Do this early so web problems are fixed alongside other bugs. |

---

## 🧪 IN TESTING: waiting for Jared's playtest

| Batch | Cards | Branch / commit | Status |
|---|---|---|---|

Nothing is waiting for a playtest right now.

## 🐞 BUGS: P0 crashes, softlocks, lost runs

| ID | Bug | Where | Size |
|---|---|---|---|

All known P0 bugs are fixed, see DONE.

## 🐞 BUGS: P1 rules behave wrongly

**Combat core**
| ID | Bug | Where | Size |
|---|---|---|---|
| B33 | Intel level is only recalculated at turn start, so intel gained mid-turn never raises the level (*"intel 4 doesn't add the 3rd die"*) | `oCombat/Step_0.gml:164-177` | S [L] (design call: see Q3) |
| B36 | `"None!"` in `get_slot_stats` makes its condition always true. Left alone on purpose: it looks like a deliberate switch-off, and removing it would change how neutral dice count in a slot. Needs Jared's call. (The doubled `is_slot_exclusive` check was fixed in batch 2.) | `scCombatScripts.gml` | S [C] |

**Dice / keepsakes / items**
| ID | Bug | Where | Size |
|---|---|---|---|

**Map / events / bounty / workbench**
| ID | Bug | Where | Size |
|---|---|---|---|
| B69 | Intro cutscene replays every launch (`seen` isn't saved) | `oCutsceneManager` | S [C] |

**Save / load**
| ID | Bug | Size |
|---|---|---|

## 🐞 BUGS: P2 UI / polish

| ID | Bug | Where |
|---|---|---|
| B82 | `draw_outline_text` coloured mode wraps every word and ignores halign/alpha. `queue_tooltip` changes the caller's font | `scHelpers.gml:290-426` |
| B83 | Fixed 1080p coordinates break at 1440p: shop, bounty, tools, cutters hitbox, cutscene, backgrounds, particle targets | see audit notes |

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
- F02 **Rethink what happens between pages (Jared, 2026-11-17).** Today a finished spread offers "heal 25% or gain a core" (the design doc says 20% heal), and the workbench can be visited after every node from a map button. Jared wants to improve the between-page choices and decide whether the always-available workbench should stay as it is. Design not started.
- F03 Elite/boss chest reward
- F04 Starting choice (die + core) at run start *(classes cut, 2026-11-15)*
- F05 Death / win screens, run summary, die roll-history stats page
- F06 Chapters, what's left: real art for the chapter tab, a second boss (chapter 2 reuses Barnacle Titan), a story tie-in for the chapter break, and balancing the chapter difficulty growth (+50% health, +3 attack and block per chapter, macros in scMap).

**Combat clarity** (the most common playtest feedback)
- F10 Always show the enemy intent *type*; intel reveals the numbers
- F11 Enemy targeting indicator; floating arrows at intel ≥ 6
- F13 Slower / configurable action speed (Jack)
- F14 Colour-blind-safe palette (Jack can't tell the blues apart)
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
- F34 Tutorial path (fight 1 has no intel → intel die reward → fight 2 teaches intel)
- F35 Pause menu (Resume / Settings / Main Menu)

**Juice**
- F40 Individual Balatro-style trigger animations per die
- F41 Room transitions, death animation, enemy sprites, particles for coins/potions/sacrifice
- F42 Unique visual per die

**Art direction (parked, Jared wants to discuss later)**
- F50 Decide an art style for the game. Jared isn't an artist and wants to explore AI-assisted art workflows (he's been following r/aigamedev). Covers dice, enemies, map/book, UI and backgrounds. Don't start until he raises it.

---

## ❓ OPEN QUESTIONS (design decisions blocking work)

- Q1 What is "done" for the friends-and-family build? Leaning towards 1 act + boss, but deck evolution over 3 acts (like Slay the Spire) matters to the feel. Scope may grow now that Claude is helping. *Open.*
- Q3 Intel redesign (incl. B33): **parked until after bug fixes, the debug menu and the world map.**
- Q7 Resolution targets: just 1080p + 1440p, or arbitrary? (decides how much layout work T07 needs)
- Q8 Between pages: what should the choices be, and should the workbench stay available after every node? (see F02)

## 📌 DECISIONS

- 2026-11-15 **Action queue:** settled as "permanent dice eject on their second turn". Other ideas stay in the notes.
- 2026-11-15 **Map lock stays.** It's a design pillar: "pick 1, lose 1, gain the last" choices like the rewards. Look for more places to use it.
- 2026-11-15 **Scope cuts:** no four Act III regions, no 3 classes (F04 classes removed). **Alignment stays** in this build (F32).
- 2026-11-15 **Platform:** a web build on itch.io for early playtests (keep exe as the dev/reference build); Steam is the long-term goal. See H07.
- 2026-11-16 **Bounty board:** two bounties are offered, on purpose (Jared likes the choice). The potion on the bounty board is free.

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
