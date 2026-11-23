// Tides of Fortune: combat output simulation for the Hammer / big-dice / cores review.
// Run: node docs/design/sim/sim.js            (all tables, markdown, to stdout)
//      node docs/design/sim/sim.js 20000      (more fights per scenario; default 5000)
//      node docs/design/sim/sim.js 5000 ink   (the ink run: ink dice played, ink spent on rerolls and redraws)
//
// Rules modelled, checked against the code on dev (2026-11-23):
// - 6 dice dealt a turn (global.hand_size, oRunManager Create), each rolled as it's dealt (die_roll_faces) using the
//   core's weights (define_dice_distributions) and keeping that face.
// - 4 plays a turn (dice_allowed_per_turn_original). Coins (d2) don't use a play (slot_placement_check, sacrifice_die).
// - The bag is drawn at random (deal_single_die: irandom over the bag). When it's empty mid-deal, the discard pile is
//   shuffled back in. Every die, played or not, goes to the discard pile at End Turn. Each fight starts with the full bag.
// - Every turn starts with one slot. Building slot N (N >= 2) needs dice on the tile adding up to 2 x (N-1) pips
//   (new_slot_threshold), with a coloured die among them (new_slot_has_coloured); every slot needs an action first.
//   The builders go into the new slot and count this turn (combat_try_build_slot). Slot N gets +(N-1) once, on its
//   first die (slot_set_position_bonus, scope "first").
// - A coloured die starts a slot (claim) or joins one of its type; generic dice join any typed slot but can't start
//   one, and can only help build once a coloured die is on the tile (slot_placement_check, die_cant_build_slot_reason).
// - Ink dice give ink, not attack or block. This sim never plays them (ink spending is ignored), so they are dead draws.
// - Enemies are ignored except a fixed incoming hit of D per turn. "Effective" = attack + min(block, D).
//
// Play policy (a simple, greedy captain):
// 1. Squall rolling 5+ draws a die; Invisible is always played when a coloured die can anchor it (+1 play, draw 1).
// 2. Anchor is never played (its Stowaway 5 block is worth more than its face). Ink dice are never played.
// 3. Pick up to 4 non-coin dice one at a time, each time the one adding the most to attack + min(block, D)
//    (a generic counts as whichever is worth more), ties to the bigger face; at least one coloured die. All usable
//    coins are played too (they're free).
// 4. Lay them out: slot 1 gets the smallest coloured die. Then build slot 2, 3, 4... each time from the smallest group
//    of remaining dice (one colour plus generics) that reaches the threshold, so the biggest dice end up in the latest
//    slots. Leftover dice join a slot of their colour; leftover generics top block up to D, then go to attack.
//    Tried twice (preferring attack or block where groups tie) and the better layout kept.
// Ink run (`ink` argument): ink dice play and start INTEL slots (generics may join); a slot's total arrives as ink next
// turn (buff_intel), capped at 12 at the turn's start (INSIGHT_MAX, intel_max), starting each fight at 0. Before playing,
// 3 ink rerolls or redraws the worst die below the hand's median when that gains at least 0.3 pips (a benched die only
// gains by beating the last die that would be played). Ink is worth lam per pip when choosing plays; each bag keeps the
// lam in LAMS that gives the most output, so ink is valued only by what it buys. Plays can't be bought with ink (the
// buy-play pips are switched off in combat_turn_tokens_draw), and reveal/rewrite/move are ignored.
// Effects modelled for the common reward dice: Accurate, Warrior, Splash, Reed snap, Anchor, Tidebreaker, Bolster,
// Invisible, Squall, Power penny, Slipstream. Every other common is plain (its size and type).

'use strict';

const FIGHTS = parseInt(process.argv[2] || '5000', 10);
const TURNS = 6;
const HAND = 6;
const PLAYS = 4;
const D_DEFAULT = 6;

