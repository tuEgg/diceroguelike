# Build archetypes: coverage (Q17)

Read from `docs/design/content-catalogue.md` and the code on `dev`, 2026-11-23. Odds are estimates worked out from the reward code, not measured in play. "Working" means the engine fires most turns and the payoff matters in a fight, not a perfect build.

## Summary

| Archetype | Enablers | Payoffs | Working by end of ch. 2 | Biggest gap |
|---|---|---|---|---|
| 1. Full ink | Plenty: ink d4s, Looking Glass, Lookout, Radar, Eye patch, Book of Secrets, Deep Lens, Crow's Nest, Deflect, Inkwell | Few: Guerrilla Coin, Assassin, Deepdiver, plus the ink actions themselves | ~35% for "ink every turn, control 1-2 enemies"; 0% for the engine as pitched | Nothing raises max ink or cuts ink costs. The 12 cap means at most 2 rewrites a turn |
| 2. Infinite might | Thinning only: removal events, Squall stop, Scavenger's Tear, Kraken's Grasp, the Hammer | Captain's Ledger, Blood Reef. Might: Offhand (1, this turn), Grog of Grit | ~5% | No engine: Might lasts one turn and nothing builds it |
| 3. Valleys | Warrior, Edge and Binary cores, coins, ink rerolls, ruthless Compass/Lodestone | Topographic Map, Navigation Chart, Balancing Compass, Rusty Rudder, Warrior, Offhand | ~45% | Payoffs are 4 rollable keepsakes (~40% each to show up). A 1 only turns into something else; nothing scales |
| 4. Coin swarm | 4 coin dice, Fogcaller, Cutters, Wishing Well, draw dice | Protective Rigging, Eye patch, Power penny, Repeater Rail, Riggers Tonic | ~20% | Too few coins, and the hand is 6 dice: coins free up plays, not dice. Only 2 per-play payoffs, both rollable |
| 5. Heavy hitters | Hammer, +2 size events, Whetstone/Chainshot/tattooist, min-up keepsakes, Weighted/Loaded cores, Cursed Heart, Sticky | Big slot totals, place bonus (+3 at slot 4), Muzzle, Kill coin, Cannon Splitter, Bolster | ~40% | Only one big attack die (Crescendo, rare) and no d12. Nothing pays for size or for late slots beyond +index |
| 6. Fortress | Lots: 13 BLK dice, Shield Plating, Balance, Lantern, Protective Rigging, Starver's Efficiency, Ballast, Storm | Bulwark (rare) only. Tidebreaker hits after a block slot but doesn't use Block | ~20% | No Block-into-damage payoff besides one rare die. Block and Balance don't carry over |
| 7. Alignment extremes | Events (7 of 19 move it), elite and crossroads kill/spare | Holy, Unholy (one encounter, take 1), Medallion (boss), Compass/Lodestone, Siren's Call | ~20% | Payoffs are single copies from rare sources. Holy/Unholy are generic dice that can't start a slot |

## How many rewards a run sees by the end of chapter 2

From scMap, oWorldManager Room End (`Other_5`), scShop, scCombatScripts (`win_fight` rewards) and the catalogue's map estimate (about 26 stops, 16 sea stops, 2 harbours, 2 bosses):

| Source | Count by end of ch. 2 | What it offers |
|---|---|---|
| Quartermaster | 1 | 3 cored dice (each core ~5/6 uncommon), take 1 |
| Normal fights | 10-12 | 3 dice each (80% common / 19.5% uncommon / 0.5% rare). Items now come back (B162): about every other fight, 2-of-3 items, each card 30% core |
| Elites | 2-3 **for the whole run** | 3 rollable keepsakes, 3 dice (all rare if you spare), 2-of-3 items |
| Bosses | 2 | 3 of the 9 rare dice, 3 of the 5 boss keepsakes, 2-of-3 rare cores |
| Shops | 4-5 | 4 dice (60/30/10), 4 items (40% cores), 3 of the 7 shop keepsakes, 1 tool while one is unowned (Hammer or Cutters, so ~50% Hammer per shop) |
| Treasure | ~2 (pages 4 and 12) | 1 rollable keepsake |
| Bounty | 0-1 **for the whole run** | a rare core, a rollable keepsake, a die |
| Events | 9-11 (of 19) | see catalogue |
| Crossroads (alignment) fight | 0-1 **for the whole run** | Holy or Unholy |
| Workbench visits | 2-3 | one Drill, Hammer and Cutters use each |
| Gold | roughly 700-850 (fight bounties ~25 a fight, elites ~45-50, bosses up to 151, 50 to start, events) | about 8-10 shop buys, or a tool and 5-6 more |

