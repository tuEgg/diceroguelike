# Buffs and debuffs: the agreed rules and the plan

2026-11-24. Jared's answers to the questions, then what gets built. (Background: KANBAN T02; most of the old bugs B21 to B30 are fixed, see DONE.)

## The rules

**Two kinds of buff, shown two ways.**

1. **Amount buffs** (Might, Balance, queued ink, Spines, Shiny Scales if it grows): they have a number and no turn counter.
   - A **permanent** copy is one icon. More of it adds to its amount for the rest of the fight (the Pirate Captain's Command: Might +1, +2...).
   - A **temporary** copy is its own, separate icon. It lasts **one turn only**, and more of it adds to that icon's amount.
   - Both icons show their own amount, and the tooltip names the total ("Might 5: 3 permanent, 2 this turn").
   - No "turns left" on these, ever.
2. **Fixed-effect buffs and debuffs** (Bind, Rot, Mock, Barnacle Bind, Stunned, Reserve, the shells): no amount, and **a turn counter** when they end. They are the only ones with counters.

**Timing.** A debuff an enemy puts on you during its move is active for your whole next turn and gone when that turn ends; duration N adds N-1 more turns. (As now.)

**On screen.** An icon shows its amount (amount buffs) or the turns left (fixed-effect ones, and nothing for permanent ones). Enemies' buffs and debuffs are shown too, over their health bars, with the same numbers, and their expiry is in the hover.

**Words.** Every buff and debuff is explained the same way wherever its name appears (the glossary box), with its current amount or turns.

## To confirm

- **Re-applying a fixed-effect debuff (Bind on a Bind).** Recommended: it refreshes to the longer of the two (no stacking turns). Now it adds the durations. Say if you want adding.
- **The specific bugs you've seen** (the scope answer said "specific bugs" but the list wasn't in it). Anything you remember goes here: what happened, which buff, what you expected.

## The build (in this order)

1. **One buff model** (T02) in `apply_buff` / `trigger_debuff_list` (scDebuffs, scCombatScripts): each template declares `kind: "amount"` or `"effect"`. Amount buffs merge into at most two instances per target (permanent, temporary); temporary always has duration 1 and expires at the end of the turn it was applied (enemy-applied: through your next turn, as now); effect buffs merge by id with the rule above. Each buff ticks once per event, outside the per-effect loop. No flag writing on shared templates.
2. **Move the existing templates onto it**, checking each: Might, Balance, queued ink (and the two-turn "lasting" one stays its own fixed-effect), Spines, Shiny Scales, Reserve, Bind, Rot, Mock, Barnacle Bind, Stunned, the Turtle's and Conch's shells and Heartache (permanent passives, shown without counters; the Conch shows its layers).
3. **Icons**: a number on the icon (amount or turns), permanent and temporary Might as two icons, for you and for enemies, where the buff bar draws now (oRunManager Draw GUI for you, oCombat Draw GUI for enemies).
4. **Tooltips**: the glossary box shows the current amount or turns, and the total for amount buffs.
5. **Tests to write down for you** (KANBAN): Pirate Captain stacking Might on two enemies and himself; Might from a Grit die plus War Drum together; Bind then Bind again; Rot for a turn; Mock; the Conch's shell through three layers; a save and Continue mid-fight (buffs aren't saved: they restart with the fight's seed).

Estimated: one session for steps 1 and 2, one for 3 and 4.