// ---------------------------------------------------------------- rng (seeded, so runs repeat)
let _seed = 12345;
function rand() { // mulberry32
	_seed |= 0; _seed = (_seed + 0x6D2B79F5) | 0;
	let t = Math.imul(_seed ^ (_seed >>> 15), 1 | _seed);
	t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
	return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
function irandom(n) { return Math.floor(rand() * (n + 1)); } // 0..n like GML irandom

// ---------------------------------------------------------------- cores (define_dice_distributions)
// GML round(): assumed round-half-to-even; only matters for Compass on a d10 at alignment 0 / 100
function gmlRound(x) {
	const f = Math.floor(x), d = x - f;
	if (Math.abs(d - 0.5) < 1e-9) return (f % 2 === 0) ? f : f + 1;
	return Math.round(x);
}
let ALIGNMENT = 50;
function weights(core, min, max) {
	const a = [];
	for (let d = min; d <= max; d++) {
		let w = 1;
		switch (core) {
			case '': w = 1; break;
			case 'weighted': w = max - 2 + d; break;
			case 'loaded': w = d; break;
			case 'edge': w = (d === min || d === max) ? 7 : 2; break;
			case 'binary': w = (d === min || d === max) ? 1 : 0; break;
			case 'bell': w = (d <= max / 2) ? Math.pow(2, d - 1) : Math.pow(2, max - d); break;
			case 'dome': w = (d === min || d === max) ? 0 : ((d <= max / 2) ? Math.pow(3, d - 2) : Math.pow(3, max - d - 1)); break;
			case 'dual': w = (d === min + 1 || d === max - 1) ? 3 : 1; break;
			case 'tower': w = (d === min + 1 || d === max - 1) ? 1 : 0; break;
			case 'compass': case 'lodestone': {
				const lean = Math.max(-1, Math.min(1, (ALIGNMENT - 50) / 50));
				const s = (core === 'lodestone') ? 1 : 0.65;
				const p = (max > min) ? (d - min) / (max - min) : 0.5;
				const mid = 1 - Math.abs(2 * p - 1);
				w = Math.max(0, gmlRound(10 + 10 * s * lean * (2 * mid - 1)));
				break;
			}
		}
		a.push(w);
	}
	return a;
}
const CORES = ['', 'weighted', 'loaded', 'edge', 'binary', 'bell', 'dome', 'compass', 'lodestone', 'dual', 'tower'];
const CORE_NAME = { '': 'No core', weighted: 'Weighted', loaded: 'Loaded', edge: 'Edge', binary: 'Binary', bell: 'Bell',
	dome: 'Dome', compass: 'Compass', lodestone: 'Lodestone', dual: 'Dual', tower: 'Tower' };

// cumulative weight tables cached per (core, size, alignment)
const _cdf = new Map();
function cdf(core, size) {
	const key = core + '|' + size + '|' + ALIGNMENT;
	let c = _cdf.get(key);
	if (!c) {
		const w = weights(core, 1, size);
		let tot = w.reduce((s, x) => s + x, 0);
		const ww = (tot > 0) ? w : w.map(() => 1);
		tot = ww.reduce((s, x) => s + x, 0);
		c = { w: ww, tot };
		_cdf.set(key, c);
	}
	return c;
}
function rollFace(core, size) { // die_roll_faces: irandom_range(1, weight) walked through the weights
	const c = cdf(core, size);
	let r = 1 + irandom(c.tot - 1);
	for (let i = 0; i < c.w.length; i++) { r -= c.w[i]; if (r <= 0) return i + 1; }
	return size;
}

// ---------------------------------------------------------------- dice
// type: ATK BLK INK GEN; size; core; eff (effect id or '')
function die(type, size, core = '', eff = '') { return { type, size, core, eff }; }
const isCoin = (d) => d.size === 2;
const coloured = (d) => d.type !== 'GEN';
const usable = (d) => d.type !== 'INK' && d.eff !== 'anchor';

function startBag() {
	const b = [];
	for (let i = 0; i < 3; i++) b.push(die('ATK', 4));
	for (let i = 0; i < 3; i++) b.push(die('BLK', 4));
	for (let i = 0; i < 2; i++) b.push(die('INK', 4));
	for (let i = 0; i < 2; i++) b.push(die('GEN', 4));
	return b;
}

// the 21 common pooled dice (content catalogue section 1), as type/size/effect
const COMMONS = [
	die('BLK', 6, '', 'anchor'), die('ATK', 4, '', 'slipstream'), die('ATK', 6, '', 'tidebreaker'),
	die('BLK', 2, '', 'penny'), die('GEN', 4, '', 'invisible'), die('GEN', 6, '', 'squall'),
	die('BLK', 4, '', 'reedsnap'), die('BLK', 4), /* Fogcaller */ die('BLK', 4, '', 'bolster'),
	die('ATK', 4, '', 'accurate'), die('BLK', 6), /* Harvest */ die('INK', 6), /* Lookout */
	die('ATK', 4), /* Bouncing */ die('INK', 2), /* Guerrilla coin */ die('INK', 6), /* Radar */
	die('ATK', 6), /* Offhand */ die('BLK', 6), /* Balanced */ die('BLK', 4), /* Ninja */
	die('ATK', 4, '', 'warrior'), die('BLK', 10, '', 'splash'), die('ATK', 4), /* Gunpowder */
];

// rolled as it's dealt: its own range, core, roll-twice, Warrior
function roll(d) {
	let f = rollFace(d.core, d.size);
	if (d.eff === 'accurate') f = Math.max(f, rollFace(d.core, d.size));
	if (d.eff === 'warrior' && f <= 1) f = d.size;
	return f;
}
// what it adds in a slot (or on the tile): Splash's -2, never below 0
function worth(h) { return (h.d.eff === 'splash') ? Math.max(0, h.f - 2) : h.f; }

// ---------------------------------------------------------------- one fight
function runFight(bagDef, opt, acc) {
	const D = opt.D;
	let bag = bagDef.map((d) => d);
	let discard = [];
	let bonusPlays = 0;
	const INK = !!opt.ink; // ink modelled: ink dice play, ink slots pay next turn, ink buys rerolls and redraws
	const ok = (d) => d.eff !== 'anchor' && (INK || d.type !== 'INK');
	let ink = 0, inkNext = 0;
	for (let t = 0; t < TURNS; t++) {
		const hand = [];
		if (INK) { // START_TURN: last turn's ink arrives, capped at INSIGHT_MAX (12)
			const raw = ink + inkNext + (opt.freeInk || 0); // freeInk: a test gift, to price a point of ink
			ink = Math.min(INK_MAX, raw);
			acc.inkCapped += raw - ink;
			inkNext = 0;
		}
		const deal = (n) => {
			for (let i = 0; i < n; i++) {
				if (bag.length === 0) {
					if (discard.length === 0) return;
					bag = discard; discard = [];
				}
				const k = irandom(bag.length - 1);
				const d = bag[k];
				bag.splice(k, 1);
				const h = { d, f: roll(d), played: false, free: false };
				hand.push(h);
				if (opt.heavy && d.size > opt.heavy) i++; // lever E: a big die takes two spots in the hand
				if (d.eff === 'squall' && h.f >= 5) n++; // rolls 5+: draw a die
			}
		};
		deal(opt.hand || HAND);
		let plays = (opt.plays || PLAYS) + bonusPlays;
		if (INK) {
			const spent = spendInk(hand, ink, plays, bag, discard, deal, ok, opt);
			ink -= spent.ink; acc.inkSpent += spent.ink; acc.rerolls += spent.rerolls; acc.redraws += spent.redraws;
		}
		bonusPlays = 0;

		// Invisible: played for free when something coloured can anchor it (+1 play, draw 1)
		let guard = 0;
		while (guard++ < 10) {
			const inv = hand.find((h) => h.d.eff === 'invisible' && !h.free);
			if (!inv || !hand.some((h) => coloured(h.d) && usable(h.d))) break;
			inv.free = true;
			deal(1);
		}

		// choose plays
		const coins = hand.filter((h) => isCoin(h.d) && ok(h.d) && !h.free);
		const cands = hand.filter((h) => !isCoin(h.d) && ok(h.d) && !h.free);
		const lam = opt.lam || 0, room = Math.max(0, INK_MAX - ink);
		let inkG = 0;
		const chosen = [];
		let atk = 0, blk = 0;
		for (const c of coins) { if (c.d.type === 'ATK') atk += c.f; else if (c.d.type === 'BLK') blk += c.f; }
		const gain = (h) => {
			const v = worth(h);
			const a = v, b = Math.min(v, Math.max(0, D - blk));
			if (h.d.type === 'INK') return lam * Math.min(v, Math.max(0, room - inkG));
			if (h.d.type === 'ATK') return a;
			if (h.d.type === 'BLK') return b;
			return Math.max(a, b);
		};
		const cost = (h) => (opt.bigCost && h.d.size > 8) ? 2 : 1; // lever C: a die over d8 uses two plays
		let used = 0;
		while (used < plays && cands.length > 0) {
			let bi = -1, bg = -1;
			for (let i = 0; i < cands.length; i++) {
				if (used + cost(cands[i]) > plays) continue;
				const g = gain(cands[i]);
				if (bi < 0 || g > bg || (g === bg && worth(cands[i]) > worth(cands[bi]))) { bg = g; bi = i; }
			}
			if (bi < 0) break;
			const h = cands.splice(bi, 1)[0];
			used += cost(h);
			if (h.d.type === 'ATK') atk += worth(h);
			else if (h.d.type === 'BLK') blk += worth(h);
			else if (h.d.type === 'INK') inkG += worth(h);
			else if (gain(h) === worth(h) && D - blk <= 0) atk += worth(h); else blk += worth(h);
			chosen.push(h);
		}
		// at least one coloured die (or coloured coin) to start slot 1
		if (!chosen.some((h) => coloured(h.d)) && !coins.some((h) => coloured(h.d))) {
			const col = cands.filter((h) => coloured(h.d)).sort((x, y) => worth(y) - worth(x))[0];
			if (col && chosen.length > 0) { chosen[chosen.length - 1] = col; }
			else if (col) chosen.push(col);
		}
		const toPlay = chosen.concat(coins).concat(hand.filter((h) => h.free));

		let r = null;
		for (const pref of (INK ? ['ATK', 'BLK', 'INK'] : ['ATK', 'BLK'])) {
			const x = layout(toPlay, D, pref, lam, room);
			if (!r || x.score > r.score) r = x;
		}
		if (INK) { inkNext = r.ink; acc.inkGain += r.ink; }
		for (const h of r.placed) h.played = true;

		// effects outside the slot totals
		let extraBlk = 0;
		for (const h of hand) {
			if (h.d.eff === 'anchor' && !h.played) extraBlk += 5; // Stowaway
			if (h.d.eff === 'slipstream' && !h.played) bonusPlays += 1; // Stowaway: +1 play next turn
			if (h.d.eff === 'reedsnap' && h.played && h.f >= 4) extraBlk += 2;
		}
		const A = r.atk, B = r.blk + extraBlk;
		acc.atk += A; acc.blk += B; acc.eff += A + Math.min(B, D); acc.slots += r.slots; acc.n++;
		acc.eff2 += Math.pow(A + Math.min(B, D), 2);
		acc.turn[t] += A + Math.min(B, D);
		acc.played += r.placed.filter((h) => !isCoin(h.d)).length;
		acc.waste += hand.filter((h) => h.d.type === 'INK').length;
		acc.inkHeld += ink; // unspent at End Turn (carried)
		for (const h of hand) discard.push(h.d);
	}
	acc.inkEnd += Math.min(INK_MAX, ink + inkNext); // ink left when the fight ends
}

// expected value of max(0, X - c) for a die's face X (its core's weights)
function dieMean(d) { const c = cdf(d.core, d.size); let m = 0; for (let i = 0; i < c.w.length; i++) m += c.w[i] * (i + 1); return m / c.tot; }
function overMean(d, c0) { const c = cdf(d.core, d.size); let m = 0; for (let i = 0; i < c.w.length; i++) m += c.w[i] * Math.max(0, i + 1 - c0); return m / c.tot; }

// ink spent before playing: 3 for a reroll (the die rolls again) or a redraw (discarded, a new one dealt).
// The worst die below the hand's median gets whichever is worth more, while that is worth at least MIN_GAIN pips. A die that
// won't be played anyway (more usable dice than plays) only gains by beating the last die that would be.
const INK_MAX = 12, INK_COST = 3, MIN_GAIN = 0.3;
function spendInk(hand, ink, plays, bag, discard, deal, ok, opt) {
	const out = { ink: 0, rerolls: 0, redraws: 0 };
	for (let guard = 0; guard < 12 && ink - out.ink >= INK_COST; guard++) {
		const use = hand.filter((h) => ok(h.d) && !h.free).sort((x, y) => worth(x) - worth(y));
		if (use.length === 0) break;
		const vals = use.map(worth);
		const median = (vals[(vals.length - 1) >> 1] + vals[vals.length >> 1]) / 2;
		const h = use[0];
		const v = worth(h);
		if (v >= median && use.length > 1) break;
		const nonCoin = use.filter((x) => !isCoin(x.d));
		// the bar a new face has to clear: its own value if it'd be played, else the weakest die that would be
		const benched = !isCoin(h.d) && nonCoin.length > plays;
		const bar = benched ? worth(nonCoin[nonCoin.length - plays]) : v;
		const rerollGain = benched ? overMean(h.d, bar) : dieMean(h.d) - v;
		const pool = bag.length ? bag : discard.concat([h.d]);
		let redrawGain = 0;
		for (const d of pool) redrawGain += overMean(d, bar) - (benched ? 0 : 0);
		redrawGain = pool.length ? redrawGain / pool.length - (benched ? 0 : 0) : 0;
		if (!benched) redrawGain = (pool.length ? pool.reduce((a, d) => a + dieMean(d), 0) / pool.length : 0) - v;
		if (Math.max(rerollGain, redrawGain) < MIN_GAIN) break;
		out.ink += INK_COST;
		if (rerollGain >= redrawGain) { h.f = roll(h.d); out.rerolls++; }
		else { hand.splice(hand.indexOf(h), 1); discard.push(h.d); deal(1); out.redraws++; }
	}
	return out;
}

// lay the chosen dice out in slots; pref breaks ties between attack and block groups
function layout(dice, D, pref, lam = 0, room = 0) {
	let rem = dice.slice();
	const slots = []; // { type, dice: [h], builders: [h] }
	// slot 1: the smallest coloured die
	let first = null;
	for (const h of rem) {
		if (!coloured(h.d)) continue;
		if (!first || worth(h) < worth(first) || (worth(h) === worth(first) && h.d.type === pref && first.d.type !== pref)) first = h;
	}
	if (!first) return { atk: 0, blk: 0, ink: 0, score: 0, slots: 0, placed: [] };
	slots.push({ type: first.d.type, dice: [first], builders: [] });
	rem = rem.filter((h) => h !== first);
	// build slots 2, 3, 4...: smallest group of one colour (plus generics) reaching 2 x index
	for (let k = 1; k < 12; k++) {
		const need = 2 * k;
		const n = rem.length;
		if (n === 0) break;
		let best = 0, bestSum = Infinity, bestCnt = 99, bestType = '';
		for (let m = 1; m < (1 << n); m++) {
			let s = 0, cnt = 0, ty = '', ok = true;
			for (let i = 0; i < n; i++) {
				if (!(m & (1 << i))) continue;
				const h = rem[i];
				s += worth(h); cnt++;
				if (coloured(h.d)) { if (ty === '') ty = h.d.type; else if (ty !== h.d.type) { ok = false; break; } }
			}
			if (!ok || ty === '' || s < need) continue;
			if (s < bestSum || (s === bestSum && (cnt < bestCnt || (cnt === bestCnt && ty === pref && bestType !== pref)))) {
				best = m; bestSum = s; bestCnt = cnt; bestType = ty;
			}
		}
		if (!best) break;
		const g = rem.filter((h, i) => best & (1 << i));
		slots.push({ type: bestType, dice: g.slice(), builders: g.slice() });
		rem = rem.filter((h, i) => !(best & (1 << i)));
	}
	// leftovers: coloured dice join a slot of their colour, generics top block up to D then attack
	const sumType = (ty) => slots.filter((s) => s.type === ty).reduce((a, s) => a + s.dice.reduce((b, h) => b + worth(h), 0) + slots.indexOf(s), 0);
	for (const h of rem.filter((x) => coloured(x.d))) {
		const s = slots.slice().reverse().find((x) => x.type === h.d.type);
		if (s) s.dice.push(h);
	}
	for (const h of rem.filter((x) => !coloured(x.d)).sort((x, y) => worth(y) - worth(x))) {
		const blkS = slots.slice().reverse().find((x) => x.type === 'BLK');
		const atkS = slots.slice().reverse().find((x) => x.type === 'ATK');
		if (blkS && sumType('BLK') < D) blkS.dice.push(h);
		else if (atkS) atkS.dice.push(h);
		else slots[slots.length - 1].dice.push(h);
	}
	let atk = 0, blk = 0, ink = 0;
	const placed = [];
	slots.forEach((s, i) => {
		let tot = i; // place bonus
		for (const h of s.dice) {
			tot += worth(h);
			placed.push(h);
			if (h.d.eff === 'penny') tot += s.dice.length; // +1 per die in its slot
			if (h.d.eff === 'tidebreaker' && i > 0 && slots[i - 1].type === 'BLK') tot += 2;
		}
		if (s.type === 'ATK') atk += tot; else if (s.type === 'BLK') blk += tot; else if (s.type === 'INK') ink += tot;
		for (const h of s.builders) if (h.d.eff === 'bolster') blk += 2 * h.d.size; // builds a slot: 2 x size block
	});
	return { atk, blk, ink, score: atk + Math.min(blk, D) + lam * Math.min(ink, room) + 0.01 * (atk + blk), slots: slots.length, placed };
}

function simulate(name, bagFn, opt = {}) {
	const o = Object.assign({ D: D_DEFAULT }, opt);
	const acc = { atk: 0, blk: 0, eff: 0, eff2: 0, slots: 0, n: 0, played: 0, waste: 0, turn: new Array(TURNS).fill(0),
		inkGain: 0, inkSpent: 0, inkHeld: 0, inkCapped: 0, inkEnd: 0, rerolls: 0, redraws: 0 };
	_seed = 987654321; // same seed per scenario, so differences are the bag, not luck
	for (let f = 0; f < FIGHTS; f++) runFight(bagFn(), o, acc);
	const n = acc.n;
	const mean = acc.eff / n;
	return {
		name, dice: bagFn().length, atk: acc.atk / n, blk: acc.blk / n, total: (acc.atk + acc.blk) / n, eff: mean,
		sd: Math.sqrt(acc.eff2 / n - mean * mean), slots: acc.slots / n, played: acc.played / n,
		turn1: acc.turn[0] / FIGHTS, later: acc.turn.slice(1).reduce((a, b) => a + b, 0) / (FIGHTS * (TURNS - 1)),
		inkGain: acc.inkGain / n, inkSpent: acc.inkSpent / n, inkHeld: acc.inkHeld / n, inkCapped: acc.inkCapped / n,
		inkEnd: acc.inkEnd / FIGHTS, rerolls: acc.rerolls / n, redraws: acc.redraws / n,
		pips: Math.round(Array.from({ length: 200 }, () => bagFn().reduce((a, d) => a + d.size, 0)).reduce((a, b) => a + b, 0) / 200), // averaged: the random-commons bag varies
	};
}

// ---------------------------------------------------------------- bag builders
const B = (spec) => () => spec.map(([t, s, e]) => die(t, s, '', e || ''));
const rep = (n, x) => Array.from({ length: n }, () => x);

const BAGS = {
	start: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	// 2: rewards
	plain3: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4]), ['ATK', 6], ['BLK', 6], ['GEN', 6]]),
	common3: () => { const b = startBag(); for (let i = 0; i < 3; i++) { const c = COMMONS[irandom(COMMONS.length - 1)]; b.push(die(c.type, c.size, '', c.eff)); } return b; },
	// 3: hammer (d4 + d4 -> d8 once a visit)
	h2: B([['ATK', 8], ['ATK', 4], ['BLK', 8], ['BLK', 4], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	h4: B([['ATK', 8], ['ATK', 4], ['BLK', 8], ['BLK', 4], ['INK', 8], ['GEN', 8]]),
	h4big: B([['ATK', 12], ['BLK', 12], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	h6: B([['ATK', 12], ['BLK', 12], ['INK', 8], ['GEN', 8]]),
	// with 3 plain d6 rewards: d4 + d6 -> d10
	r3h3: B([['ATK', 10], ...rep(2, ['ATK', 4]), ['BLK', 10], ...rep(2, ['BLK', 4]), ...rep(2, ['INK', 4]), ['GEN', 10], ['GEN', 4]]),
	r3h6: B([['ATK', 10], ['ATK', 8], ['BLK', 10], ['BLK', 8], ['INK', 8], ['GEN', 10], ['GEN', 4]]),
	// 4: same dice count per type, no die above d6, pips as close as d6 allows
	c2: B([['ATK', 6], ['ATK', 6], ['BLK', 6], ['BLK', 6], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	c4: B([['ATK', 6], ['ATK', 6], ['BLK', 6], ['BLK', 6], ['INK', 6], ['GEN', 6]]),
	c4big: B([['ATK', 6], ['BLK', 6], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	c6: B([['ATK', 6], ['BLK', 6], ['INK', 6], ['GEN', 6]]),
	cr3h3: B([['ATK', 6], ['ATK', 4], ['ATK', 4], ['BLK', 6], ['BLK', 4], ['BLK', 4], ...rep(2, ['INK', 4]), ['GEN', 6], ['GEN', 6]]),
	cr3h6: B([['ATK', 6], ['ATK', 6], ['BLK', 6], ['BLK', 6], ['INK', 6], ['GEN', 6], ['GEN', 6]]),
	// 4b: thin only (the absorbed dice thrown overboard instead of merged)
	t2: B([...rep(2, ['ATK', 4]), ...rep(2, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	t4: B([...rep(2, ['ATK', 4]), ...rep(2, ['BLK', 4]), ['INK', 4], ['GEN', 4]]),
	t6: B([['ATK', 4], ['BLK', 4], ['INK', 4], ['GEN', 4]]),
	// d12 vs two d6s (on top of the starting bag)
	plusD12: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4]), ['ATK', 12]]),
	plus2D6: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4]), ['ATK', 6], ['ATK', 6]]),
	plusD6: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4]), ['ATK', 6]]),
	// d10 from hammering a reward d6 into a starter d4, vs keeping both
	d10merged: B([['ATK', 10], ...rep(2, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	d10kept: B([['ATK', 6], ...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	// 5: cutters (a die loses 2 sides, a plain coin of its type hops out)
	cutA: B([...rep(2, ['ATK', 4]), ['ATK', 2], ['ATK', 2], ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	cutAB: B([...rep(2, ['ATK', 4]), ['ATK', 2], ['ATK', 2], ...rep(2, ['BLK', 4]), ['BLK', 2], ['BLK', 2], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	cutG: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ['GEN', 4], ['GEN', 2], ['GEN', 2]]),
	cutI: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ['INK', 4], ['INK', 2], ['INK', 2], ...rep(2, ['GEN', 4])]),
	cut6: B([...rep(6, ['ATK', 2]), ...rep(6, ['BLK', 2]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	cutD6: B([...rep(3, ['ATK', 4]), ['ATK', 4], ['ATK', 2], ...rep(3, ['BLK', 4]), ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	cutD12: B([['ATK', 10], ['ATK', 2], ['BLK', 12], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	h3: B([['ATK', 8], ['ATK', 4], ['BLK', 8], ['BLK', 4], ...rep(2, ['INK', 4]), ['GEN', 8]]),
	// dead-dice controls: the ink dice taken out
	minusInk1: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ['INK', 4], ...rep(2, ['GEN', 4])]),
	minusInk2: B([...rep(3, ['ATK', 4]), ...rep(3, ['BLK', 4]), ...rep(2, ['GEN', 4])]),
	// lever D: a merge loses 2 sides (d4 + d4 = d6, d6 + d4 = d8)
	dH2: B([['ATK', 6], ['ATK', 4], ['BLK', 6], ['BLK', 4], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	dH3: B([['ATK', 6], ['ATK', 4], ['BLK', 6], ['BLK', 4], ...rep(2, ['INK', 4]), ['GEN', 6]]),
	dH4: B([['ATK', 6], ['ATK', 4], ['BLK', 6], ['BLK', 4], ['INK', 6], ['GEN', 6]]),
	dH4big: B([['ATK', 8], ['BLK', 8], ...rep(2, ['INK', 4]), ...rep(2, ['GEN', 4])]),
	dH6: B([['ATK', 8], ['BLK', 8], ['INK', 6], ['GEN', 6]]),
};

// ---------------------------------------------------------------- core stats (exact, from the weights)
function coreStats(core, size, extra = {}) {
	const c = cdf(core, size);
	let m = 0, m2 = 0;
	for (let i = 0; i < c.w.length; i++) { const p = c.w[i] / c.tot, f = i + 1; m += p * f; m2 += p * f * f; }
	const pMin = c.w[0] / c.tot, pMax = c.w[c.w.length - 1] / c.tot;
	// Warrior: rolls of its min become its max
	const warrior = m + pMin * (size - 1);
	return { mean: m, sd: Math.sqrt(m2 - m * m), pMin, pMax, warrior, w: c.w };
}

// ---------------------------------------------------------------- output
const f2 = (x) => x.toFixed(2), f1 = (x) => x.toFixed(1), pc = (x) => (100 * x).toFixed(0) + '%';
function table(rows, base) {
	const out = ['| Bag | Dice | Pips | Attack | Block | Total | Effective | vs start | SD | Slots | Dice played | Turn 1 | Turns 2-6 |',
		'|---|---|---|---|---|---|---|---|---|---|---|---|---|'];
	for (const r of rows) {
		const vs = base ? ((r.eff / base.eff - 1) * 100) : 0;
		out.push(`| ${r.name} | ${r.dice} | ${r.pips} | ${f2(r.atk)} | ${f2(r.blk)} | ${f2(r.total)} | ${f2(r.eff)} | ${(vs >= 0 ? '+' : '') + vs.toFixed(0)}% | ${f2(r.sd)} | ${f2(r.slots)} | ${f2(r.played)} | ${f2(r.turn1)} | ${f2(r.later)} |`);
	}
	return out.join('\n');
}

function main() {
	const lines = [];
	const P = (s) => lines.push(s);
	const S = (name, key, opt) => simulate(name, BAGS[key], opt);
	P(`Fights per scenario: ${FIGHTS}, ${TURNS} turns each, hand ${HAND}, ${PLAYS} plays, incoming D = ${D_DEFAULT}.\n`);

	const base = S('Start (3 ATK, 3 BLK, 2 Ink, 2 Gen d4)', 'start');
	P('### 1-2. Starting bag and rewards\n');
	P(table([base,
		S('Start + d6 ATK, d6 BLK, d6 Gen (plain)', 'plain3'),
		S('Start + 3 random commons (effects modelled)', 'common3'),
	], base));

	P('\n### 3-4. Hammer bags, unmerged controls and thin-only controls\n');
	P(table([base,
		S('H2: ATK d8+d4, BLK d8+d4, 2 Ink, 2 Gen', 'h2'),
		S('  control: ATK d6+d6, BLK d6+d6, 2 Ink, 2 Gen', 'c2'),
		S('  thin only: 2 ATK, 2 BLK, 2 Ink, 2 Gen d4', 't2'),
		S('H4: ATK d8+d4, BLK d8+d4, Ink d8, Gen d8', 'h4'),
		S('H4 (d12s): ATK d12, BLK d12, 2 Ink, 2 Gen', 'h4big'),
		S('  control: ATK d6+d6, BLK d6+d6, Ink d6, Gen d6', 'c4'),
		S('  control (d12s): ATK d6, BLK d6, 2 Ink, 2 Gen', 'c4big'),
		S('  thin only: 2 ATK, 2 BLK, Ink, Gen d4', 't4'),
		S('H6: ATK d12, BLK d12, Ink d8, Gen d8', 'h6'),
		S('  control: ATK d6, BLK d6, Ink d6, Gen d6', 'c6'),
		S('  thin only: ATK, BLK, Ink, Gen d4', 't6'),
	], base));

	P('\n### 3b. With 3 reward d6s (ATK, BLK, Gen): d10 bags\n');
	const p3 = S('Start + 3 d6 (13 dice)', 'plain3');
	P(table([p3,
		S('3 visits: ATK d10, BLK d10, Gen d10 + 2 ATK, 2 BLK, 2 Ink, Gen d4', 'r3h3'),
		S('  control: same counts, no die above d6', 'cr3h3'),
		S('6 visits: ATK d10+d8, BLK d10+d8, Ink d8, Gen d10+d4', 'r3h6'),
		S('  control: same counts, no die above d6', 'cr3h6'),
	], p3));

	P('\n### Which limit binds: the same bags with unlimited plays\n');
	P('With no play limit every usable die in hand is played. If a bag barely gains, the 6-dice hand (not the 4 plays) is what holds it back.\n');
	P('| Bag | Effective, 4 plays | Effective, unlimited plays | Gain vs start, 4 plays | Gain vs start, unlimited |');
	P('|---|---|---|---|---|');
	const bu = S('', 'start', { plays: 99 });
	for (const [nm, k] of [['Start', 'start'], ['H2', 'h2'], ['H4', 'h4'], ['H4 (d12s)', 'h4big'], ['H6', 'h6'], ['H2 control (d6s)', 'c2'], ['H4 control (d6s)', 'c4']]) {
		const a = S(nm, k), u = S(nm, k, { plays: 99 });
		P(`| ${nm} | ${f2(a.eff)} | ${f2(u.eff)} | ${(a.eff - base.eff >= 0 ? '+' : '') + f2(a.eff - base.eff)} | ${(u.eff - bu.eff >= 0 ? '+' : '') + f2(u.eff - bu.eff)} |`);
	}

	P('\n### d12 vs two d6s, d10 vs d4 + d6\n');
	P(table([base,
		S('Start + ATK d6', 'plusD6'),
		S('Start + ATK d6 + ATK d6', 'plus2D6'),
		S('Start + ATK d12 (the two d6s hammered)', 'plusD12'),
		S('Start + ATK d6 kept beside an ATK d4 (11 dice)', 'd10kept'),
		S('Start with an ATK d4 and the d6 hammered into a d10', 'd10merged'),
	], base));

	P('\n### 5. Cutters\n');
	P(table([base,
		S('Cut an ATK d4: 2 ATK coins', 'cutA'),
		S('Cut an ATK d4 and a BLK d4', 'cutAB'),
		S('Cut a Generic d4: 2 generic coins', 'cutG'),
		S('Cut an Ink d4 (ink coins are dead here)', 'cutI'),
		S('Cut all 6 ATK and BLK d4s (12 coins)', 'cut6'),
		S('Start + ATK d6, cut to d4 + ATK coin', 'cutD6'),
		S('H4 (d12s), ATK d12 cut to d10 + coin', 'cutD12'),
	], base));

	P('\n### Incoming damage sensitivity (effective per turn)\n');
	P('| Bag | D = 0 (attack only) | D = 3 | D = 6 | D = 10 |');
	P('|---|---|---|---|---|');
	for (const [nm, k] of [['Start', 'start'], ['Start + 3 d6', 'plain3'], ['H2', 'h2'], ['H4', 'h4'], ['H4 (d12s)', 'h4big'], ['H6', 'h6'], ['Cut ATK + BLK', 'cutAB']]) {
		P(`| ${nm} | ${[0, 3, 6, 10].map((D) => f2(S(nm, k, { D }).eff)).join(' | ')} |`);
	}

	P('\n### 6. Cores: one die, exact odds\n');
	for (const size of [4, 6, 10]) {
		P(`\n**d${size}** (alignment 50 for Compass/Lodestone; their extremes below)\n`);
		P('| Core | Weights low to high | Average | SD | P(lowest) | P(highest) | Warrior average | Change vs no core |');
		P('|---|---|---|---|---|---|---|---|');
		const none = coreStats('', size);
		for (const c of CORES) {
			const s = coreStats(c, size);
			P(`| ${CORE_NAME[c]} | ${s.w.join(',')} | ${f2(s.mean)} | ${f2(s.sd)} | ${pc(s.pMin)} | ${pc(s.pMax)} | ${f2(s.warrior)} | ${(s.mean - none.mean >= 0 ? '+' : '') + f2(s.mean - none.mean)} |`);
		}
	}
	P('\n**Compass and Lodestone at the alignment extremes (d6)**\n');
	P('| Core | Alignment | Weights | Average | SD | P(lowest) | P(highest) |');
	P('|---|---|---|---|---|---|---|');
	for (const c of ['compass', 'lodestone']) for (const al of [0, 50, 100]) {
		ALIGNMENT = al; const s = coreStats(c, 6);
		P(`| ${CORE_NAME[c]} | ${al} | ${s.w.join(',')} | ${f2(s.mean)} | ${f2(s.sd)} | ${pc(s.pMin)} | ${pc(s.pMax)} |`);
	}
	ALIGNMENT = 50;

	// sampled check of the exact numbers, and the combat value of one cored Attack d6 in the starting bag
	P('\n### 6b. Cores in a fight: starting bag + one Attack d6 with the core\n');
	P('Trigger rates are per time the die is dealt (sampled, should match the exact P(lowest)/P(highest) above).\n');
	P('| Core | Sampled average | "Rolled its lowest" | "Rolled its highest" | Effective per turn | vs plain d6 |');
	P('|---|---|---|---|---|---|');
	let plainEff = 0;
	for (const c of CORES) {
		_seed = 42; let s = 0, lo = 0, hi = 0; const N = 200000;
		for (let i = 0; i < N; i++) { const f = rollFace(c, 6); s += f; if (f === 1) lo++; if (f === 6) hi++; }
		const bag = () => { const b = startBag(); b.push(die('ATK', 6, c)); return b; };
		const r = simulate(c, bag);
		if (c === '') plainEff = r.eff;
		P(`| ${CORE_NAME[c]} | ${f2(s / N)} | ${pc(lo / N)} | ${pc(hi / N)} | ${f2(r.eff)} | ${(r.eff - plainEff >= 0 ? '+' : '') + f2(r.eff - plainEff)} |`);
	}

	P('\n### Dead dice: the ink dice taken out\n');
	P(table([base,
		S('Start minus 1 Ink d4', 'minusInk1'),
		S('Start minus both Ink d4s', 'minusInk2'),
		S('H3: ATK d8+d4, BLK d8+d4, 2 Ink, Gen d8', 'h3'),
	], base));

	P('\n### Levers (simulated)\n');
	P('Effective per turn, and the change vs the starting bag (' + f2(base.eff) + ').\n');
	P('| Rule | H2 | H3 | H4 | H4 (d12s) | H6 |');
	P('|---|---|---|---|---|---|');
	const row = (nm, cells) => P('| ' + nm + ' | ' + cells.map((r) => {
		if (!r) return '-';
		const v = (r.eff / base.eff - 1) * 100;
		return f2(r.eff) + ' (' + (v >= 0 ? '+' : '') + v.toFixed(0) + '%)';
	}).join(' | ') + ' |');
	row('As now', [S('', 'h2'), S('', 'h3'), S('', 'h4'), S('', 'h4big'), S('', 'h6')]);
	row('D: a merge loses 2 sides (d4+d4 = d6, d6+d4 = d8)', [S('', 'dH2'), S('', 'dH3'), S('', 'dH4'), S('', 'dH4big'), S('', 'dH6')]);
	row('E: a die over d6 takes 2 of the 6 hand spots', ['h2', 'h3', 'h4', 'h4big', 'h6'].map((k) => S('', k, { heavy: 6 })));
	row('F: a die over d8 uses 2 plays', ['h2', 'h3', 'h4', 'h4big', 'h6'].map((k) => S('', k, { bigCost: true })));
	return lines.join('\n');
}

// ---------------------------------------------------------------- the ink run (ink dice played, ink spent on rerolls/redraws)
// Each bag is run with ink worth lam effective points per pip for each lam in LAMS, and the best kept: ink is valued only
// by what its rerolls and redraws turn into.
const LAMS = [0, 0.25, 0.5, 1];
function simInk(key, opt = {}) {
	let best = null;
	for (const lam of LAMS) {
		const r = simulate(key, BAGS[key], Object.assign({ ink: true, lam }, opt));
		r.lam = lam;
		if (!best || r.eff > best.eff) best = r;
	}
	return best;
}
function mainInk() {
	const L = [];
	const P = (x) => L.push(x);
	P(`Ink run: ${FIGHTS} fights x ${TURNS} turns, D = ${D_DEFAULT}. Ink dice played; ink arrives next turn, capped at 12; reroll or redraw for 3.\n`);
	P('| Bag | Ink value used | Effective | vs start | Ink dead (first run) | Attack | Block | Ink made | Ink spent | Rerolls | Redraws | Unspent at End Turn | Lost to cap |');
	P('|---|---|---|---|---|---|---|---|---|---|---|---|---|');
	const base = simInk('start');
	for (const [nm, k] of [['Start', 'start'], ['H2 (d8s)', 'h2'], ['H2 control (d6s)', 'c2'], ['H3 (d8s)', 'h3'], ['H4 (d8s)', 'h4'], ['H4 control (d6s)', 'c4'], ['H4 (d12s)', 'h4big'], ['H6', 'h6']]) {
		const r = simInk(k), d = simulate(k, BAGS[k]);
		P(`| ${nm} | ${r.lam} | ${r.eff.toFixed(2)} | ${((r.eff / base.eff - 1) * 100).toFixed(0)}% | ${d.eff.toFixed(2)} | ${r.atk.toFixed(2)} | ${r.blk.toFixed(2)} | ${r.inkGain.toFixed(2)} | ${r.inkSpent.toFixed(2)} | ${r.rerolls.toFixed(2)} | ${r.redraws.toFixed(2)} | ${r.inkHeld.toFixed(2)} | ${r.inkCapped.toFixed(2)} |`);
	}
	P('\n**Plays vs hand** (effective per turn)\n');
	P('| Bag | 6 dealt, 4 plays | 6 dealt, 5 plays | 6 dealt, unlimited | 7 dealt, 4 plays | 7 dealt, unlimited | +1 play | +1 die dealt |');
	P('|---|---|---|---|---|---|---|---|');
	for (const [nm, k] of [['Start', 'start'], ['H2', 'h2'], ['H4', 'h4']]) {
		const a = simInk(k), p5 = simInk(k, { plays: 5 }), pu = simInk(k, { plays: 99 }), h7 = simInk(k, { hand: 7 }), h7u = simInk(k, { hand: 7, plays: 99 });
		P(`| ${nm} | ${a.eff.toFixed(2)} | ${p5.eff.toFixed(2)} | ${pu.eff.toFixed(2)} | ${h7.eff.toFixed(2)} | ${h7u.eff.toFixed(2)} | +${(p5.eff - a.eff).toFixed(2)} | +${(h7.eff - a.eff).toFixed(2)} |`);
	}
	P('\n**What a point of ink buys** (3 free ink at the start of every turn)\n');
	P('| Bag | Effective | With +3 ink a turn | Per ink |');
	P('|---|---|---|---|');
	for (const [nm, k] of [['Start', 'start'], ['H2', 'h2'], ['H4', 'h4']]) {
		const a = simInk(k), b = simInk(k, { freeInk: 3 });
		P(`| ${nm} | ${a.eff.toFixed(2)} | ${b.eff.toFixed(2)} | ${((b.eff - a.eff) / 3).toFixed(2)} |`);
	}
	P('\n**Hammer, with the "merge loses 2 sides" lever** (effective, vs start)\n');
	P('| Rule | H2 | H3 | H4 (d8s) | H4 (d12s) | H6 |');
	P('|---|---|---|---|---|---|');
	const cell = (k) => { const r = simInk(k); return r.eff.toFixed(2) + ' (' + ((r.eff / base.eff - 1) * 100 >= 0 ? '+' : '') + ((r.eff / base.eff - 1) * 100).toFixed(0) + '%)'; };
	P('| As now | ' + ['h2', 'h3', 'h4', 'h4big', 'h6'].map(cell).join(' | ') + ' |');
	P('| A merge loses 2 sides | ' + ['dH2', 'dH3', 'dH4', 'dH4big', 'dH6'].map(cell).join(' | ') + ' |');
	return L.join('\n');
}

if (require.main === module) console.log(process.argv[3] === 'ink' ? mainInk() : main());
module.exports = { simulate, BAGS, coreStats, weights };
