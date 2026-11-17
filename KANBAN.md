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
| | Nothing right now. Jared: itch.io launch when ready (`docs/itch-launch.md`). | |

---

## 🧪 IN TESTING: waiting for Jared's playtest

| Batch | Cards | Branch / commit | Status |
|---|---|---|---|
| 12: playtest notes | F02 (workbench part), F14, F56–F59, F61–F64, F66–F70, B83, B94–B117 | `feature/playtest-notes` | **Ready to test.** Jared's 2026-11-17 playtest list: Quill reroll or halve, cleaner intent hover, targeting marker and tip, enemies re-centre after deaths, dice dealt apart, ranges in tooltips, roll feedback, Rigger's Tonic, workbench Cutters layout and tool tips, alignment/spare tips, and several rule fixes. |

**Batch 12 test list**
- F56 Quill (10 insight): click a glowing intent and two buttons appear under it, Reroll and Halve. Reroll: the enemy picks a different move. Halve: the number halves (range or exact), "Halved" shows under the intent, and the enemy's attack/block/heal really comes out at half. Forced moves can still be halved but not rerolled; buffs and debuffs can be rerolled but not halved (greyed, with a reason on hover). Clicking elsewhere puts the quill down. Once per turn.
- F56 Hover an enemy: no dice under the intent any more; the tooltip says it in words ("Attacks you for 4-9", "Blocks 6", "Attacks you for 5, then Blocks 3"), plus how to see exact numbers when Faded.
- F57 Two or more enemies: a red "Target" with arrows under your target's health bar; hovering another enemy lights it faintly and says "Click to target" ("Target locked" when Overwhelmed). Your first multi-enemy fight shows a one-time tip pointing at your target.
- B94 Multi-enemy fights: when an enemy dies the rest glide to new, centred spots and grow back to full size as they become fewer; the last one standing is centred, not pushed to a side. Summoned enemies slot in. A long action queue nudges them right without going off screen.
- B95 Dealt dice never overlap (deal a full hand several times, also after Deepdiver draws more).
- B96 Hovering a die: its range is in the tooltip title ("Inkwell Die (1-4)") and no longer drawn over the die and its keyword icons.
- F58 Roll feedback: a Warrior die that rolls its minimum shows "Warrior!" over its slot and counts as its max. A die that rolls twice shows "Rolled 2 and 5, kept 5". (B97: I could not find how a Warrior showed a 1 from the code; the check is sturdier now. If you see it again, note the keepsakes and the slot.)
- B98 Rigger's Tonic: pick it up in a fight and every slot pulses yellow; let go over a slot and its dice get +1 this turn (the slot's bonus shows). Bilge-Purge Flask works the same way. Letting go elsewhere puts it back.
- B99 Single Focus: the +1 is on the first die of a single-type slot only (hover the slot's bonus); description says so.
- B100 Bilge Die: heals 2 when the total on the die (roll plus bonuses) is even. A 6 with +1 (7) no longer heals; a 5 with +1 (6) does.
- B101 Debug runs (F6): no x/y coordinates beside enemies.
- F59 Workbench with the Cutters: the bench reads "Dice = Basic coin + Remainder", with a note under Remainder (keeps the die's effects; red if it becomes a coin and loses its core, or if the die is already a coin). Cutting a die down to a coin removes its core. A coin can't be cut (the button shakes).
- F59 Workbench: die names sit clear of the slot edges; the distribution bars sit just above the box and only for dice bigger than a coin. While a tool is in hand, two mouse hints at the bottom: left button (hold over the Drill button / click the Cut or Combine button) and right button (put the tool down).
- F59 First workbench visit (turn "Tutorial next run" on to see tips again): tip 1 points at the slots (die + core); once both are in, tip 2 points at the toolbag (click the Drill); once the Drill is on the bench, tip 3 points at it (pick up, hold over the Drill button, right click to put down). Each goes away by itself once done.
- F57 First alignment fight: a tip explains kill vs spare and alignment dice. When the Kill / Spare buttons first appear, a tip points at them. Hovering Kill or Spare explains what each does (gold, compass, bounty contract for elites).
- B102 Taking a die reward: no black flash. Buttons still look the same and grow on hover.
- B103 Hover tooltips everywhere still look right (button panels are now reused at rounded sizes).

**Batch 12, round 2 (2026-11-17 feedback)**
- B104 Rigger's Tonic no longer crashes when dropped on a slot (the item slot was read after it had been used up).
- B105 Hovering an enemy: the intent icon and number stay visible; the move name no longer appears above (it's the tooltip title). The enemy's name appears under its health bar, in place of "Target" (which hides while hovered); other enemies show "Click to target" under the name.
- B106 Hovering a die hides the name drawn under it. Keyword boxes (Coin, Sticky...) sit tight under the main tooltip, smaller, with no gap, and the whole stack stays on screen.
- B107 Buff/debuff tooltips: the description, then a grey line like "2 turns left, Strength 3" (or "Lasts all fight"); nothing about amount when it's 0.
- B108 Taking a reward die: no black flash (second try: the flying die now sets its draw depth once when created). If it still flashes, say whether it's the web build, the desktop build or both.
- F61 End of a spread: "Heal X HP" on the left page (small "Recover below deck" above), "Gain a random core" on the right ("Search the hold"), and "Continue" below. Heal is greyed at full health and Gain a core when your item slots are full, each saying why on hover. Text grows with the buttons.
- F62 Custom cursor: a parchment arrow with an ink edge; it tips forward and gets a gold glint over anything you can hover or click, and dips while the button is held. Settings > Display > Custom cursor turns it off (saved). Check it in the menu, map, fights, settings and the web build.
- Workbench: crafting now makes a sound (placeholders: a shield clang for the Hammer, rubble for the Drill, a sword swish for the Cutters). There were no tool sounds at all before.

**Batch 12, round 3 (2026-11-17 feedback)**
- B109 Workbench with too few dice in the bag (e.g. after a fight, bag nearly empty): no black screen; it deals what there is.
- F62 Cursor: no shrinking on click; it tips further forward while the button is held. No glint circle. Tooltips that follow the mouse sit down and to the right of the pointer, clear of it.
- F61 End of a spread: the page turns first (no buttons or darkening yet), then "The spread is done" with the two options either side of the book's spine and Continue below, then after choosing, "What happened next?" and the pages.
- F63 The top bar stays in full colour while the map dims (drafting, spread end, chapter complete). Fights' reward screen already did.
- F63 Embark glows and pulses green once two pages are chosen; hovering it before then says "Choose two pages first". The chosen draft pages get a thick green outline (your mockup); the locked-away one stays a dark silhouette.
- F64 UI phase 1, colours by role: green = the main go action (Embark, Resume, Save, Turn the page, Back to the menu, tutorial note buttons, Spare, Craft when ready); brown = ordinary choices and leaving (Exit buttons, Settings, Visit the workbench, Heal/Gain a core, Cancel); dark red = costly (Start anew, Kill); grey = skippable (Skip tutorial, Continue). Red/blue/green/yellow now only mean attack/block/heal/insight.
- F64 Main menu items are always drawn as buttons, not plain text until hovered. The abandon-run warning says "Start anew" / "Keep voyage".
- F64 Writing: "a die" / "1 die" / "this die" wherever one die is meant (dice and keepsake descriptions, events, prompts); the new-slot tile says "Sacrifice 1 die" or "2 dice"; an empty slot says "Empty" with no "(0-0)".
- F64 Tooltips have a logbook look: dark ink, a thin cream rule inside the edge and small diamonds at the corners; keyword boxes are plainer. Coloured words (insight, keywords) still read clearly.

**Batch 12, round 11: smoother shapes**
- B117 Desktop: edges of shapes drawn in code are smooth, not jagged: the plays pips, action icon badges, insight icons, tooltip borders, panels, buttons, the cursor. Circles are rounder. Insight icons (brushes, quill) keep their shape in the insight panel and beside intents. Check the frame rate is unchanged. (The web build can't switch this on from the game.)

**Batch 12, round 10: screen sizes (B83)**
- B83 Desktop: Settings > Display > Resolution 2560x1440 (and fullscreen). Every screen should look exactly like 1920x1080, just bigger: shop, bounty board, workbench tools and the Cutters' hit area, the intro cutscene, backgrounds, coins and particles flying to the top bar, the map, fights, tooltips, the cursor. Text may look a touch softer at 1440p (it is drawn at 1080p and scaled up). Switch back to 1920x1080: unchanged. Web: unchanged.
- F70 The "plays left" label is bigger, with bigger pips. F14 The action icons on dice are about half as big again.

**Batch 12, round 9: UI phase 3 (fight screen)**
- B116 The bag icon (bottom left) is drawn above the map, the draft overlay and room windows, everywhere.
- F70 Plays left: under the queue's start, a small "3 plays left" label over a row of pips, filled for plays left and hollow for plays used. Coins don't use one. Extra plays (Invisible die, keepsakes) add pips.
- F14 Settings > Display > Action icons on dice (off by default, saved): every die in hand and in slots gets a small round badge in its bottom-left corner, a sword, shield, heart or brush, so attack, block, heal and insight can be told apart without colour. Generic dice get none.

**Batch 12, round 8 (2026-11-17 feedback)**
- B115 An Exclusive die played into a slot that already has dice ejects them all and takes the slot, whatever the slot's type, including a slot built by sacrificing neutral dice (it used to just sit beside them). Exclusive dice still can't be sacrificed (that is the keyword's rule).
- F69 No panel behind the rewards (the rule under the title stays).
- F66 Tooltips for things in the top bar (gold, health, items, keepsakes, toolbag, compass...) appear just below the bar, lined up with the thing.
- F69 The workbench Craft label and the bounty board Re-roll label grow with their buttons; Re-roll is brown when available (blue is for block). A rule sits under the draft heading.

**Batch 12, round 7 (2026-11-17 feedback)**
- F02 Choosing dice at the workbench works: the chosen dice fly onto the bench and stay (the picker now blocks the Exit button that sat right under Confirm, which was ending the visit). Events that ask you to pick dice are protected the same way.
- F02 "Sail on" sets sail for the next stop straight away.
- F66 Tooltips sit at a fixed place beside the thing you're hovering (to its right, top-aligned; to its left near the right edge of the screen). They don't follow the mouse or stay where they started. Check enemies, intents, dice in hand, slots, top bar items, map nodes.
- F51 Brush icons tilted 45 degrees: Legible is a brush loaded with yellow ink with a drop at the tip; Faded is a dry brush with pale splayed strands and a trace of ink.
- F69 More padding: the At sea panel is roomier, and tooltip text sits further inside the border.
- F69 UI kit: the Exit buttons in the workbench, events, treasure and the bounty board, and the dice picker's Confirm, are now kit buttons: big text that grows with the button, a shadow, a press-down, and a reason on hover when they can't be pressed (e.g. "Choose an option first", "Take the dice off the bench first"). The picker's button says "Take none" when nothing is chosen at the workbench.
- F69 The fight's rewards sit on a logbook panel with a rule under the title; Next is green and the last Exit brown.

**Batch 12, round 6: the At sea workbench (F02)**
- F02 The map's "Visit the workbench" button is gone. Finishing a page's island (its last stop) earns a visit: back on the map an "At sea" panel offers "Open the workbench" or "Sail on". Choosing your next stop also counts as sailing on. Ordinary stops no longer earn a visit.
- F02 Opening the workbench shows your bag: choose up to N dice (N = tools you own, +1 if you own the Hammer; just the Drill = 1). Confirm works with fewer, even none. No dice are dealt at random any more.
- F02 Each tool works once per visit: when it crafts it vanishes back into the toolbag, and clicking it in the toolbag again says "Used this visit". With two or three tools you can craft two or three times.
- F02 After a craft, click the finished die (and the Cutters' coin) to take it back into your hand; once the bench is clear the Craft button resets for the next tool. Your other chosen dice stay in your hand between crafts (they used to be sent back to the bag).
- F02 Exit sends everything in your hand back to the bag, crafted dice included. Check the bag afterwards: right dice, no duplicates, nothing lost.
- F02 Tips: the map tip now points at the At sea panel; the workbench tip mentions one use per tool.

**Batch 12, round 5 (2026-11-17 feedback)**
- B108 The reward flash is gone (confirmed on web).
- B113 The bag view and the dice picker draw above every other window (events that ask you to pick dice, the shop, the workbench).
- B114 The chosen draft pages' green outline follows the torn paper again (no rectangle, no black).
- F59 Workbench tool mouse hints sit above the bench, not over the dice in hand.
- F51 New placeholder insight icons: Faded is a dry brush tip (pale bristles, a touch of yellow at the point), Legible a brush dipped in yellow ink, Quill a feather quill with a dark nib. Check them above the player, in the insight panel and beside rewritable intents.

**Batch 12, round 4 (2026-11-17 feedback)**
- B110 Buttons are no longer black boxes (main menu, settings, pause...): panels are now drawn straight to the screen, with the same wobbly ink edges, held still. Draft pages: unchosen ones look normal; a chosen one has a green rounded frame. (If a page still looks black, send a screenshot.)
- B111 Splash Die: a total below 0 counts as 0 (description says so).
- F66 Tooltips stay where they first appeared (beside the pointer) while you keep hovering the same thing, instead of following the mouse. Moving to another thing places a new one.
- B108 Reward flash, third try: taking a reward die no longer creates the flying die in the middle of drawing (it's made in the next step). Tell me on web whether the flash is gone.
- B112 The dimming starts exactly where the top bar ends (rewards, new-run offer, map). Long reward names wrap inside their frames.
- F67 Shop: clicking an item with your slots full says "No room"; anything you can't afford says how much more gold you need.
- F67 End Turn uses the same green as Embark and gently breathes once your hand is empty.
- F68 (withdrawn) The ship no longer opens the workbench: it was awkward. The workbench redesign is being discussed (F02).
- F69 UI kit, phase 2: every button has a soft shadow, sinks a little while held, and a greyed-out one is a muted colour with readable text. The pause menu, voyage summary and spread-end choice sit on one logbook panel (dark ink, cream rule, corner diamonds) with a divider under the title.


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
- F02 **Rethink what happens between pages (Jared, 2026-11-17).** Workbench part built in batch 12 (At sea). Still open: the spread-end choices themselves. Built version (2026-11-17): the workbench becomes an "At sea" step between pages (after a page's island is done, before the next), replacing the map button. You choose which dice to take from your bag (not dealt at random), up to one per tool you own (plus a core for the Drill); each tool can be used once per visit and goes back in the toolbag after. "Sail on" skips it. Like FTL's ship upgrades between jumps, or the Slay the Spire campfire, but more often and smaller. Today a finished spread offers "heal 25% or gain a core" (the design doc says 20% heal), and the workbench can be visited after every node from a map button. Jared wants to improve the between-page choices and decide whether the always-available workbench should stay as it is. Design not started.
- F03 Elite/boss chest reward
- F05 Die roll-history stats page (death/win screens and the run summary were done in batch 10)
- F06 Chapters, what's left: real art for the chapter tab, a second boss (chapter 2 reuses Barnacle Titan), a story tie-in for the chapter break, and balancing the chapter difficulty growth (+50% health, +3 attack and block per chapter, macros in scMap).

**Combat clarity** (the most common playtest feedback)
- F11 Enemy targeting indicator; floating arrows at intel ≥ 6
- F14 Colour-blind-safe palette (Jack can't tell the blues apart). Action icons on dice built in batch 12 (option); a palette change is still open
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
- F42 Unique visual per die

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