**Counters that never reset.** `elite_nodes_this_voyage`, `bounty_nodes_this_voyage` and `alignment_nodes_this_voyage` are only set in Create and loaded from saves; `start_new_chapter` doesn't touch them. So elites stop for good after the third (elite chance is zeroed while the count is above 2), the bounty board comes once a run, and the crossroads chance stops growing after the first one but never goes back to 0. Most rollable keepsakes come from elites, so chapter 2 sees fewer than chapter 1, and chapter 3 hardly any.

**Rough odds of seeing a given piece at least once by the end of chapter 2:**

| Piece | Chance to see it |
|---|---|
| A given common die | ~80% (11% per fight offer, the same per shop) |
| A given uncommon die | ~75% (6% per fight offer, 12% per shop) |
| A given rare die | ~50-65% (bosses 1 in 3 each, shops 4% each, spared elites, An island dream), but a boss pick competes with 2 other rares |
| A given rollable keepsake | ~40% (about 11 offered from 25) |
| At least one of 4 given rollable keepsakes | ~85% |
| A given boss keepsake | ~85-90% offered over 2 bosses (you take only 1 each time) |
| A given uncommon core | ~60% |
| A given rare core | ~45% |
| The Hammer on a shop shelf | ~90%. Affording it at 150 is the real limit |

## 1. Full ink (control)

**Enablers.** Ink d4 x2 (starter); Looking Glass (starter, 6 ink on turn 1); Lookout (common, Stowaway, 3 ink); Radar (common, 3 ink for 2 turns on building a slot); Deflect (uncommon, BLK/INK); Inkwell (uncommon, +1 per action type); Assassin (rare, ATK/INK); Eye patch (rollable, 1 ink per die played); Book of Secrets (rollable, +1 min on ink dice); Deep Lens (boss, 12 ink for 2 turns); Crow's Nest Clarity (potion, 10 ink); Siren's Call (event, +2 size to 1-3 ink dice at high alignment).

**Payoffs.** The ink actions: reveal 2, reroll or redraw 3, move a timeline marker 4, rewrite an intent 6. Guerrilla Coin (common, half your ink as damage when it builds a slot), Assassin (+1 min per 3 ink held), Deepdiver (uncommon, draw when inked). Ink rerolls also re-fire every "when rolled" effect (see Valleys).

**Chance.** High for "some ink every turn". About 35% that a player can steer 1-2 enemies a turn by the end of chapter 2. The archetype as pitched can't be built at all.

**Missing.**
- **Scaling (critical):** nothing raises the 12 cap and nothing lowers an ink cost. Rewriting 3 intents costs 18; 12 ink buys 2 rewrites or 3 moves, and ink gained during a turn arrives next turn.
- **Payoffs for spending:** Guerrilla Coin and Assassin reward *holding* ink. Only Deepdiver rewards spending it.
- **Cost:** ink dice are weak dice, a fair cost.

## 2. Infinite might (thin and punch)

**Enablers (thinning).** Squall sea stop (remove a die, needs 7+ dice); Pirate Prisoner, An island dream, Rough tides (remove a die); Scavenger's Tear (boss, remove 2); the Hammer (two dice become one); skipping die rewards. Kraken's Grasp (boss, +1 play, 1 fewer die drawn) suits a small bag. Overboard dice (coming) shrink the bag during a fight.

