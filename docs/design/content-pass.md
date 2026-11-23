# Content pass (F242)

Worksheet for the dice and keepsake pass, section by section, against `principles.md`. For each: what's there now, what the checks found (`analysis-*.md`), the proposal, and Jared's call. Once every section is agreed, it's built as one batch.

Values are "points per play" (dice) or "points per fight" (keepsakes) from `analysis-power-curve.md`. Plain d4 2.5, d6 3.5, d8 4.5.

## 1. Reprice free value (never common)

Rule: anything that gives value without using a play is uncommon or rarer and kept small. **Plain coins** (just "doesn't use a play") can be common, as Coin swarm's entry piece; coins with an effect on top are uncommon or rarer (Jared, 2026-11-23). Builders now count as played (F238), which makes the per-play keepsakes stronger than when they were measured.

### Dice

| Die | Now | Value | Proposal |
|---|---|---|---|
| Invisible die | common, d4 generic: when played, draw 1 and +1 play | ~+3.75 premium, far above | **Uncommon**, effect unchanged |
| Power penny | common, BLK coin: +1 per die in its slot | ~4.0 free, far above | **Uncommon** (a coin with an effect) |
| Guerrilla Coin | common, ink coin: builds a slot, half your ink as damage | ~2.2 free | **Uncommon** (a coin with an effect) |
| Anchor die | common, d6 BLK, Stowaway: unused, 5 block | +5 a turn left in hand, far above | **Uncommon**, effect unchanged |
| Slipstream die | common, d4 ATK, Stowaway: unused, +1 play next turn | +3 free, above | **Uncommon**, effect unchanged |
| Lookout die | common, d6 ink, Stowaway: unused, 3 ink next turn | +1.8 free | **Uncommon**, effect unchanged |
| Fogcaller Die | common, d4 BLK, Followthrough: after a coin slot, +1 and draw 1 | fires 10-20% of plays | **Stays common**: a conditional Coin swarm payoff, not free value most turns |

Coin swarm then has no common coin. Section 6 adds plain common coins (one per action type) to the dice pool.

### Keepsakes

| Keepsake | Now | Value | Proposal |
|---|---|---|---|
| Protective Rigging | rollable: play a die, 2 block | ~25 a fight, the strongest keepsake | **1 block** per die played |
| Shipwright's Draft | rollable: build a slot, +1 play this turn | ~20 a fight (building becomes free) | **The first slot you build each turn** gives +1 play |
| Lantern of Patience | rollable: each unused die, 2 block | ~16 a fight | **1 block** per unused die |
| Eye patch | rollable: play a die, 1 ink next turn | ~11 a fight | **Unchanged**: ink is a weak currency, and it's Full ink's enabler |
| Kraken's Grasp, Pickled Cucumber, Medallion | boss / shop: +1 play | boss and shop prices already | **Unchanged** |

**Jared's call (section 1):** accepted as proposed, 2026-11-23.

## 2. Lift the weak rares

Rule: a rare is like a Slay the Spire gold card: clearly above the curve, and usually build-defining or rule-bending. Plain uncommon d8 (Ballast) is worth 6.0 a play, so a rare should beat ~6 or define a build.

| Die | Now | Value | Proposal | Archetype |
|---|---|---|---|---|
| Tidepusher die | rare 90, d4 heal, Exclusive, Overboard: its max heals 1 more | 2.75, far below; worse than the uncommon Tidecaller | **d6, Overboard, "Heals double."** No Exclusive. One big heal a fight (~7). | survival |
| Defensive coin | rare 70, coin, Heal or Block, Favourite, Overboard | 1.5 free, far below | **A Block coin, Favourite: "Its slot's Block lasts until your next turn."** No heal, no Overboard. Block that carries over is Fortress's missing engine. | Fortress |
| Assassin die | rare 70, d4 Attack or Ink: +1 min per 3 ink held | ~3.2, below | **d6, "+1 minimum roll per 2 ink held."** A Full ink payoff that also hits. | Full ink |
| Crescendo die | rare 80, d8 Attack: +1 min each play this fight, up to half | ~5.6, never beats Ballast | **"+1 each time it's played this fight"** (added to its roll, no cap). Grows all fight. | Heavy hitters |
| Blood Reef die | rare 80, d6 Attack: +2 when attacking, lose 1 health | ~4.0-4.5 net, below | **"When played: lose 1 health, gain 2 Might this turn."** Might lifts every Attack die this turn: the first real Might engine piece. | Infinite might |
| Bulwark die | rare 70, d8 Block, Followthrough: slot before is Block, 2 x min damage to all | ~6.25, "on" but the payoff is ~2 damage | **"Followthrough: if the slot before is Block, deal your current Block as damage to all enemies."** Fortress's punish. | Fortress |
| Echo, Bilge, Barrel, Holy, Unholy | | above the curve | **Unchanged** | |

