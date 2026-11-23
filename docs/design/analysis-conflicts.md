# Conflicts and dead content (Q17)

Read from the code on `dev`, 2026-11-23. Frequencies are estimates from the odds in the code, not measured. "End of chapter 2" = about 11 normal fights, 2 elites, 2 bosses, 4-5 shops, 9 events, 2 workbench visits plus a harbour refit.

## The short version

1. **Raising a minimum shrinks the die, it doesn't clamp it.** `die_roll_faces` rolls evenly over min..max, so Weapon Polish makes an Attack d4 roll 2-4: its minimum comes up 1 in 3, and it's a 2. Min-up keepsakes *help* the min-roll engine until min reaches max. (Corrects the catalogue.)
2. **Rollable keepsakes are thin:** 25 in the pool, about 11 offers by the end of chapter 2 (2 elites x 3, 4 treasures, a few events, a bounty). Any one is seen in about 1 run in 3; a specific pair in about 1 in 12.
3. **Cores come far faster than you can fit them:** ~25 core cards seen, 3-5 fitted (the Drill works once per visit), and they block the 3 item slots potions need.
4. **Rare dice are boss loot:** 1 in 200 normal-fight cards; before the first boss a given rare turns up in about 1 run in 9, and only in shops.
5. **The "this voyage" counters never reset between chapters** (`elite_`, `bounty_`, `alignment_nodes_this_voyage`): at most ~3 elites, 1 bounty and 1 crossroads fight per run; chapter 3 can have no elites. Bug or intended?
6. **The treasure is forced on all three offered pages**, so each trigger gives 2 treasures: 4 by the end of chapter 2.

## Worst anti-synergies