**Payoffs.** Might: Offhand (common, 1 Might this turn on a min roll) and Grog of Grit (potion, 3 Might this turn). Small-bag payoffs: Captain's Ledger (rollable, 5 to all and 3 gold when the bag runs out), Blood Reef (rare), Echo (rare).

**Chance.** About 5%. Thinning works (bag 7-8 maybe 40% of the time), but no Might builds, so there's no engine.

**Missing.**
- **Engine (critical):** Might is removed at round end, and nothing grants it turn after turn or lets it stack.
- **Payoffs:** nothing rewards a small bag beyond Captain's Ledger.
- **Enablers:** removal is mostly events, and every fight pushes a new die at you.

## 3. Valleys (low rolls pay)

**Enablers.** Warrior (common, min becomes max); Edge Core (uncommon) and Binary Core (rare); ruthless Compass and Lodestone at low alignment; coins (half their rolls are minimums); ink rerolls; Offhand (common).

**Payoffs.** Topographic Map (max: slot +2; min: draw, 2 a turn), Navigation Chart (min: next die rolls twice), Balancing Compass (min: next die rolls its max), Rusty Rudder (min: that much damage to a random enemy). All four are rollable keepsakes. Warrior and Offhand pay off on their own.

**Chance.** About 45%. It needs a core, a workbench visit, and one of the four keepsakes (~85% offered by the end of chapter 2).

**Missing.**
- **Payoffs:** all four are rollable keepsakes, and two only turn a 1 into a better *next* die.
- **Scaling:** nothing grows across a fight.
- **Cost:** Edge/Binary are nearly all upside. The real tension is with the min-up cluster.
- Bugs that make it stronger than it looks: Rusty Rudder and Nav Chart fire every roll on a die whose min equals its max.

## 4. Coin swarm

**Enablers.** Power penny (common), Guerrilla Coin (common), Kill coin (uncommon), Defensive coin (rare); Fogcaller (common); Lucky Coin (rollable); the Cutters; The Wishing Well. Draw: Invisible, Squall, Fogcaller, Small Sail, Topographic Map, Navigator's Brew.

**Payoffs (per die played).** Protective Rigging (rollable, 2 block per die played), Eye patch (rollable, 1 ink per die played). Stacking: Power penny, Repeater Rail (rollable), Echo (rare), Riggers Tonic (potion).

**Chance.** About 20%.

**Missing.**
- **Enablers:** coins don't use a play but still take a spot in the 6-die hand. Only 4 coin dice exist.
- **Payoffs:** only two "per die played" keepsakes, both rollable. Nothing counts coins.
- **Scaling:** d2s stay tiny.

## 5. Heavy hitters

**Enablers.** Splash d10 (common, BLK, -2 per roll), Ballast d8 (uncommon, BLK), Crescendo d8 (rare, ATK), Bulwark d8 (rare, BLK), Holy d8 (crossroads only). The Hammer (shop 150, ~90% offered by the end of chapter 2). Size events: Clear skies, A Great Storm, Roundshot, Siren's Call, Artisan's Ember Draught. Min: Whetstone reef, Chainshot, the tattooist, Weapon Polish, Shield Plating, Last Stand. Shape: Weighted and Loaded cores. Late slots: Cursed Heart, Shipwright's Draft, Sticky die, Friendship Bracelet.

**Payoffs.** Big totals build slots easily. Place bonus +1 at slot 2, +2 at 3, +3 at 4. Muzzle, Kill coin, Cannon Splitter, Bolster, Bulwark.

**Chance.** About 40%. Limits: 150 gold, a workbench visit, two same-type dice worth merging.

**Missing.**
- **Enablers:** Crescendo is the only attack die above d6, and it's rare. No d12 outside the Hammer.
- **Payoffs:** nothing cares about a die's size except Bolster and Bulwark.
- **Scaling:** late slots pay +index once; little reason to aim for slot 4.

## 6. Fortress (block and punish)

