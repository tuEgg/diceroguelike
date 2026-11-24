# Content catalogue (for the build-archetype review, Q17)

Read from the code on `dev`, 2026-11-23 (scDice, scKeepsakes, scItems, scShop, scEvents, scMap, scBounties, scCombatScripts, oRunManager, oWorkbenchManager). Numbers are quoted from the code. Where I'm not sure, it says so.

**Counts:** 40 pooled dice + 2 alignment dice (+ 4 starter dice in the bag and 10 unused or internal templates), 42 keepsakes (1 starter, 7 shop, 4 event-only, 25 rollable, 5 boss), 10 cores, 10 potions (plus the "Coins" item), 3 tools.

**Rules that shape everything below:** every die rolls as it is dealt (`die_roll_faces`) and keeps that face. 6 dice dealt a turn, 4 plays. Coins (d2) don't use a play. Every turn starts with one slot. Building slot N costs 2 x (N-1) pips (Cursed Heart -2, never below 1), and built slots are removed at the end of the round unless a Sticky die is still in one. Each slot gets a "Slot N" place bonus of +index on its first die. Enemy moves happen after a set slot (the timeline).

## Tag vocabulary

| Tag | Means |
|---|---|
| high-roll | triggers on a face at or above a number |
| max-roll | triggers on the die's highest face |
| min-roll | triggers on the die's lowest face |
| min-up | raises the minimum roll |
| max-up | raises the maximum or the size |
| twice | rolls twice, keeps the higher |
| shape | changes the face weighting (cores, Lucky Coin) |
| slot-pos | depends on which slot it's in, or how many slots there are |
| stack | depends on the dice in the same slot |
| followthrough | depends on the slot before |
| build | fires when the die builds a slot ("when it builds a slot") |
| played | fires when the die is played into a slot ("when played") |
| unused | rewards a die left in hand (Stowaway, Lantern) |
| plays | gives extra plays |
| draw | draws extra dice |
| coin | about d2s |
| ink | gains, spends or scales with ink (INTEL) |
| alignment | scales with alignment |
| size | cares about the die's size |
| block / heal / dmg | adds block, healing or extra damage outside the slot total |
| aoe | hits several or random enemies |
| buff | Might or Balance |
| debuff | reacts to debuffs |
| gold / potion | gives gold or potions |
| hp-cost | costs health |
| parity | odd/even |
| types | counts action types |
| sticky / favourite / multitype / exclusive / stowaway | the keyword itself |

## 1. Dice

Trigger names: `on_roll_die` (bonus live in the slot total, also run for previews and on deal), `on_die_rolled` (as the die is dealt or rerolled with ink), `after_roll_die` (as the slot resolves), `on_dice_played_to_slot`, `on_sacrifice_die` (building a slot), `on_not_used` (left in hand at End Turn), `on_die_inked`. "Rarity (price)" is the die's own field.

### Starting bag (10 dice, `generate_dice_bag`)

| Name | Size | Type | Rarity | Keywords | Does | Trigger | Tags | In bag |
|---|---|---|---|---|---|---|---|---|
| Attack | d4 | ATK | starter | - | Deals damage | - | - | x3 |
| Block | d4 | BLK | starter | - | Blocks damage | - | - | x3 |
| Ink | d4 | INTEL | starter | - | Provides ink (next turn) | - | ink | x2 |
| Generic die | d4 | None | starter | - | Adds to any slot; can't start a slot | - | - | x2 |

Starter keepsake: Looking Glass. Starting tool: the Drill. 50 gold, 60 HP, 3 item slots.

### Pooled dice (`global.master_dice_list`, 40)

