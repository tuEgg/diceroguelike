# Power curve: dice, keepsakes, potions

Worked out on `dev`, 2026-11-23, from `docs/design/content-catalogue.md`, checked against scDice, scKeepsakes, scCombatScripts and scDebuffs. Nothing here was measured in play: every number is an expected value worked out by hand from the code's rules, so trust the ranking more than the exact figures.

## How the numbers are worked out

**Plays are the limit, not dice.** 6 dice are dealt and you get 4 plays, so 2 dice go unused every turn and you always play your best 4. A die is worth what it adds *per play*. Anything that gives value **without using a play** (coins, Stowaways, "when played: +1 play", per-play keepsakes) is worth about one whole extra die on top.

| Thing | Points | Why |
|---|---|---|
| 1 damage = 1 block = 1 heal | 1 | heal is scarcer; flat block can be wasted |
| 1 extra play | 3 | it plays your 5th-best die, about a d4-d6 |
| 1 extra draw (no play) | 0.75 | a better 4 from 7, not an extra action |
| 1 ink | 0.6 | 3 ink buys a reroll worth about +1.5 to +2; capped at 12 |
| 1 gold | 0.1 | a common die costs 30-50 |
| 1 potion | ~6 | the average of the potion table |
| 1 Might (this turn) | 2 | +1 on each ATK die, about 2 a turn |
| 1 Balance (next turn) | 1.5 | +1 on each BLK die |
| "every other enemy takes N" | N x 0.75 | half of fights have extra enemies |
| +1 minimum roll | +0.5 | at any size |

**Plain baselines:** d2 1.5, d4 2.5, d6 3.5, d8 4.5, d10 5.5, d12 6.5.

**Building slots makes size worth more than its average.** Slot N costs 2 x (N-1) pips and its first die gets +(N-1). A d4 alone builds slot 3 (4+ pips) 25% of the time and slot 4 never; a d6 50% / 17%, a d8 63% / 38%, a d10 70% / 50%. That's about +0.5 per size step on top of the +1 average.

## Findings, most important first

1. **Free value is badly under-priced.** The best dice and keepsakes act without a play: Invisible (common, 30), Power penny (common, 50), Anchor (common, 30), Slipstream (common, 40), Kill coin (uncommon), and the keepsakes Protective Rigging, Shipwright's Draft and Lantern of Patience. Each is worth about one extra die a turn, and several are commons.
2. **Die size beats almost every effect.** One size step is worth about **+1.5 per play**; most common effects are worth +0.3 to +1. Ballast (uncommon d8, never below 4) is the best die per play in the pool at **6.0**, more than any pooled rare. The +2 size events and the Hammer are worth as much as a good common.
3. **Rares are mostly below the curve.** Tidepusher (rare, 90 gold) is worth **2.75**, and **Tidecaller (uncommon, 50) beats it on every count**. Defensive coin gives 1.5 free a turn (Favourite only counts on turn 1). Assassin ~3.2. Crescendo ~5.6, never better than Ballast. Blood Reef ~4.0 after its health cost. Only Echo, Bilge, Barrel and Bulwark earn "rare". The alignment dice (rare, priced 30) are the strongest rares.
4. **Shipwright's Draft and Protective Rigging are far above every other keepsake**, at about 20 and 25 points a fight. Draft makes every build free (building costs a play); Rigging gives 2 block on every play, coins included.
5. **The shop keepsakes (80-120 gold) are the weakest group.** Rum adds nothing on average (+1 max, -1 min). Salted Pork ~6 HP a rest. Rations and Water Barrel need potions. Lime Juice +5 HP once. Black Purse is broken (3 gold a fight).
6. **Bolster (common) is a top-five die:** 2 x size block when it builds (8 on a d4, 16 after a Hammer), about 6.4 per play.
7. **Ink dice are worth about 60% of an attack or block die.** The starter Ink d4 is the weakest play in the bag (~1.5). Deflect (uncommon, 70) is a plain d6. Radar (common) is the only ink die well above the curve.
8. **Only 2 of the 10 cores add raw value:** Loaded (+0.5 on a d4, +0.83 on a d6, +1.17 on a d8) and Weighted (+0.28 / +0.39). The other 8 are symmetrical, so they only matter for min/max triggers.
9. **Strictly worse options:** Bouncing < Gunpowder; Tidepusher < Tidecaller; Crescendo never passes Ballast's minimum; Small Sail < Pickled Cucumber; Weapon Polish beats Rum on every plain die; Anchor is worth more left in hand (5 block, free) than played (3.5).
10. **Potions:** Healing Flask (~24 HP) and Captain's Brew (~13) are far ahead; Artisan's Ember and Mirage Brew are the weakest. All cost 25-50.

