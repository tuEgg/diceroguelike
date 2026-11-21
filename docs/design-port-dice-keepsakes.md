# Porting dice and keepsakes to rolled dice

Reviewed by Jared 2026-11-19 and done (F128): see **Decided** at the end. Branch `feature/rolled-dice`. Rules: `docs/design-rolled-dice.md`.

## The three moments

Under rolled dice a die's number is known the moment it's dealt, so every effect has to pick one of three moments:

| Moment | When | What belongs here | Code today |
|---|---|---|---|
| **When rolled** | as the die is dealt, or rerolled with ink | anything that shapes the roll (min, max, roll twice, weighting), and "if it rolls X" effects about your hand or this turn (draw, buffs) | `on_roll_die` with `on_deal` (read only); `after_roll_die` doesn't fire here yet |
| **In the queue** | live, while it sits in a slot; shown in the slot's total | bonuses from position or neighbours (Followthrough, last slot, dice in this slot) | `on_roll_die` reading the slot (already live in the totals) |
| **When it acts** | End Turn, as the queue resolves | outcomes: damage, block, heal, side hits, self-damage | `after_roll_die`, `on_roll_die` non read-only |

**Proposed rule:** "If it rolls X, gain block/heal/damage" happens when it acts (it has to be played). "If it rolls X, draw/buff" happens when rolled (it's about your turn, and it reads at a glance as it lands). Roll-shaping is always when rolled.

Status: **OK** works as is · **Reword** works, the text is stale · **Move** change its moment · **Rework** broken or dull under the new rules · **Q** needs your call.

## Dice (40, plus Holy and Unholy)

### When rolled

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Accurate (d4 ATK) | rolls twice, keeps the higher | OK | already rolls twice on deal |
| Crescendo (d8 ATK) | +1 min each time it rolls, up to half | OK | counts deals per fight |
| Ballast (d8 BLK) | never below 4 | OK | |
| Last Stand (d6 ATK) | +1 min per 20% HP missing | OK | |
| Holy / Unholy (alignment) | min / max from alignment | OK | |
| Splash (d10 BLK) | -2 on every roll | OK | it's a bonus, so it shows in the queue |
| Assassin (d4 ATK/INSIGHT) | +1 min per 3 insight | Q | ink carries over (up to 12), so it's often +3-4 on a d4: nearly always max. Per 4 ink? |
| Squall (d6 neutral) | 5+: draw a die | Move | to when rolled: the extra die arrives as it lands (today it draws during End Turn, wasted) |
| Offhand (d6 ATK) | rolls min: +1 Might this turn | Move | when rolled, so the Might counts for this turn's queue |
| Balanced (d6 BLK) | rolls max: +1 Balance this turn | Move | same as Offhand |
| Warrior (d4 ATK) | rolls min: becomes max | Move | when rolled, changing the face itself, so the slot total shows 4 |
| Tidepusher (d4 HEAL, Exclusive) | rolls 4: heal 1 more | OK | it's a bonus on its act; works |

### In the queue (live in the slot's total)

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Tidebreaker (d6 ATK, Followthrough) | previous slot Block: +2 | OK | |
| Ninja (d4 BLK, Followthrough) | previous slot Insight: +2 | OK | |
| Fogcaller (d4 BLK, Followthrough) | previous slot has a coin: +1 and draw a die | Rework | the +1 is fine; the draw happens at End Turn (wasted). Draw when it's **placed** after a coin slot |
| Muzzle (d4 ATK, Followthrough) | +1 per previous slot | Q | overlaps the new slot position bonus (slot N is already +N-1), so it's double. Make it +2 per previous slot, or "+1 per previous slot of a different type"? |
| Surge (d4 BLK) | +1 per later slot | OK | the mirror of the position bonus; nice |
| Kill coin (d2 ATK) | +2 in the last slot | OK | |
| Power penny (d2 BLK) | +1 per die in its slot | OK | |
| Inkwell die (d4 INSIGHT) | +1 per unique action in the queue | OK | |

### When it acts

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Reed snap (d4 BLK) | 4+: gain 2 block | OK | |
| Tidecaller (d6 HEAL) | 5+: also gain 3 block | OK | |
| Bilge (d6 neutral, Sticky) | total even: heal 2 | Q | see Sticky below |
| Bulwark (d8 BLK, Followthrough) | after a Block slot: damage all for double its min | OK | |
| Gunpowder (d4 ATK) | 2 damage to every other enemy | OK | |
| Blood Reef (d6 ATK) | +2 damage, lose 1 HP | OK | |
| Bouncing (d4 ATK) | hits a random other enemy | OK | |

### When played (into a slot)

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Invisible (d4 neutral) | draw 1, +1 play this turn | OK | |
| Deepdiver (d6 neutral) | discard your hand, draw 2 | Q | discarding is free now, so this is just "draw 2" with a downside. "Draw 2" plain, or "discard your hand: draw that many +1"? |
| Echo (d4 neutral) | a copy joins its slot | Reword | text says "the sacrificed slot": "When played: a copy of it joins the slot" |
| Harvest (d6 BLK) | 1 gold when played, ejected or sacrificed | Rework | End Turn ejects everything now, so it's 2 gold every turn it's played. Make it "1 gold when played" (and when it builds a slot); fix the text |

### When it builds a slot ("when sacrificed")

"Sacrifice" now means dropping dice on the new-slot tile; the effect fires when the slot is built. These dice also stop that slot being taken apart (F124).

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Bolster (d4 BLK) | gain double its max as block | Reword | "When it builds a slot: gain 8 block" |
| Barrel (d6 BLK) | a random potion | Reword | same wording change |
| Radar (d6 INSIGHT) | 3 insight for 2 turns | Reword | it arrives next turn as ink; say so |
| Guerrilla Coin (d2 INSIGHT, Coin) | damage a random enemy equal to your insight | Rework | can hit a dead enemy (bug). With ink up to 12 it's a big hit: half your ink? |

### Stowaway (when left unplayed at End Turn)

| Die | Effect | Status | Proposal |
|---|---|---|---|
| Anchor (d6 BLK) | +5 block | OK | discarding is free, so holding it costs nothing but the play |
| Slipstream (d4 ATK) | +1 play next turn | OK | |
| Lookout (d6 INSIGHT) | 3 insight next turn | OK | |

### Keyword only

| Die | Status | Proposal |
|---|---|---|
| Defensive coin (Coin, Favourite, Multitype) | OK | a coin can't build the first slot (it needs a 3) |
| Deflect (Multitype) | OK | |
| Sticky die (Sticky) | Q | see Sticky |

## Keepsakes (42)

### When rolled

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Weapon Polish, Shield Plating, Book of Secrets, Crossword Puzzle, Polished Sextant | +1 min on a type / d4s | OK | applied on deal |
| Rum | attacks +1 max, -1 min | OK | |
| Lucky Coin | coins roll 2s twice as often | OK | check it applies on deal |
| Starver's Efficiency | first Block die each turn rolls twice | Rework | only fires on the resolving roll, so it never shows. Make it "the first Block die dealt each turn rolls twice" |
| Balancing Compass | min roll: max next time it rolls | OK | check the forced face lands on deal |
| Nav Chart | min roll: the next die rolls twice | Rework | the next die has already rolled. "When a die rolls its minimum, the next die you're dealt rolls twice" |
| Topographic Map | max roll: the next die in that slot +2 min | Rework | same problem. "When a die rolls its max, the next die played into its slot gets +2" |
| Rusty Rudder | min roll: that much damage to a random enemy | Move | when rolled (you see it hit as the die lands) |
| Deckhand's Token | first die in slot 1: +1 min and max | Rework | min/max are too late once it's rolled. "+1 to the first die in slot 1" |

### In the queue

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Single Focus | first die in a single-type slot +1 | OK | |
| Repeater Rail | +1 per same-type slot before | Q | stacks with the position bonus; maybe fine (rewards long same-type runs) |
| Chainmaster's Anchor | first Followthrough each turn twice | OK | |
| Bandage | debuffed: slot 1 +1 for the fight | OK | |

### When it acts

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Cannon Splitter | first attack slot hits the rest for 75% | OK | |

### When played / building slots

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Protective Rigging | +2 block per die played | OK | taken back and replayed counts once |
| Eye patch | +1 insight next turn per die played | OK | |
| Windbound Charm | Stowaway also fires when played | OK | |
| Lead Line | "when played" fires twice when sacrificed | Reword | "...when it builds a slot" |
| Shipwright's Draft | new slot: +1 play this turn | OK | given back if the slot is taken apart |
| Cursed Heart (boss) | slots cost 1 more die | Reword | it now adds 3 to each new slot's number: "New slots need 3 more to build" |

### End of turn

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Lantern of Patience | +2 block per unplayed die | Q | strong now: discarding is free and every unplayed die counts. +1 each? |

### Turn and fight start, plays and draws

| Keepsake | Effect | Status | Proposal |
|---|---|---|---|
| Looking Glass (starter), Deep Lens (boss) | 6 / 12 ink at the start | OK | |
| Pickled Cucumber, Kraken's Grasp, Medallion of the Sea | extra plays | OK | |
| Small Sail, Message in a Bottle | extra dice at fight start | OK | |
| Rope of Repair | heal 3 at fight start | OK | |
| Captain's Ledger | bag runs out: 5 to all, 3 gold | OK | |

### Outside fights (no change)

Lime Juice, Salted Pork (heals at the strait now), Toolbelt, Rations, Water Barrel, Black Purse, Friendship Bracelet, Scavenger's Tear.

## Keywords

| Keyword | Status | Proposal |
|---|---|---|
| Coin | Reword | "Doesn't use a play." (the size rule it mentions is gone) |
| Exclusive | Reword | "...and can't build a slot" (not "sacrificed") |
| Loose | Rework | everything leaves the queue at End Turn now, so it means nothing. Retire it |
| Sticky | Q | "stays in its slot". With End Turn clearing the queue: does a Sticky die stay and **roll again each turn** (a permanent, growing queue), or just stay one extra turn? I'd say it stays and rerolls each turn: a slow-build archetype with Bilge |
| Followthrough, Stowaway, Favourite, Multitype | OK | |

## Your calls (the Q rows)

1. Sticky: stay forever and reroll each turn (my pick), or one extra turn?
2. Muzzle: +2 per previous slot, or different-type slots only?
3. Assassin: +1 min per 4 ink instead of 3?
4. Deepdiver: plain "draw 2", or "discard your hand, draw that many +1"?
5. Lantern of Patience: +1 block per unplayed die?
6. Guerrilla Coin: half your ink as damage?
7. Repeater Rail: keep stacking with the position bonus?
8. The moment rule above ("if it rolls X": outcomes when it acts, hand/buffs when rolled): agree?

Once these are settled the code work is: move 6 effects to when rolled (`after_roll_die` on deal), rework 6 (Fogcaller, Harvest, Starver's, Nav Chart, Topographic Map, Deckhand's), reword about 10 descriptions, retire Loose, fix Guerrilla Coin's dead-target bug.

## Decided (Jared, 2026-11-19) and done

1. Sticky stays one extra turn (and acts again), then leaves.
2. Muzzle stays +1 per previous slot (reworded).
3. Assassin stays per 3 insight.
4. Deepdiver: "When rerolled or redrawn with ink, draw a die (an extra one, if redrawn)."
5. Lantern of Patience stays; instead, dice can't be discarded at all except by a redraw with ink.
6. Guerrilla Coin: half your insight, to a living enemy.
7. Repeater Rail: unchanged.
8. The moment rule: agreed. Balanced's Balance arrives next turn.