| Name | Size | Type(s) | Rarity (price) | Keywords | Does | Trigger(s) | Tags |
|---|---|---|---|---|---|---|---|
| Anchor die | d6 | BLK | common (30) | Stowaway | Unused: gain 5 block | on_not_used | unused, block |
| Slipstream die | d4 | ATK | common (40) | Stowaway | Unused: +1 play next turn | on_not_used | unused, plays |
| Tidebreaker die | d6 | ATK | common (50) | Followthrough | +2 if slot before is BLK | on_roll_die | followthrough |
| Power penny | d2 | BLK | common (50) | Coin | +1 per die in its slot (counts itself) | on_roll_die | coin, stack |
| Invisible die | d4 | None | common (30) | - | Played: draw 1, +1 play | on_dice_played_to_slot | played, draw, plays |
| Squall die | d6 | None | common (50) | - | Rolls 5+: draw a die | on_die_rolled | high-roll, draw |
| Reed snap die | d4 | BLK | common (30) | - | Rolls 4+: gain 2 block | after_roll_die | high-roll (max on a d4), block |
| Fogcaller Die | d4 | BLK | common (40) | Followthrough | Slot before holds a coin: +1; and draw 1 when played there | on_roll_die, on_dice_played_to_slot | followthrough, coin, draw |
| Bolster Die | d4 | BLK | common (50) | - | Builds a slot: gain {max2} block (2 x size) | on_sacrifice_die | build, block, size |
| Accurate Die | d4 | ATK | common (40) | - | Rolls twice, keeps higher | on_roll_die (on deal) | twice |
| Harvest Die | d6 | BLK | common (50) | - | Played or builds a slot: 1 gold | on_dice_played_to_slot, on_sacrifice_die | played, build, gold |
| Lookout die | d6 | INTEL | common (40) | Stowaway | Unused: 3 ink next turn | on_not_used | unused, ink |
| Bouncing Die | d4 | ATK | common (40) | - | Attacking: switch to a random target | on_roll_die | aoe |
| Guerrilla Coin | d2 | INTEL | common (40) | Coin | Builds a slot: half your ink as damage to a random enemy | on_sacrifice_die | coin, build, ink, dmg, aoe |
| Radar die | d6 | INTEL | common (40) | - | Builds a slot: 3 ink next turn and the turn after | on_sacrifice_die | build, ink |
| Offhand die | d6 | ATK | common (30) | - | Rolls {min}: 1 Might this turn | on_die_rolled | min-roll, buff |
| Balanced die | d6 | BLK | common (30) | - | Rolls {max}: 1 Balance | on_die_rolled | max-roll, buff |
| Ninja die | d4 | BLK | common (40) | Followthrough | +2 if slot before is ink | on_roll_die | followthrough, ink |
| Warrior die | d4 | ATK | common (30) | - | Rolls of {min} become {max} | on_die_rolled | min-roll, max-roll |
| Splash Die | d10 | BLK | common (60) | - | -2 on every roll, min 0 | on_roll_die | size |
| Gunpowder die | d4 | ATK | common (40) | - | Attacking: every other enemy takes 2 | after_roll_die | aoe, dmg |
| Surge die | d4 | BLK | uncommon (40) | - | +1 per slot after it | on_roll_die | slot-pos |
| Kill coin | d2 | ATK | uncommon (40) | Coin | +2 in the last slot | on_roll_die | coin, slot-pos |
| Muzzle die | d4 | ATK | uncommon (60) | Followthrough | +1 per slot before it | on_roll_die | followthrough, slot-pos |
| Sticky die | d4 | None | uncommon (50) | Sticky | Nothing else | - | sticky |
| Deepdiver Die | d6 | None | uncommon (50) | - | Rerolled or redrawn with ink: draw a die | on_die_inked | ink, draw |
| Inkwell Die | d4 | INTEL | uncommon (50) | - | +1 per action type in your queue | on_roll_die | ink, types, slot-pos |
| Deflect Die | d6 | BLK / INTEL | uncommon (70) | Multitype | Block or Ink | - | multitype, ink, block |
| Last Stand Die | d6 | ATK | uncommon (60) | - | +1 min per 20% health missing | on_roll_die | min-up, hp-cost |
| Tidecaller die | d6 | HEAL | uncommon (50) | - | Rolls 5+: also gain 3 block | after_roll_die | high-roll, heal, block |
| Ballast die | d8 | BLK | uncommon (55) | - | Never rolls below 4 | on_roll_die | min-up, size |
| Defensive coin | d2 | HEAL / BLK | rare (70) | Coin, Favourite, Multitype | Heal or Block | - | coin, favourite, multitype, heal, block |
| Tidepusher die | d4 | HEAL | rare (90) | Exclusive | Rolls exactly 4: heals 5 | after_roll_die | exclusive, max-roll, heal |
| Bulwark die | d8 | BLK | rare (70) | Followthrough | Slot before is BLK: {min2} damage to all enemies | after_roll_die | followthrough, aoe, dmg |
| Crescendo die | d8 | ATK | rare (80) | - | +1 min each time played this combat, up to {half} | on_roll_die | min-up, size |
| Blood Reef die | d6 | ATK | rare (80) | - | Attacking: +2, lose 1 health | on_roll_die | dmg, hp-cost |
| Bilge die | d6 | None | rare (80) | Sticky | Total is even: heal 2 | after_roll_die | sticky, parity, heal |
| Echo Die | d4 | None | rare (60) | - | Played: a copy joins its slot | on_dice_played_to_slot | played, stack |
| Barrel Die | d6 | BLK | rare (70) | - | Builds a slot: a random potion | on_sacrifice_die | build, potion |
| Assassin Die | d4 | ATK / INTEL | rare (70) | Multitype | +1 min per 3 ink held | on_roll_die | multitype, ink, min-up |

By rarity: 21 common, 10 uncommon, 9 rare. Single-type: ATK 12, BLK 13, None 6, INTEL 4, HEAL 2, plus 3 multitype (BLK/INTEL, HEAL/BLK, ATK/INTEL). Sizes: d2 x4, d4 x17, d6 x15, d8 x3, d10 x1.

### Alignment dice (`global.alignment_dice_list`, only from alignment encounters)