## Dice: value per play

Curve target: common +0.5 to +1.5, uncommon +1 to +2, rare +2 or more, value that needs no play counted in full.

### Common

| Die | Size, type | EV per play | Premium | Verdict | Notes |
|---|---|---|---|---|---|
| Invisible | d4 None | 2.5 + free play + draw | ~+3.75 | far above | gives back its play |
| Bolster | d4 BLK | ~6.4 | +3.9 | far above | 8 block when it builds |
| Anchor | d6 BLK | 3.5 played; 5 block free unused | +5 a turn left in hand | far above | 2 dice go unused anyway |
| Power penny | d2 BLK coin | ~4.0, no play | +2.5, free | far above | 4.5 in a 3-die slot |
| Slipstream | d4 ATK | 2.5 played; +1 play next turn unused | +3 free | above | |
| Radar | d6 INTEL | ~5.0 | +2.9 vs d6 ink | above | 6 delayed ink when it builds |
| Gunpowder | d4 ATK | 4.0 | +1.5 | above | |
| Tidebreaker | d6 ATK | 4.5 | +1.0 | on | |
| Warrior | d4 ATK | 3.25 (Edge 3.67, Binary 4.0) | +0.75 | on | |
| Accurate | d4 ATK | 3.13 | +0.63 | on | |
| Ninja | d4 BLK | ~3.2 | +0.7 | on | |
| Reed snap | d4 BLK | 3.0 | +0.5 | on | |
| Guerrilla Coin | d2 INTEL coin | ~2.2, no play | +1.3, free | on | |
| Lookout | d6 INTEL | 2.1 played; 1.8 free unused | +1.8 free | on | |
| Offhand | d6 ATK | 3.83 | +0.33 | low | |
| Balanced | d6 BLK | 3.75 | +0.25 | low | |
| Squall | d6 None | 3.75 | +0.25 | low | can't start a slot |
| Splash | d10 BLK | 3.6 | +0.1 vs d6 | low | a noisy d6 |
| Harvest | d6 BLK | 3.6 | +0.1 | low | ~25 gold over a run |
| Fogcaller | d4 BLK | 2.5 (3.5 with coins) | 0 to +1 | below unless coins | |
| Bouncing | d4 ATK | 2.5 or less | 0 or worse | below | dominated by Gunpowder |

### Uncommon

| Die | Size, type | EV per play | Premium | Verdict |
|---|---|---|---|---|
| Ballast | d8 BLK | 6.0 | +1.5 vs d8 | far above |
| Sticky | d4 None | ~5.0 (acts two turns) | +2.5 | above |
| Kill coin | d2 ATK coin | ~2.9, no play | +1.4, free | above |
| Muzzle | d4 ATK | 4.5-5.5 | +2 to +3 | above |
| Surge | d4 BLK | ~4.5 | +2.0 | on |
| Tidecaller | d6 HEAL | 4.5 | +1.0 | on |
| Inkwell | d4 INTEL | ~3.0 | +1.5 vs d4 ink | on |
| Last Stand | d6 ATK | ~4.0 | +0.5 | below |
| Deepdiver | d6 None | 3.5 | ~0 | below |
| Deflect | d6 BLK/INK | 3.5 | 0 | below (the dearest uncommon, 70) |

### Rare

| Die | Size, type | EV per play | Premium | Verdict |
|---|---|---|---|---|
| Holy (alignment) | d8 None | 6.0 neutral, up to 7.5 | +1.5 to +3 | far above (priced 30) |
| Unholy (alignment) | d6 None | 5.0 neutral, up to 6.5 | +1.5 to +3 | above (priced 30) |
| Bilge | d6 None | ~9 over two turns | +5 | above |
| Barrel | d6 BLK | ~3.5 + a potion per build | ~+4 | above |
| Bulwark | d8 BLK | ~6.25 | +1.75 | on |
| Echo | d4 None | 5.0 | +2.5 | on |
| Crescendo | d8 ATK | ~5.6 over a fight | +1.1 | below |
| Blood Reef | d6 ATK | ~4.0-4.5 net | +0.5 to +1 | below |
| Assassin | d4 ATK/INK | ~3.2 | +0.7 | below |
| Defensive coin | d2 HEAL/BLK coin | 1.5, no play | +1.5 free | far below |
| Tidepusher | d4 HEAL | 2.75 | +0.25 | far below (90 gold) |

### How much die size is worth

