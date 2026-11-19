# Rolled dice: combat redesign (prototype)

Branch `feature/rolled-dice`. Agreed with Jared on 2026-11-19. The goal: more decisions in a fight. You see your numbers before you commit them, instead of placing dice and watching End Turn play itself.

## The rules (phase 1)

- **Dice are rolled when dealt.** Each die in hand shows the number it rolled. That number is what it does when the turn resolves. Keepsake and slot bonuses still add on top.
- **Slots show live totals.** A slot whose dice are all rolled shows its exact total (with bonuses), not a range.
- **Plays per turn stay** (coins are free). Same type rules as before (`slot_placement_check`), but no size rule: any die can join a slot of its type.
- **Dice look like dice.** In fights they're drawn in code with real pips, a shape per size. A dealt die tumbles out of the bag and lands on its roll; a reroll tumbles in place.
- **Take dice back.** Click a die you played this turn (in a slot, or on the new-slot tile) to return it to your hand and get the play back. A die whose "when played" effect already fired is locked in.
- **Reroll once per turn, free.** Right-click a die in your hand.
- **Discard and redraw once per turn, free.** The first die you drop on the discard pile each turn draws a new one. Later discards just discard.
- **End Turn discards everything.** Hand, slots and unfinished new-slot dice all go to the discard pile. Sticky dice stay.
- **One slot to start, filled left to right.** A fight starts with 1 empty slot. A die can only go in a slot if every slot before it has an action (a chained slot doesn't count), and a slot can't be emptied by taking a die back while a later slot has dice.
- **Slots start empty, every turn.** The first coloured die played into an empty slot sets its type for that turn (the old "claim"). At End Turn every slot, built ones too, is empty and untyped again. (Built slots kept their types for a while; that let one Attack/Block slot swallow everything, so it went.)
- **A slot's place is worth a bonus.** Added once to its total, not per die: slot 1 +0, slot 2 +1, slot 3 +2, and so on. Built slots are worth more, and with more slots than good dice, which die gets the big bonus is a choice.
- **New slots cost a total, not a count.** Drop dice on the new-slot tile. When enough dice are there and their rolled numbers add up to the threshold, the slot is built:
  - slot 2: 1 die, 3+; slot 3: 2 dice, 6+; slot 4: 3 dice, 9+; and so on (slot N: N-1 dice adding to 3(N-1); Cursed Heart adds +3 to the total).
  - Each die dropped there uses a play (coins free) and can be taken back until the slot is built.
  - This turn the new slot has the types of the dice that built it (a red and a blue die: Attack/Block, right-click switches). From next turn it's an empty slot like the others.
  - The dice that built it become its first dice and act this turn, locked in (taking one back would leave a free slot), then are discarded at End Turn. "When sacrificed" effects fire when the slot is built.
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
- Slot building: `sacrifice_die`, `new_slot_threshold`, `new_slot_min_dice`, `slot_recompute_types`. Order: `slot_has_action` in `slot_placement_check` and `combat_take_back`. Position bonus: `slot_set_position_bonus`.
- Flee: `combat_enemies_flee`.