| Pair | What happens | Severity | Healthy or trap |
|---|---|---|---|
| **Building a slot vs every "when played" effect** (Protective Rigging, Eye patch, Topographic's max, Invisible, Harvest, Fogcaller, Echo) | `combat_try_build_slot` never fires `on_dice_played_to_slot`, but building uses a play. A quarter to a third of dice placed each turn are builders. | Med | Trap |
| **Navigation Chart + Balancing Compass** | Both change the same next die; Nav works about half as often when you own both. | Med | Trap |
| **Rum vs the min-roll engine and cores** | Attack dice roll 0-5: Rusty Rudder hits for 0; Binary/Edge roll 0 often; Rum switches Polished Sextant off depending on bar order. | Med | Trap |
| **Kraken's Grasp vs Lantern and Stowaways** | 5 dice, 5 plays: nothing left over. | Med | Mostly healthy |
| **Extra plays vs a 6-die hand** | Play sources far outnumber draw sources; extra plays beyond the hand do nothing (Bilge-Purge's +3). | Med | Healthy limit, potions overpromise |
| **Overboard vs Crescendo** | Crescendo's minimum grows with plays; Overboarded after one, it never grows. | High | Trap if Overboard is forced on it |
| **Overboard vs a thin bag in long fights** | Dealing stops when bag and discard are empty; a 10-die bag with 3-4 Overboard dice can run dry in a 6+ turn fight. | High | Needs a floor (e.g. never below the hand size) |
| Min-up stacking to one face vs min-roll keepsakes | Once min = max, Topographic and Compass stop, Rudder and Nav fire every roll (no guard). | Low-Med | Trap (bug) |
| Random size upgrades (Storm, Clear skies) vs fixed-number effects | Polished Sextant stops applying; Tidepusher's "exactly 4" breaks. | Low-Med | Trap where the game picks the die |
| Ink cap 12 vs ink producers and Deep Lens | Ink over 12 is lost; Crow's Nest with Deep Lens is a waste. | Med | Mostly healthy |
| Bouncing Die vs leader fights | It moves the target for good, away from the leader. | Med | Trap |
| Item slots: cores vs potions | Cores wait for a workbench and block potions; Barrel's potion is lost when full. | Med | Trap for potion keepsakes |
| Ink held (Assassin, Guerrilla) vs ink spent | A real tension. | Low | Healthy |
| Kill coin vs building after it; Surge vs Muzzle | Positional puzzles. | Low | Healthy |

## Rarely or never seen by the end of chapter 2

| Rarity | Pool | Cards seen | Chance a given one appears | Before the chapter 1 boss |
|---|---|---|---|---|
| Common dice | 21 | ~45 | ~89% | ~70% |
| Uncommon dice | 10 | ~14 | ~77% | ~55% |
| Rare dice | 9 | ~8.5 (6 from bosses) | ~65% | ~11% |
| Holy / Unholy | 2 | one crossroads fight per run | ~50-70% to get the offer, take one | ~25% |
| Rollable keepsakes | 25 | ~11 offers | ~36% seen, ~28% owned | |
| Shop keepsakes | 7 | 3 a shop | ~90% | gold-limited |
| Boss keepsakes | 5 | 3 a boss | ~90% | 2 of 5 owned |

Potions: each seen 2-3 times; item slots, not supply, decide how many you carry. Cores: every core seen 2-3 times, 3-5 fitted. Tools: each offered about twice (150 and 165 gold).

## Effects that rarely fire

| Effect | How often | Note |
|---|---|---|
| Medallion of the Sea | alignment below 20 or above 80 in ~5% of runs without steering | near-dead, and it's a chapter 1 boss reward |
| Compass and Lodestone cores | at alignment 35-65, almost a plain die | dead in a normal run |
| Tidepusher | +0.25 heal per use | dead (90-gold rare) |
| Chainmaster's Anchor | doubles a +1/+2 once a turn with a Followthrough die | dead unless built around |
| Lead Line | only Invisible and Harvest work | dead |
| Fogcaller | a coin in the slot before: ~10-20% of plays | near-dead |
| Lucky Coin | +0.17 per coin roll | dead without coins |
| Bulwark | two Block slots in a row, 2 damage to all | rare and small |
| Black Purse | always 3 gold (bug) | broken |
| Splash die | a d10 - 2 averages ~3.7 | filler |

## Fire so often they're flat bonuses

On a d4-heavy bag (~1.5 minimum rolls a turn): Topographic Map (~1.2 extra dice every turn), Navigation Chart (~80% of turns), Balancing Compass (~80%), Rusty Rudder (~1.5 a turn, including unplayed dice and ink rerolls), Kill coin (+2 almost every play), Single Focus, Inkwell Die, Protective Rigging (~6-8 block a turn), Eye patch (~3-4 ink a turn), Lantern (~4 block a turn), Shipwright's Draft (~+1 play a turn; free building with Cursed Heart), Holy/Unholy (flat strong dice at neutral alignment). The min-roll keepsakes weaken as the bag fills with bigger dice, the opposite of how a build ramps.

## The catalogue's broken list, checked (one-line fixes)

| # | Item | Verdict and fix |
|---|---|---|
| 1 | Black Purse pays 3 | Confirmed: built slots are reset before `on_combat_end`. Record the slot count on `on_player_turn_end` and pay 3 x that. |
| 2 | Normal-fight items | Fixed by B162. |
| 3 | Crescendo | Confirmed: counted on play (line 733) and resolve (line 171); `min_roll =` wipes Whetstone bonuses. Delete the line-171 increment; use `max(min_roll, min(max/2, 1+n))`. |
| 4 | Chainmaster's Anchor | Confirmed: only doubles the `on_roll_die` bonus. Reword to "The first Followthrough bonus each turn counts twice." |
| 5 | Lead Line | Confirmed: Echo's flag never read, Fogcaller returns on slot -1. Fire it on `after_new_slot_created` with the new slot. |
| 6 | Artisan's Ember | Confirmed: faces kept after the resize. Call `die_roll_faces` after `die_size_changed`. |
| 7 | Rusty Rudder, Navigation Chart | Confirmed: no `min < max` guard. Add it. |
| 8 | Lodestone text | Confirmed at both ends. "Low alignment: mostly its lowest or highest. High alignment: never them." |
| 9 | Bell, Dome | Confirmed: absolute faces, tip low on a raised minimum. Index relative to `_min_roll`. |
| 10 | Rum, Weapon Polish, Shield Plating, Book of Secrets | Confirmed: own type on deal, slot type at resolve. Read `data.die.action_type`. |
| 11 | Tidepusher | Confirmed: "exactly 4" breaks after a resize. Check `>= max_roll`; text "If it rolls its max, heal 1 more." |
| 12 | Polished Sextant | Confirmed: depends on bar order. Check `data.die.dice_value == 4`. |
| 13 | Inkwell Die | Partly: counts are right in play; `slot` lacks `var`. |
| 14 | Barrel Die | Confirmed: potion lost when full. Route to `pending_item`. |
| 15 | Bouncing Die | Confirmed: changes the target for good. Restore it in `after_roll_die`. |
| 16 | Names, prices | Rename "Rigger's Tonic"; price Holy/Unholy like rares (60-80). |
| 17 | Fire-on-deal effects | Confirmed, a design call (it's why the min-roll keepsakes are flat). |

New: the voyage counters (above); 2 treasures per trigger; a shop's 4th die can repeat its 3rd (track all picks); Lantern fires every frame of RESOLVE_ROUND (only fire `on_not_used` when dice exist); builder dice don't fire "when played" keepsakes (design call); Assassin's min passes its max at 12 ink (cap at `max_roll - 1`).