| Size | Average | Builds slot 3 alone | Builds slot 4 alone | Worth vs d4 per play |
|---|---|---|---|---|
| d2 (coin) | 1.5 | 0% | 0% | free (no play) |
| d4 | 2.5 | 25% | 0% | 0 |
| d6 | 3.5 | 50% | 17% | ~+1.5 |
| d8 | 4.5 | 63% | 38% | ~+3 |
| d10 | 5.5 | 70% | 50% | ~+4.5 |
| d12 | 6.5 | 75% | 58% | ~+6 |

A d4-to-d6 resize equals three Whetstones. A Loaded core is about half a size step; Weighted about a quarter.

## Cores (raw value)

| Core | d4 | d6 | d8 | Gain |
|---|---|---|---|---|
| Loaded | 3.0 | 4.33 | 5.67 | +0.5 / +0.83 / +1.17 |
| Weighted | 2.78 | 3.89 | ~5.0 | +0.28 / +0.39 / ~+0.5 |
| Edge, Binary, Bell, Dome, Compass, Lodestone, Dual, Tower | same | same | same | 0, shape only |

Nothing in the game reads the shape of Bell, Dome, Dual or Tower.

## Keepsakes: value per fight (chapter 1-2 bag)

| Keepsake | Pool | Points per fight | Verdict |
|---|---|---|---|
| Protective Rigging | rollable | ~25 | far above |
| Shipwright's Draft | rollable | ~20 | far above |
| Lantern of Patience | rollable | ~16 | above |
| Single Focus | rollable | ~12 | above |
| Cursed Heart | boss | ~12 | above |
| Medallion of the Sea | boss | ~12 while active | above, conditional |
| Cannon Splitter | rollable | ~11 | above |
| Eye patch | rollable | ~11 | above |
| Topographic Map | rollable | ~10 | above |
| Kraken's Grasp | boss | ~8 | on |
| Deep Lens | boss | ~7 over Looking Glass | on |
| Repeater Rail, Balancing Compass, Rusty Rudder, Polished Sextant | rollable | ~6 each | on |
| Captain's Ledger | rollable | ~5-7 | on |
| Deckhand's Token | event | ~4 | on |
| Looking Glass | starter | ~3.6 | baseline |
| Shield Plating, Weapon Polish, Navigation Chart | rollable | ~3 each | low |
| Pickled Cucumber | shop 100 | ~3 | low for its price |
| Rope of Repair | event | 3 heal | on |
| Starver's Efficiency | event | ~2.5 | low |
| Message in a Bottle, Crossword Puzzle | rollable | ~2 | low |
| Scavenger's Tear | boss | ~2 | below for a boss |
| Salted Pork | shop 90 | ~2 | below |
| Small Sail | event | ~1.5 | low |
| Book of Secrets | rollable | ~1.2 | below |
| Friendship Bracelet | rollable | ~1 | below |
| Bandage | rollable | 0-4 | low |
| Toolbelt | shop 100 | ~0-1 | below |
| Lucky Coin | rollable | ~0.5 | far below |
| Rations, Water Barrel | shop 110/120 | ~0.5 | far below |
| Lime Juice | shop 80 | +5 HP once | below |
| Black Purse | rollable | 0.3 (broken) | far below |
| Rum | shop 110 | 0 | far below |
| Chainmaster's Anchor, Windbound Charm, Lead Line | rollable | 0 alone; ~2-4 with their dice | below |

## Potions: value per use

| Potion | Price | Points per use |
|---|---|---|
| Healing Flask | 40 | ~24 |
| Captain's Brew | 35 | ~13 |
| Bilge-Purge Flask | 25 | ~6-7 |
| Crow's Nest Clarity | 30 | ~6 |
| Grog of Grit | 35 | ~6 |
| Corsair's Gambit | 50 | ~6 |
| Riggers Tonic | 25 | ~5 |
| Navigator's Brew | 35 | ~4-5 |
| Artisan's Ember Draught | 40 | ~3 (broken) |
| Mirage Brew | 40 | ~2-3 |

## What this suggests (for Jared to decide)

- Price free effects like an extra die: move Invisible, Power penny and Anchor to uncommon, or trim them (Invisible: draw only; Anchor: 3 block; Power penny: +1 per *other* die).
- Tone down Protective Rigging (1 block a play) and Shipwright's Draft (first build each turn only).
- Lift the bottom rares: Tidepusher to a d6 or "+2 on its max"; Defensive coin Favourite every turn; Assassin +1 minimum per 2 ink.
- Give the shop keepsakes effects worth 80-120 gold; Rum could be +1 max only.
- If ink dice should match the others, cut the reroll cost to 2 or give ink dice +2 faces.
- Give Bouncing an effect of its own so Gunpowder doesn't dominate it.