**Jared's call (section 2), 2026-11-23:** accepted, except:
- **Tidepusher:** not a big heal ("healing should be very rare indeed, and quite dependent on certain triggers"). Instead: **a Block die, Overboard: heal 1 for each enemy hit its Block fully stops this turn.** Rewards timing it on the track (a Fortress bridge).
- **Blood Reef:** **when it's dealt, gain 1 Might, lose 3 health.**

## 3. Strictly worse, dead, too strong (commons and uncommons)

New principle (Jared): **healing is very rare and depends on triggers.**

| Piece | Now | Finding | Proposal |
|---|---|---|---|
| Bouncing Die | common d4 Attack: switches to a random target (and keeps it: bug) | strictly worse than Gunpowder (same price, same pool) | **"Attacking: half its roll also hits another enemy."** No target change. |
| Bolster Die | common d4 Block: builds a slot, 2 x size block (8, 16 after a Hammer) | ~6.4 a play, a top-five die as a common | **1 x size** block (4 on a d4) |
| Splash Die | common d10 Block: -2 every roll, min 0 | a noisy d6 (~3.6); a poor builder | **-1 every roll, never below 1.** Heavy hitters' common big die (~4.6). |
| Tidecaller die | uncommon d6 Heal, Overboard: 5+ also gains 3 block | a plain heal die (~3.5 heal) breaks the new healing rule | **A d6 Block die: if it rolls 5 or higher, also heal 3.** Overboard. Heal on a trigger. |
| Deflect Die | uncommon 70, d6 Block or Ink | a plain d6 (0 premium), the dearest uncommon | **"+2 while you hold 6 or more ink."** Full ink and Fortress bridge. |
| Chainmaster's Anchor | rollable: the first Followthrough bonus each turn counts twice | ~0 alone | **Every** Followthrough bonus counts twice. |
| Lucky Coin | rollable: coins roll 2 twice as often | ~0.5 a fight | **"Each coin you play gives 1 block."** A Coin swarm payoff. |
| Small Sail | event: draw 2 more on turn 1 | worse than Pickled Cucumber (+1 play on turn 1) | **Draw 1 more every turn.** It's an event reward, rarely seen. |
| Medallion of the Sea | boss: +1 play below 20 or above 80 alignment | fires in ~5% of runs without steering | **Below 30 or above 70.** (Section 7 may do more for alignment.) |
| Deepdiver, Single Focus, Message in a Bottle, Crossword Puzzle, Friendship Bracelet, Bandage | | small but honest | **Unchanged** for now |

**Jared's call (section 3):** accepted as proposed, 2026-11-23.

## 4. Shop keepsakes (80-120 gold)

They're the weakest group (most worth 0-3 a fight). Target: worth its price (~8-12 a fight) and, where it fits, a step on an archetype's ladder. New archetype keepsakes for the shop come in section 6.

