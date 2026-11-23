# Hammer, big dice, Cutters and cores: a simulation

2026-11-23, on `dev`. Script: `docs/design/sim/sim.js` (`node docs/design/sim/sim.js [fights]`, seeded). 5,000 fights of 6 turns per scenario. Not checked in GameMaker.

**Modelled:** 6 dice dealt a turn (rolled with their core), draw and reshuffle, 4 plays (coins free), slots built for 2/4/6 pips with a coloured die, place bonus +(N-1), generics join typed slots, Hammer (same type, sizes added, max d12), Cutters (-2 sides, a coin of its type). **Left out:** enemies except a fixed incoming hit of 6 a turn, keepsakes, potions, ink (ink dice are never played, so they're dead draws: this undersells the starting bag and flatters merging ink dice). **Measure:** effective = attack + min(block, 6). **Policy:** a greedy captain (best 4 non-coin dice, smallest coloured die in slot 1, build with the smallest qualifying group, biggest dice in the latest slots).

## Short answers

- **The Hammer is too strong.** Each swing is +7 to +11% a turn and it stacks: 2 swings +14%, 3 +32%, 4 +45%. Three plain d6 rewards give +9%. Once bought, every swing is free.
- **Its power is thinning that keeps the pips, not big dice.** Bags with the same number of dice and pips made only of d6s tie with the hammered bags (13.96 vs 13.80). Past d8, more merging loses (H4 with d8s 17.48 > H4 with d12s 16.52 > H6 15.64), because generic dice can't start a slot.
- **The 6-dice hand is the limit, not the 4 plays.** Unlimited plays lift the starting bag only from 12.06 to 13.50. Pips per die decides everything; free plays (coins, Invisible's refund) are worth little, draws more.
- **A d12 beats two d6s by +0.86 a turn** (14.99 vs 14.13, +6%) despite its lower average, all from the freed hand spot. A d10 instead of a d4 + d6: +0.79.
- **The Cutters are weak:** best cut +4%, cutting everything -13% (coins fill the hand).
- **Cores:** only Weighted and Loaded raise the average (+0.24 / +0.51 a turn on one d6). The other eight are symmetrical and worth ~0 without min/max triggers. Dome and Tower never roll a min or max at any size and are identical on a d4; Bell and Dual come next. Compass and Lodestone do nothing at alignment 50. Edge and Binary pay only with min/max dice (Binary on Warrior always rolls the max).

## Starting bag, rewards and Hammer bags (effective per turn)

| Bag | Dice | Pips | Effective | vs start |
|---|---|---|---|---|
| Start (3 ATK, 3 BLK, 2 Ink, 2 Gen d4) | 10 | 40 | 12.06 | +0% |
| Start + plain d6 ATK, BLK, Gen | 13 | 58 | 13.08 | +9% |
| Start + 3 random commons | 13 | ~54 | 12.55 | +4% |
| **H2** (2 merges into d8s) | 8 | 40 | 13.80 | +14% |
| control: same dice count, d6s | 8 | 40 | 13.96 | +16% |
| thin only (dice thrown away) | 8 | 32 | 11.53 | -4% |
| **H3** | 7 | 40 | 15.96 | +32% |
| **H4** (d8s) | 6 | 40 | 17.48 | +45% |
| **H4** (d12s) | 6 | 40 | 16.52 | +37% |
| control: 6 dice, d6s | 6 | 36 | 16.91 | +40% |
| thin only, 6 d4s | 6 | 24 | 13.25 | +10% |
| **H6** (ATK d12, BLK d12, Ink d8, Gen d8) | 4 | 40 | 15.64 | +30% |
| Start minus both Ink d4s | 8 | 32 | 13.28 | +10% |

| Bag | Effective, 4 plays | Effective, unlimited plays |
|---|---|---|
| Start | 12.06 | 13.50 |
| H2 | 13.80 | 14.80 |
| H4 | 17.48 | 19.64 |

## d12 vs two d6s

| Bag | Dice | Pips | Effective |
|---|---|---|---|
| Start + ATK d6 + ATK d6 | 12 | 52 | 14.13 |
| Start + ATK d12 (the two d6s hammered) | 11 | 52 | 14.99 |
| ATK d4 + d6 hammered into a d10 | 10 | 46 | 14.02 (vs 13.23 unmerged) |

## Cutters

| Bag | Effective | vs start |
|---|---|---|
| Cut an ATK d4 (2 ATK coins) | 12.54 | +4% |
| Cut an ATK d4 and a BLK d4 | 12.13 | +1% |
| Cut all 6 ATK and BLK d4s | 10.52 | -13% |

## Cores (one die)

| Core | d6 weights | d6 average | P(lowest) d6 | P(highest) d6 | Warrior average d6 | Effective vs plain d6 |
|---|---|---|---|---|---|---|
| No core | flat | 3.50 | 17% | 17% | 4.33 | 0 |
| Weighted | 5..10 | 3.89 | 11% | 22% | 4.44 | +0.24 |
| Loaded | 1..6 | 4.33 | 5% | 29% | 4.57 | +0.51 |
| Edge | 7,2,2,2,2,7 | 3.50 | 32% | 32% | 5.09 | +0.03 |
| Binary | 1,0,0,0,0,1 | 3.50 | 50% | 50% | 6.00 | +0.06 |
| Bell | 1,2,4,4,2,1 | 3.50 | 7% | 7% | 3.86 | +0.01 |
| Dome | 0,1,3,3,1,0 | 3.50 | 0% | 0% | 3.50 | +0.01 |
| Compass / Lodestone (alignment 50) | flat | 3.50 | 17% | 17% | 4.33 | 0 |
| Dual | 1,3,1,1,3,1 | 3.50 | 10% | 10% | 4.00 | -0.05 |
| Tower | 0,1,0,0,1,0 | 3.50 | 0% | 0% | 3.50 | -0.13 |

On a d4, Dome and Tower are both 0,1,1,0. At alignment 0 a ruthless Lodestone d6 is 20,12,4,4,12,20 (28% lowest); at 100 it's 0,8,16,16,8,0 (never min or max).

## Balance levers (simulated, effective vs start 12.06)

| Rule | H2 | H3 | H4 | H4 (d12s) | H6 |
|---|---|---|---|---|---|
| As now | +14% | +32% | +45% | +37% | +30% |
| D: a merge loses 2 sides (d4+d4 = d6) | +6% | +18% | +28% | +15% | +2% |
| E: a die over d6 takes 2 hand spots | -2% | -5% | -5% | +4% | -8% |
| F: a die over d8 uses 2 plays | +14% | +32% | +45% | +0% | +2% |

1. **Best: a merge loses 2 sides.** One clear rule; halves the gain and limits itself; two swings still pay.
2. **Softer: cap swings** (once per chapter, or not below 8 dice), or a rising gold cost per swing.
3. **Don't** cap die size or charge extra plays for big dice: the d8 route is already the strongest. Rule E hits the real cause but wipes the gain out and also hits Splash, Ballast, Crescendo and Bulwark.

Related: the Cutters need a buff (e.g. the coin keeps the core, or the die keeps its sides); generic dice not starting slots quietly caps two-colour bags at 2 slots (worth keeping).

## Rerun with ink in play (2026-11-23)

`node docs/design/sim/sim.js 5000 ink`. Ink dice now play and start ink slots; an ink slot's total arrives as ink next turn (cap 12); rerolls and redraws cost 3 ink, spent greedily on the worst die below the hand's median. Enemy ink actions are still ignored. **This supersedes the "hand is the limit" finding above.**

| Bag | 6 dealt, 4 plays | 6 dealt, 5 plays | 7 dealt, 4 plays | +1 play | +1 die dealt |
|---|---|---|---|---|---|
| Start | 12.06 | 13.62 | 12.89 | **+1.56** | +0.83 |
| H2 | 13.98 | 16.23 | 15.15 | **+2.25** | +1.17 |
| H4 | 17.32 | 19.83 | 17.32 | **+2.51** | +0.00 |

- **With ink in play the 4 plays are the tighter limit:** +1 play is worth about twice +1 die dealt, matching Jared's playtest feel. (Every extra play also tends to build another slot and earn its place bonus.)
- **Ink is weak currency:** each point is worth about 0.2-0.5 effective, so a 3-ink reroll is worth 0.6-1.4 pips. About 1 ink a turn goes unspent; almost none hits the cap.
- **The Hammer is still too strong:** +16% / +33% / +44% for 2 / 3 / 4 merges, and the d6 controls still tie (14.16 vs 13.98). The new outlier is H6 (d12, d12, Ink d8, Gen d8) at **+59%**: every die is dealt and played each turn, and the Ink d8 funds ~1.4 rerolls of the d12s.

| Rule | H2 | H3 | H4 (d8s) | H4 (d12s) | H6 |
|---|---|---|---|---|---|
| As now | +16% | +33% | +44% | +38% | +59% |
| A merge loses 2 sides | +6% | +18% | +27% | +15% | +23% |
