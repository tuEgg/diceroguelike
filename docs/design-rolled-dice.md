# Rolled dice: combat redesign (prototype)

Branch `feature/rolled-dice`. Agreed with Jared on 2026-11-19. The goal: more decisions in a fight. You see your numbers before you commit them, instead of placing dice and watching End Turn play itself.

## The rules (phase 1)

- **Dice are rolled when dealt.** Each die in hand shows the number it rolled. That number is what it does when the turn resolves. Keepsake and slot bonuses still add on top.
- **Slots show live totals.** A slot whose dice are all rolled shows its exact total (with bonuses), not a range.
- **Plays per turn stay** (coins are free). Same stacking and type rules as before (`slot_placement_check`).
- **Take dice back.** Click a die you played this turn (in a slot, or on the new-slot tile) to return it to your hand and get the play back. A die whose "when played" effect already fired is locked in.
- **Reroll once per turn, free.** Right-click a die in your hand.
- **Discard and redraw once per turn, free.** The first die you drop on the discard pile each turn draws a new one. Later discards just discard.
- **End Turn discards everything.** Hand, slots and unfinished new-slot dice all go to the discard pile. Sticky dice stay.
- **Slots start empty.** A fight starts with 2 empty slots. The first coloured die played into an empty slot sets its type for that turn (the old "claim"). At End Turn it's empty again.
- **New slots cost a total, not a count.** Drop dice on the new-slot tile. When at least 2 dice are there and their rolled numbers add up to the threshold, the slot is built:
  - slot 3: 6+, slot 4: 9+, slot 5: 12+, and so on (+3 per slot; Cursed Heart adds +3).
  - Each die dropped there uses a play (coins free) and can be taken back until the slot is built.
  - The new slot keeps the types of the dice that built it (a red and a blue die make an Attack/Block slot). It starts empty; the first matching die picks its type for the turn, and right-click still switches it.
  - The dice that built it go to the discard pile. "When sacrificed" effects fire when the slot is built.
- **One target.** All attacks go at the marked enemy, as now.
- **When an elite or the boss dies, the others flee.** They fade out, give no gold, and the fight is won. In kill/spare fights only the elite gets the choice.

## Later phases (after Jared plays phase 1)

- Order bonuses: an expanded Followthrough.
- Port every die and keepsake into three buckets: **when rolled** (on deal), **while in the queue** (live, reversible), **at End Turn** (resolution). The list goes to Jared for review first.
- Tutorial and tips rewrite. The guided first fight is off on this branch for now.

## Where it lives

- Rolling on deal: `die_roll_faces` (scDice), called from `deal_single_die`. The faces are stored on the die struct (`faces`, one per die in a "2d4"). `process_action` uses them instead of rolling.
- Live totals: `get_slot_stats` uses the faces.
- Take back: `combat_take_back` (scCombatScripts), clicked in oCombat Draw GUI, run from oCombat Step.
- Reroll and redraw: `reroll_used` / `redraw_used` on oCombat, reset at turn start.
- Slot building: `sacrifice_die`, `new_slot_threshold`, `slot_recompute_types`.
- Flee: `combat_enemies_flee`.