| Name | Size | Type | Rarity (price) | Keywords | Does | Trigger | Tags |
|---|---|---|---|---|---|---|---|
| Holy die | d8 | None | rare (30) | - (text starts "Alignment:", not a keyword) | +1 min per alignment stage (0-6) | on_roll_die | alignment, min-up |
| Unholy die | d6 | None | rare (30) | - | max + (6 - stage): a d6 rolls up to 12 at stage 0, 9 at neutral | on_roll_die | alignment, max-up |

Alignment stage (oRunManager Draw GUI): 0 below 10, 1 below 25, 2 below 40, 3 below 60, 4 below 75, 5 below 90, 6 to 100.

### Unused or internal templates

d6 Generic / Attack / Block (in `starter_dice_list`, used to load saves by name, never dealt), d4 Heal (defined, never used: no HEAL in the starting bag), Multicolor die (d4, "All", "Counts as anything"; rarity "starter", never offered, used as a placeholder in `generate_dice_rewards`), and five plain d2 coins (Generic., Attack., Block., Ink., Heal.) that the Cutters hand out.

## 2. Keepsakes

| Name | Pool (price) | Does | Trigger | Tags |
|---|---|---|---|---|
| Looking Glass | starter | Start each combat with 6 ink | on_turn_start (turn 1) | ink |
| Lime Juice | shop (80) | Lose 5 health, +10 max health | on_keepsake_acquired | heal, hp-cost |
| Salted Pork | shop (90) | Calm water heals 10% more | on_rest | heal |
| Pickled Cucumber | shop (100) | +1 play on turn 1 | on_turn_start | plays |
| Toolbelt | shop (100), also an event | +2 item slots | on_keepsake_acquired | potion |
| Rum | shop (110) | Attacks: +1 max, -1 min | on_roll_die | max-up (its -1 min can make a 0 face) |
| Rations | shop (110) | Drink a potion: heal 3 | on_consumable_used | potion, heal |
| Water Barrel | shop (120) | Potions 30% not used up | on_consumable_used | potion |
| Small Sail | event (Broken sails, 10 gold) | Draw 2 more on turn 1 | on_turn_start | draw |
| Rope of Repair | event (Broken sails, lose an item) | Heal 3 at the start of each combat | on_turn_start | heal |
| Deckhand's Token | event (Pirate Prisoner, 10 gold) | First die in slot 1 gets +1 | on_roll_die | slot-pos |
| Starver's Efficiency | event (A Great Storm) | First Block die dealt each turn rolls twice | on_roll_die (on deal) | twice, block |
| Black Purse | rollable | After combat, 3 gold per slot | on_combat_end | gold, slot-pos |
| Shipwright's Draft | rollable | Build a slot: +1 play this turn | on_new_slot_created | build, plays |
| Cannon Splitter | rollable | First ATK slot each turn also hits other enemies for 75% | after_slot_damage_calculated | aoe, slot-pos |
| Bandage | rollable | You're debuffed: slot 1 +1 for the fight (stacks) | on_player_debuffed | debuff, slot-pos |
| Single Focus | rollable | First die in each single-type slot +1 | queue changes | slot-pos, types |
| Repeater Rail | rollable | Each die +1 per die before it in its slot | on_roll_die | stack |
| Chainmaster's Anchor | rollable | First Followthrough each turn triggers twice | on_roll_die | followthrough |
| Lantern of Patience | rollable | Each unused die: 2 block | on_not_used | unused, block |
| Windbound Charm | rollable | Stowaway effects also fire when played | on_dice_played_to_slot | stowaway, played |
| Lead Line | rollable | A die building a slot fires its "when played" twice | on_sacrifice_die | build, played |
| Friendship Bracelet | rollable | Give a die Favourite | on_keepsake_acquired | favourite |
| Topographic Map | rollable | Play a max roll: its slot +2 this turn. A min roll draws a die, 2 a turn | on_die_rolled, on_dice_played_to_slot | max-roll, min-roll, draw |
| Navigation Chart | rollable | A min roll: next die dealt rolls twice | on_die_rolled, on_roll_die | min-roll, twice |
| Balancing Compass | rollable | A min roll: next die dealt rolls its max | on_die_rolled, on_roll_die | min-roll, max-roll |
| Message in a Bottle | rollable | Random extra die (master list) each combat | on_turn_start | draw |
| Polished Sextant | rollable | +1 min on d4s | on_roll_die | min-up, size |
| Shield Plating | rollable | +1 min on Block | on_roll_die | min-up, block |
| Weapon Polish | rollable | +1 min on Attack | on_roll_die | min-up |
| Crossword Puzzle | rollable | +1 min on generic dice | on_roll_die | min-up |
| Book of Secrets | rollable | +1 min on ink | on_roll_die | min-up, ink |
| Lucky Coin | rollable | Coins roll 2 twice as often as 1 ("loaded") | on_roll_die | coin, shape |
| Protective Rigging | rollable | Play a die: 2 block (also skips the Sirens' damage) | on_dice_played_to_slot | played, block |
| Captain's Ledger | rollable | Bag runs out: 5 damage to all, 3 gold | on_bag_empty | aoe, gold |
| Rusty Rudder | rollable | A min roll: that much damage to a random enemy | on_die_rolled | min-roll, aoe, dmg |
| Eye patch | rollable | Play a die: 1 ink next turn | on_dice_played_to_slot | played, ink |
| Kraken's Grasp | boss | +1 play, 1 fewer die drawn each turn | on_turn_start | plays |
| Deep Lens | boss | First 2 turns start at 12 ink; replaces Looking Glass | on_turn_start | ink |
| Scavenger's Tear | boss | Remove 2 dice from your bag | on_keepsake_acquired | (thin bag) |
| Medallion of the Sea | boss | +1 play while alignment is below 20 or above 80 | on_turn_start | alignment, plays |
| Cursed Heart | boss | New slots cost 2 fewer pips | on_combat_started | slot-pos, build |

Pools: rollable = elites, treasure, events ("Some old loot", "A bird flies aboard", "The Flying Dutchman"), bounty contracts. Shop keepsakes only in shops (3 on the shelf). Boss keepsakes only from bosses (3 offered). Event keepsakes only from their event. A keepsake you own is never offered again.

## 3. Cores

Cores change a die's `distribution` (weights over its faces from min to max, `define_dice_distributions`). Fitted at the workbench with the Drill (not on coins), or fitted already in the quartermaster's offer and by Grapeshot. Weights below are for the die's faces lowest to highest.

| Core | Rarity (price) | Shape | d4 | d6 | Good with |
|---|---|---|---|---|---|
| Weighted Core | uncommon (50) | Mild lean high: weight = max - 2 + face; top face always 2x the bottom | 3,4,5,6 | 5,6,7,8,9,10 | high-roll thresholds (Squall, Tidecaller, Reed snap), anything that wants totals |
| Loaded Core | rare (75) | Weight = the face number | 1,2,3,4 | 1,2,3,4,5,6 | Balanced, Topographic Map's max, Tidepusher, Squall |
| Edge Core | uncommon (50) | 7 on min and max, 2 between (78% edges on a d4, 64% d6, 54% d8) | 7,2,2,7 | 7,2,2,2,2,7 | Warrior (min becomes max), min and max triggers together (Topographic Map, Rusty Rudder, Nav Chart, Balancing Compass, Offhand, Balanced) |
| Binary Core | rare (75) | Only min or max, 50/50 | 1,0,0,1 | 1,0,0,0,0,1 | Warrior (always max), every min/max trigger |
| Bell Core | uncommon (50) | Powers of 2 up to the middle | 1,2,2,1 | 1,2,4,4,2,1 | steady totals; kills min/max triggers |
| Dome Core | rare (75) | Never min or max; powers of 3 to the middle | 0,1,1,0 | 0,1,3,3,1,0 | steady totals; anti-synergy with every min/max effect |
| Compass Core | uncommon (50) | Flat at alignment 50; ruthless leans to the edges, merciful to the middle (65% strength) | ruthless ~17,8,8,17 / merciful ~4,12,12,4 | ruthless ~17,11,6,6,11,17 / merciful ~4,9,14,14,9,4 | alignment builds: ruthless = Edge's partners, merciful = Bell's |
| Lodestone Core | rare (75) | As Compass at full strength | ruthless 20,7,7,20 / merciful 0,13,13,0 | ruthless 20,12,4,4,12,20 / merciful 0,8,16,16,8,0 | as Compass, stronger |
| Dual Core | uncommon (50) | 3 on the second-lowest and second-highest faces, 1 elsewhere | 1,3,3,1 | 1,3,1,1,3,1 | little; on a d4 it's nearly Bell |
| Tower Core | rare (75) | Only the second-lowest or second-highest face | 0,1,1,0 | 0,1,0,0,1,0 | little; on a d4 it's identical to Dome |

Notes:
- On the d4s the whole starting bag is made of, the cores collapse: Dome and Tower are the same (2 or 3 only), Bell (1,2,2,1) and Dual (1,3,3,1) nearly the same, Edge and Binary close.
- Lucky Coin's "loaded" weighting overrides a core on a d2, but coins can't take cores anyway.
- Grapeshot picks from all 10 shapes at random (`get_random_distribution`), straight onto a die.
- How often: see Sources. Roughly, about 30% of normal item cards are cores (25% uncommon, 5% rare at luck 50), 40% of shop item cards, every boss item card (rare), every quartermaster card, the wreck. Of cores rolled with the "core" filter, 5 in 6 are uncommon at luck 50.

## 4. Potions (consumables)

All rarity "common". Used from the item bar (`on_clicked`) or dragged onto a slot (`on_item_played_to_slot`). Most only work on your turn in a fight.

| Name | Price | Does | Use | Tags |
|---|---|---|---|---|
| Riggers Tonic | 25 | Every die in a slot +2 this turn | onto a slot | stack |
| Bilge-Purge Flask | 25 | Empty a slot, +3 plays this turn | onto a slot | plays |
| Artisan's Ember Draught | 40 | A random die in hand +4 max (size) this combat | click | max-up, size |
| Corsair's Gambit | 50 | +1 play per enemy this turn, min 2 | click | plays |
| Mirage Brew | 40 | Copy a random die in hand for this combat | click | draw |
| Crow's Nest Clarity | 30 | 10 ink next turn | click | ink |
| Grog of Grit | 35 | 3 Might this turn | click | buff |
| Captain's Brew | 35 | 3 Balance for the rest of combat | click | buff, block |
| Navigator's Brew | 35 | Draw 4 dice; in combat +1 play (at the workbench, 4 dice from the bag onto the table) | click | draw, plays |
| Healing Flask | 40 | Heal 40% max health (any time) | click | heal |

The "Coins" item (30-45 gold) can replace a normal item card: any common pick has a 10% chance (`irandom(100) < 10`) of turning into gold, and never in shops or events.

## 5. Tools (workbench)

The workbench (`oWorkbenchManager`, "the free bench") is reached from the Shipwright sea stop or the harbour's refit before a boss. Each tool crafts once per visit. Misses cost nothing.

| Tool | Price | Where from | Exact rule |
|---|---|---|---|
| The Drill | 125 (not sold) | Every run starts with it | Load a core from the item bar into the chuck, drop on a die bigger than a coin: the die takes the core's distribution (replacing any core). "Coins can't take a core." |
| The Hammer | 150 | Shop tool shelf (1 per shop while any are unowned), or "A precious ingot" (random tool) | Two dice with the same `action_type`, sizes added at most 12: one die of the summed size. The die with a core carries on (its name and effects); if both have cores, one of the two at random; if neither, the first of the pair. The other die's effects are lost. A hammered coin stops being a coin. Multitype dice compare by their first type (`action_type`). |
| The Cutters | 165 | As the Hammer | A die bigger than a d2 loses 2 sides; a plain coin of its `action_type` (generic, ATK, BLK, INTEL or HEAL) hops out. Cut down to a d2 it becomes a coin and loses its core. |

## 6. Sources

**Dice rarity odds** (`generate_dice_rewards`, roll 1-200; luck starts at 50):

| Where | Common | Uncommon | Rare |
|---|---|---|---|
| Normal fight, elite, events, quartermaster | 80% | 19.5% (roll <= 40 + (luck-50)/2) | 0.5% (roll <= 1 + (luck-50)/10) |
| Shop shelf (4 dice) | 60% | 30% | 10% |
| Bounty contract die | as a normal fight on the first board (rolled on the map); 0% / 50% / 50% on a board rerolled in the bounty room | | |
| Fight where you spared every enemy, alignment encounter | 0% | 0% | 100% |
| Boss | - | - | 100% (3 rare dice) |

**Item odds** (`generate_item_rewards`, roll 1 to 200 - 20 x cards already picked): rare <= 10 + (luck-50)/5, uncommon <= 60 + (luck-50)/2, else common. Rare and uncommon items are only cores; common items are potions and Coins. So at luck 50 the first card is 5% rare core, 25% uncommon core, 70% potion (or gold). Shop: rare <= 20, uncommon <= 80 (10% / 30% / 60% on the first card).

| Source | What you get |
|---|---|
| Quartermaster (new run) | 3 cards, each a die (normal odds, coins swapped out) with a core fitted (uncommon or rare); take 1 |
| Normal fight | 1 die of 3. Items (take 2 of 3, the first pick burns one) only at `show_consumables_chance` (starts 30%, -30 when shown), always if you spared everyone or took the Dutchman |
| Elite | 1 die of 3, 1 rollable keepsake of 3, take 2 of 3 items (any) |
| Boss | 1 of 3 rare dice, 1 of 3 boss keepsakes, take 2 of 3 rare cores |
| Alignment encounter | 2 dice from the alignment list (Holy, Unholy) |
| Shop | 4 dice, 4 items, 3 shop keepsakes, 1 tool (if one is left) |
| Treasure | 1 rollable keepsake (a treasure stop is forced as the first stop of the page when `(pages_cleared + 4) mod 8 == 0`: after 4, 12, 20... pages) |
| Bounty board | A free common potion; contracts pay a rare core, a rollable keepsake and a die |
| Events | see below |

**Sea stops** (one after each drafted page, `passage_pool`, weights): Calm water 1-5 (more when hurt; the only heal), the Shipwright (workbench) 3 + 2 per core held (to +4), The wreck (a core) 2, Whetstone reef (+1 min roll on a die) 2, Flotsam (50 gold) 2, Squall (remove a die; needs 7+ dice) 1. The 3 offered pages get different stops, one of them is always Calm water or the Shipwright, and a core held for two spreads forces a Shipwright. You draft 2 of the 3 pages, so you sail 2 stops a spread. The boss spread has a harbour instead: rest (Calm water) or refit (workbench).

**Events that give content:** Pirate Prisoner (Deckhand's Token; or remove a die; or a random item), A Great Storm (+2 size to a random BLK/HEAL die; or Starver's Efficiency; or +1 play next fight), Clear skies (+2 size to 2 random ATK dice), Broken sails (Small Sail or Rope of Repair), A Hidden Trunk (random die / random core / random potion), Some old loot (rollable keepsake / rare core), Spare Ammunition (Roundshot +2 size, Chainshot +1 min, Grapeshot random core), A bird flies aboard (rollable keepsake, -7 alignment), The Wishing Well (random coin; or toss a coin for 10 luck), An island dream (remove a die; or a random rare die for 5 max health), The Flying Dutchman (items after every fight, no shops; or a luck roll for a keepsake), Rough tides (remove / transform / copy a die), A precious ingot (a tool, or the Toolbelt), The Siren's Call (+2 size to 1-3 ink dice or attack dice by alignment), The tattooist (+1 min for 40 gold). Event dice and the transform use normal fight odds; "random rare die" uses the rare pool.

**Typical run by the end of chapter 2** (an estimate from the map odds, not measured): a page has 1, 2 or 2 stops (`choose(1,2,2)`), a spread 2 pages, so about 3.3 stops and 2 sea stops a spread, about 13 stops a chapter plus harbour and boss. Over two chapters: about 26 stops, 2 bosses, 16 sea stops, 2 harbours. Stop odds start at 15% fight / 65% event / 20% shop, then 40/40/20 and drift; elites from stop 7; a fight is guaranteed on every draft and after 4 stops without one. So roughly 10-12 normal fights, 1-3 elites, 9-11 events, 4-5 shops, about 2 treasures, 2-3 visits to the workbench. That means about 13-17 new dice (one per fight won plus the quartermaster's) on a 10-die bag, 4-8 keepsakes (elites, 2 bosses, treasures, events, shops), but very few potions from normal fights (see Broken: the item chance doesn't recover at luck 50), and 3-6 cores (quartermaster, boss cores, wreck, shop). Whether `elite_nodes_this_voyage` resets each chapter I didn't confirm.

## 7. Intersections

### Who supports each mechanic

| Mechanic | Dice | Keepsakes | Cores / potions / other | Count |
|---|---|---|---|---|
| min-up | Last Stand, Ballast, Crescendo, Assassin, Holy | Polished Sextant, Shield Plating, Weapon Polish, Crossword Puzzle, Book of Secrets | Whetstone reef, Chainshot, tattooist | 13 |
| block | Anchor, Reed snap, Bolster, Tidecaller, Defensive coin, Deflect, and every BLK die (13 single-type) | Shield Plating, Lantern, Protective Rigging, Starver's Efficiency | Captain's Brew | 20+ |
| ink | Ink starters, Lookout, Radar, Guerrilla Coin, Inkwell, Deflect, Assassin, Ninja, Deepdiver | Looking Glass, Deep Lens, Book of Secrets, Eye patch | Crow's Nest Clarity, Siren's Call | 17 |
| min-roll triggers | Offhand, Warrior | Topographic Map, Navigation Chart, Balancing Compass, Rusty Rudder | Edge, Binary, ruthless Compass/Lodestone | 9 |
| max-roll / high-roll | Squall, Reed snap, Tidecaller, Tidepusher, Balanced, Warrior | Topographic Map, Balancing Compass | Weighted, Loaded, Edge, Binary | 12 |
| draw / plays | Invisible, Slipstream, Squall, Fogcaller, Deepdiver | Pickled Cucumber, Small Sail, Kraken's Grasp, Medallion, Shipwright's Draft, Topographic Map, Message in a Bottle | Bilge-Purge, Corsair's Gambit, Navigator's Brew, Mirage Brew | 16 |
| slot-pos | Surge, Kill coin, Muzzle, Inkwell | Deckhand's Token, Bandage, Single Focus, Cannon Splitter, Black Purse, Cursed Heart | (built-in place bonus) | 10 |
| build | Bolster, Harvest, Guerrilla Coin, Radar, Barrel | Lead Line, Shipwright's Draft, Cursed Heart | - | 8 |
| followthrough | Tidebreaker, Bulwark, Muzzle, Fogcaller, Ninja | Chainmaster's Anchor | - | 6 |
| coin | Power penny, Kill coin, Guerrilla Coin, Defensive coin, Fogcaller | Lucky Coin | Cutters (make coins), Wishing Well | 8 |
| aoe | Bulwark, Gunpowder, Bouncing, Guerrilla Coin | Cannon Splitter, Captain's Ledger, Rusty Rudder | Corsair's Gambit (scales) | 8 |
| unused / stowaway | Anchor, Slipstream, Lookout | Lantern of Patience, Windbound Charm | (6 dealt, 4 plays: 2 left over a turn) | 5 |
| played | Invisible, Fogcaller, Echo, Harvest | Protective Rigging, Eye patch, Windbound Charm, Lead Line, Topographic Map | - | 9 |
| stack | Power penny, Echo | Repeater Rail | Riggers Tonic | 4 |
| size | Bolster, Splash, Ballast, Crescendo, Bulwark ({min2}) | Polished Sextant (d4 only) | Hammer, Cutters, Artisan's Ember, Roundshot, Storm, Clear skies, Sirens | 13 |
| heal | Tidecaller, Tidepusher, Defensive coin, Bilge | Rope of Repair, Rations, Salted Pork, Lime Juice | Healing Flask | 9 |
| twice | Accurate | Starver's Efficiency, Navigation Chart | - | 3 |
| alignment | Holy, Unholy | Medallion of the Sea | Compass, Lodestone, Siren's Call | 6 |
| potion | Barrel | Rations, Water Barrel, Toolbelt | - | 4 |
| buff (Might/Balance) | Offhand, Balanced | - | Grog of Grit, Captain's Brew | 4 |
| gold | Harvest | Black Purse, Captain's Ledger | Flotsam | 4 |
| hp-cost | Blood Reef, Last Stand (rewards missing health) | Lime Juice | - | 3 |
| sticky | Sticky die, Bilge | - | - | 2 |
| favourite | Defensive coin | Friendship Bracelet | - | 2 |
| multitype | Defensive coin, Deflect, Assassin | - | - | 3 |
| exclusive | Tidepusher | - | - | 1 |
| parity | Bilge | - | (Odd/Even cores gone) | 1 |
| debuff | - | Bandage | - | 1 |

### Cross-links (which mechanics reference each other)

| | min-roll | max-roll | min-up | coin | ink | slot-pos | build | size | alignment |
|---|---|---|---|---|---|---|---|---|---|
| min-roll | - | Warrior, Balancing Compass, Topographic Map, Edge, Binary | conflict: raising min to max disables Topographic/Compass; Rusty Rudder and Nav Chart then fire every roll | Rusty Rudder, Topographic, Nav Chart, Compass (a coin rolls its min half the time) | ink rerolls re-fire all four "when rolled" keepsakes | - | - | Rusty Rudder deals the face, so small dice deal little | ruthless Compass/Lodestone |
| max-roll | | - | Ballast/min-up push faces up only via the floor | Lucky Coin (2s) feeds Topographic's max | - | - | - | Reed snap / Tidepusher are fixed numbers (4), worse after resizing | - |
| min-up | | | - | Shield Plating on Power penny makes it a flat 2 | Assassin, Book of Secrets | - | - | Polished Sextant is d4-only, so it stops when a die is upgraded | Holy |
| coin | | | | - | Guerrilla Coin | Kill coin, Fogcaller (slot before) | Guerrilla Coin, Cursed Heart (cheap pips) | Cutters make coins, Hammer unmakes them | - |
| ink | | | | | - | Ninja (slot before ink), Inkwell (types) | Radar, Guerrilla Coin | Siren's Call | Siren's Call (merciful) |
| slot-pos | | | | | | - | Cursed Heart, Shipwright's Draft, Sticky (keeps a built slot) | - | - |
| build | | | | | | | - | Bolster ({max2}) | - |

### Clusters (many supporters)

1. **Min-roll engine**: Warrior + Edge/Binary + Topographic Map, Navigation Chart, Balancing Compass, Rusty Rudder, with coins (half their rolls are minimums) and ink rerolls (each reroll fires "when rolled" again). The strongest-looking archetype; four rollable keepsakes feed it.
2. **Min-up / steady dice**: five "+1 min on X" keepsakes, three event/sea-stop min upgrades, Ballast, Last Stand, Crescendo, Assassin, Holy. Many supporters, but each is a flat stat bump, and it fights the min-roll engine.
3. **Plays and draw**: 16 sources, but nothing pays off "having played many dice" except Protective Rigging and Eye patch (per play) and Repeater Rail (per die in a slot).
4. **Ink**: plenty of ink in (Lookout, Radar, Looking Glass, Deep Lens, Eye patch, Crow's Nest) and three scalers (Guerrilla Coin, Assassin, Deepdiver), plus Book of Secrets.
5. **Block**: the biggest type (13 BLK dice, 15 with multitype) with Shield Plating, Lantern, Protective Rigging, Starver's Efficiency, Captain's Brew.

### Orphans (almost no support)

- **Heal**: only 3 HEAL dice (one rare, one rare multitype coin, one uncommon), none in the starting bag (the d4 Heal template is unused), and no "+1 min on Heal" keepsake (Attack, Block, Ink and generic each have one).
- **Sticky**: 2 dice, nothing rewards it. Its one real use is keeping a built slot (and its place bonus) into next turn.
- **Exclusive**: Tidepusher only.
- **Multitype**: 3 dice, no payoff.
- **Favourite**: Defensive coin and Friendship Bracelet only.
- **Parity**: Bilge alone since the Odd and Even cores became Compass and Lodestone.
- **Debuff**: Bandage reacts to being debuffed; no player content debuffs enemies at all.
- **Buff (Might/Balance)**: Offhand, Balanced and two potions; no keepsake.
- **Gold**: Harvest, Black Purse (broken, below), Captain's Ledger.
- **Thin bag**: Captain's Ledger and Scavenger's Tear want a small bag; removal comes from Squall, events and Scavenger's Tear, but every fight adds a die.
- **Alignment dice**: Holy and Unholy only drop from alignment encounters (alignment chance grows 4% a stop only after stop 7, once a voyage), so they're rarely seen.
- **Dual and Tower cores**: their shapes reward nothing in the game (no "second-highest" effects).

### Broken or out of date

1. **Black Purse pays 3 gold, not 3 per slot**: `combat_queue_reset_built` removes built slots in END_OF_ROUND before `win_fight` fires `on_combat_end`, so the queue has 1 slot (2 only if a Sticky die holds one).
2. **Normal-fight items stop after the first offer**: when items aren't shown, the chance grows by `20 * round((luck - 50) / 2)`, which is 0 at luck 50 (the comment says +10%). After the first offer (-30) the chance sits at 0 for the rest of the run unless luck changes; below 50 it shrinks.
3. **Crescendo** counts each use twice (`times_played_this_combat++` on play and again when it resolves), so it climbs 2 a turn, and it *sets* min_roll (`min(max/2, 1 + plays)`), which wipes a Whetstone, Chainshot or tattoo +1 on that die. Its text says "each time it rolls".
4. **Chainmaster's Anchor can't double Bulwark** (Bulwark's damage is in `after_roll_die`, not added to `_d_amount`) or Fogcaller's draw; it only doubles the +N of Tidebreaker, Muzzle, Fogcaller and Ninja.
5. **Lead Line only helps Invisible and Harvest**: Echo's copy is a flag nothing reads on a build, and Fogcaller's draw returns early (`_slot_num` is -1 on a build).
6. **Artisan's Ember Draught** grows a die that has already rolled: the face is kept, so it does nothing this turn, only when that die is dealt again in the fight.
7. **Rusty Rudder and Navigation Chart lack the `min_roll < max_roll` guard** that Topographic Map and Balancing Compass have: a die whose min equals its max (Balancing Compass's forced die, Last Stand at low health, Power penny with Shield Plating) fires them on every roll. Rudder + Compass hits for the forced die's max.
8. **Lodestone's text overstates it**: no die has an exact middle face (all sizes are even), so fully ruthless it still rolls middle faces (d4 20,7,7,20; d6 20,12,4,4,12,20). "Only its lowest or highest" isn't true at any size above a coin.
9. **Bell and Dome use absolute face numbers** (`power(2, d - 1)`, `power(3, d - 2)`), so on a die with a raised minimum the shape tips low (Bell on Ballast's 4-8: 8,8,4,2,1).
10. **Type-based roll keepsakes read the die's own type as it's dealt**: a generic or multitype die played into an ATK slot rolled without Rum or Weapon Polish. At resolve the face is clamped to the slot's range, so a min raise still lifts a low face, but Rum's +1 max can never be reached by those dice.
11. **Tidepusher checks exactly 4** and **Reed snap 4+**: fine on a d4, but after a resize (Roundshot, Hammer, Sirens) Tidepusher's 5 and 6 don't count.
12. **Polished Sextant checks `max_roll == 4` after other keepsakes**: with Rum, an Attack d4's max is 5 and the Sextant may stop applying (depends on keepsake bar order).
13. **Inkwell Die** counts every slot's `current_action_type`, so an empty or generic slot ("None") counts as a type (`slot` is also assigned without `var`). Not checked in game.
14. **Barrel Die** loses its potion silently when item slots are full (`gain_item` does nothing).
15. **Bouncing Die** changes `oCombat.enemy_target_index` for good, so the dice after it hit the new target too.
16. **Names**: the sea stop "Squall" (remove a die) shares a name with the Squall die; the potion is named "Riggers Tonic" but its slot bonus says "Rigger's Tonic"; Medallion of the Sea has the id `medallion_of_the_deep`; Cursed Heart is pure upside now (was +3 pips). Holy's "Alignment:" reads like a keyword but isn't one, and both alignment dice are priced 30 although rare.
17. **Fire-on-deal effects** (Rusty Rudder, Topographic's draw, Nav Chart, Compass, Squall, Offhand, Balanced, Warrior) fire for dice you never play and again on every ink reroll. Probably intended by F128, but it makes ink rerolls an engine for the min-roll cluster.