| Keepsake | Now | Value | Proposal |
|---|---|---|---|
| Lime Juice (80) | lose 5 health, +10 max health | +5 HP once | **+10 max health** (no loss; the bar grows, you don't heal) |
| Salted Pork (90) | Calm water heals 10% more | ~2 | **Calm water heals 15% more** (a trigger heal, fits the healing rule) |
| Pickled Cucumber (100) | +1 play on turn 1 | ~3 | **+1 play and draw 1 on turn 1** |
| Toolbelt (100) | +2 item slots | ~0-1 before; more now (cores sit in item slots and the Drill is unlimited) | **Unchanged** |
| Rum (110) | Attack dice +1 max, -1 min (never below 1) | ~0-1 | **Attack dice +1 max roll** (no minus). A Heavy hitters step. |
| Rations (110) | drink a potion, heal 3 | ~0.5 | **Drink a potion: heal 3 and draw a die** |
| Water Barrel (120) | potions 30% not used up | ~0.5 | **50%** (item rewards are back, so potions turn up) |

**Jared's call (section 4):** accepted as proposed, 2026-11-23.

## 5. Cores: give every shape a payoff

Decided: keep the shapes and add content that rewards them. Today only Weighted and Loaded add value; Edge and Binary pay off with min/max effects; Bell, Dome, Dual and Tower have nothing; Compass and Lodestone are flat at neutral alignment.

| Shape | Which faces | New payoff (proposal) |
|---|---|---|
| Bell, Dome | the middle (Dome never its min or max) | **Plumb Line die** (new, common, d6 Block): "+2 if it rolls a middle face." **Spirit Level** (new keepsake, rollable): "Dice that roll a middle face get +1." (Middle = the one or two faces in the centre of its range: 3-4 on a d6, 2-3 on a d4.) Fortress's steady side. |
| Dual, Tower | next to the ends (one off its min or max) | **Grapnel die** (new, uncommon, d6 Attack): "If it rolls one below its max, it counts as its max +2." **Sounding Line** (new keepsake, rollable): "When a die rolls one below its max, draw a die." |
| Compass, Lodestone | lean with alignment, flat at 50 | **Full lean at 30 and 70** instead of 0 and 100 (they reach their shape much sooner). Alignment extremes' core. |
| Edge, Binary | the ends | Unchanged (the Valleys payoffs exist) |
| Weighted, Loaded | high | Unchanged (they add raw value) |

**Jared's call (section 5):** accepted as proposed, 2026-11-23.

## 6. Archetype gaps, filled by the rarity ladder

Each archetype: **common enablers** (fight rewards), **uncommon payoffs** (dice, shop keepsakes), a **rare or boss engine piece**. "Existing" includes the changes agreed above. New pieces are first drafts, to tune in play.

### Full ink (control): grow max ink, cheaper ink, pay off spending
- Existing: ink d4s, Lookout (uncommon), Radar, Eye patch, Deepdiver, Assassin (rare, now +1 min per 2 ink), Deflect (+2 at 6+ ink), Deep Lens (boss).
- **New common: Inkpot die** (d4 Ink): "When played: +2 max ink this fight."
- **New uncommon: Calligrapher's die** (d6 Ink): "+1 for each ink you spent this turn."
- **New uncommon (shop keepsake): Sharpened Quill**: "Rerolls and redraws cost 2 ink."
- **New boss keepsake: Captain's Logbook**: "Max ink 20. Rewriting an intent costs 4."

### Infinite might (thin and punch): Might that builds
- Existing: Offhand (min roll: 1 Might), Blood Reef (rare, now 1 Might when dealt for 3 health), Grog of Grit, thinning (Squall stop, events, Scavenger's Tear, Hammer).
- **New common: Grit die** (d4 Attack): "If it rolls its max, gain 1 Might this turn."
- **New uncommon (rollable keepsake): Iron Grip**: "While your bag has 10 or fewer dice, Might lasts until the end of the fight."
- **New boss keepsake: War Drum**: "At the start of each turn, gain 1 Might for every die your bag has under 12."

### Valleys (low rolls pay): something that scales
- Existing: Warrior, Offhand, Edge/Binary cores, coins, ink rerolls, Topographic Map, Navigation Chart, Balancing Compass, Rusty Rudder (all rollable keepsakes).
- **New uncommon: Undertow die** (d6 Attack): "+1 for each die that rolled its minimum this turn."
- **New rare: Riptide die** (d4 Attack): "If it rolls its minimum, it counts as double its max."

### Coin swarm: plain common coins, payoffs that count coins
- Existing: Power penny, Guerrilla Coin, Kill coin (all uncommon now), Fogcaller, Lucky Coin (now 1 block per coin), Protective Rigging, Repeater Rail, the Cutters.
- **New commons: Copper coins** (plain d2 coins: Attack, Block and Ink).
- **New uncommon: Purser's die** (d6 Block): "+1 for each coin played this turn."
- **New rare: Doubloon** (d4 coin, Attack): "Doesn't use a play. +1 for each other coin in its slot."

### Heavy hitters: payoffs for size and late slots
- Existing: Splash (now -1), Ballast, Crescendo (rare, now +1 each play), Rum (now +1 max on Attack), Hammer, Whetstone, Loaded/Weighted cores, Muzzle, Kill coin.
- **New uncommon: Broadside die** (d8 Attack): "+2 in slot 3 or later."
- **New uncommon (rollable keepsake): Heavy Rigging**: "Dice d8 or bigger get +1."
- **New rare: Carronade die** (d12 Attack): "Uses 2 plays."

### Fortress (block and punish): Block that carries and hits back
- Existing: 13 Block dice, Shield Plating, Lantern (now 1), Balanced, Captain's Brew, Defensive coin (rare, now Block lasts to your next turn), Bulwark (rare, now deals your Block), Tidepusher (rare, heals per hit fully stopped), Tidecaller.
- **New common: Barnacle die** (d4 Block, Followthrough): "+2 if the slot before is Block."
- **New uncommon (rollable keepsake): Spiked Hull**: "When your Block fully stops an enemy's hit, deal 3 damage to it."

### Alignment extremes: a repeatable push and more payoffs
- Existing: events, kill/spare, Holy and Unholy (crossroads only), Medallion (now 30/70), Compass and Lodestone (now full lean at 30/70), Siren's Call.
- **New commons: Mercy die** (d4 Block): "When played: +1 alignment." **Cutthroat die** (d4 Attack): "When played: -1 alignment."
- **New uncommon (rollable keepsake): Weathervane**: "While alignment is below 30 or above 70, every die gets +1."
- **Holy and Unholy also join the rare dice pool** (still from the crossroads fight too).

**Jared's call (section 6):** accepted as v1 (first drafts, tune in play), 2026-11-23.