**Enablers.** 13 single-type BLK dice plus Deflect and Defensive coin; Shield Plating, Starver's Efficiency, Lantern of Patience, Protective Rigging; Balance from Balanced and Captain's Brew; A Great Storm. The timeline helps.

**Payoffs.** Bulwark (rare) only. Tidebreaker and Ninja reward ordering but don't turn Block into damage.

**Chance.** About 20%.

**Missing.**
- **Payoffs (critical):** nothing deals damage based on your Block.
- **Scaling:** Block doesn't carry over; Balance lasts one turn (Captain's Brew aside).

## 7. Alignment extremes

**Enablers.** 7 of the 19 events move it; elites and the crossroads fight move it 5 per enemy. Reaching below 20 or above 80 by the end of chapter 2 is about 55%.

**Payoffs.** Holy and Unholy (only from the crossroads fight, take 1), Medallion of the Sea (boss), Compass and Lodestone cores, Siren's Call.

**Chance.** About 20%.

**Missing.**
- **Payoffs:** one copy of Holy or Unholy is all you'll ever get, and both are generic dice that can't start a slot.
- **Enablers:** no die or keepsake moves alignment.
- **Scaling:** nothing else rewards staying at the extreme. The high side has nothing like Unholy's swing.

## Bridges (pieces serving two archetypes)

| Piece | Archetypes |
|---|---|
| Ink rerolls, Deepdiver | Full ink + Valleys |
| Guerrilla Coin, Eye patch | Full ink + Coin swarm |
| Ninja, Deflect | Full ink + Fortress |
| Assassin | Full ink + Heavy hitters |
| Siren's Call | Alignment (high) + Full ink; Alignment (low) + Heavy hitters |
| Compass / Lodestone (ruthless), Unholy with an Edge core | Alignment (low) + Valleys |
| Holy, Unholy | Alignment + Heavy hitters |
| Coins, Topographic Map's draw | Valleys + Coin swarm |
| Offhand | Valleys + Infinite might |
| Hammer, Kraken's Grasp, Scavenger's Tear | Heavy hitters + Infinite might |
| Ballast, Splash, Bolster, Bulwark, A Great Storm | Heavy hitters + Fortress |
| Kill coin, Cursed Heart, Shipwright's Draft | Heavy hitters + Coin swarm |
| Tidebreaker, Chainmaster's Anchor | Fortress + an attack build |
| Draw dice and Captain's Ledger | Coin swarm + Infinite might |
| Overboard (coming) | Infinite might |

## Pieces that serve none

- **Gold and potions:** Harvest, Barrel, Black Purse (broken), Rations, Water Barrel, Toolbelt.
- **Healing and health:** Salted Pork, Lime Juice, Rope of Repair, Bilge, Tidecaller, Tidepusher, Defensive coin's heal half. Last Stand and Blood Reef have no build of their own.
- **Cores with no target:** Dual and Tower. Bell and Dome only give steady totals.
- **Stowaway / unused:** Slipstream, Windbound Charm. Anchor and Lantern only loosely fit Fortress.
- **Misc:** Sticky die, Bandage, Single Focus, Bouncing, Gunpowder, Lead Line, Message in a Bottle, Pickled Cucumber, Accurate, Surge, Inkwell, Mirage Brew, Corsair's Gambit, Bilge-Purge Flask.

## Takeaways

1. Three archetypes have no engine or no payoff today: Infinite might (no lasting Might), Fortress (no Block-into-damage beyond one rare die) and Full ink as pitched (no max-ink or cost reduction). Each needs 2-3 new pieces, at least one common.
2. Valleys is the only archetype close to "humming by the end of chapter 2", and it leans on rollable keepsakes, which dry up because the elite counter never resets per chapter.
3. Heavy hitters and Coin swarm have enablers but thin payoffs: one keepsake each that cares about size, or about dice played, would turn them on.
4. Alignment needs more than one copy of its payoff dice, and a way to push alignment that isn't an event.
5. Rare dice are the backbone of two archetypes (Bulwark, Crescendo), and outside bosses and shops a rare turns up in 0.5% of fight offers.
