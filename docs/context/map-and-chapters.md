# World map, book and chapters

Room `rmMap`, object `oWorldManager` (persistent for the run). Logic in `oWorldManager` Step/Draw GUI/Room Start/Room End, helpers in `scripts/scMap`.

## The book

- Drawn in `oWorldManager/Draw_64`: covers, then turned pages on the left and unread pages on the right, placed by **depth from the open spread** (`page_offset` px apart), so the open spread never moves. `page_image_indices` (from `generate_book_pages`, `CHAPTER_SPREADS + 2` pages) picks each page's paper art.
- Chapters still to come get `future_pages_per_chapter` extra pages behind, each with a divider tab on its first page (`draw_chapter_tab`, colour `chapter_tab_colour`): a short unlabelled tab (`tab_out` 38) that pulls out on hover (`tab_pull`), its tooltip naming the chapter. Tunable numbers sit at the top of that block.
- `draw_voyage_progress` draws the marker track under the book (one per spread, diamond per boss).
- Page turning: `current_page_turn` goes 1 → -1 in `WORLD_STATE.TURNING`; the finished spread's islands/icons follow via `draw_page_turning`.

## States (`world_state`, enum `WORLD_STATE`)

`OPENING` (book opens) → `DRAFTING` (pick pages; Embark) → `EXPLORING` (sail node to node) → `STRAIT` (spread done: sea stops on the map) → `TURNING` (the page turns) → `DRAFTING`... and `CHAPTER_END` after a boss. `world_finish_spread_if_done()` (Room Start and Step) moves EXPLORING to STRAIT or CHAPTER_END. STRAIT was added last in the enum so saved numbers keep their meaning.

**Linked stops (v0.2.1):** while drafting, a treasure or elite that more than one offered page has is linked (`draft_links_mark` sets `node.linked`; `draft_links_draw` draws dashed brass lines between them over the cards; `map_node_icon_draw` rings them), since picking one page takes it off the others. The page that loses one gets `node_morph_into`: its node shows the old icon until the lost page has burned, then shrinks, puffs and pops into the new one; the auto-take waits for it (`page_has_morph`).

**Visited (F148, F171):** `map_visited_tick(x, y)` (scMap) inks a tick on done stops; icons are the sprites as drawn (`map_icon_draw`, grey-tinted when unreachable); done stops are circled with a tick (`map_done_ring`), not faded; the ship moors down-left of a sea stop so the tick shows. Island stops carry their name underneath (draw_page); sea stops are a soft blue disc and the icon (`sea_stop_draw`); everything grows on hover. While drafting, `draw_page` inks each page's course between its stops, and draws the cards as landscape sheets of sea chart in code (F178, option A: `ui_paper` in `DRAFT_CARD_SEA`, `DRAFT_CARD_W` x `DRAFT_CARD_H`, macros at the top of scMap; the island masked to the card's shape, at `_icx` left of centre, scaled `_is` 0.78 with its stops); `page_passage_preview(..., _inside true)` puts the sea stop in the card's right part, with a course out to it (for pages already picked, on the book, it sits beside the page as on the chart); `page_pos` sits the three cards 570 px apart round the middle. `map_waves_draw` (oWorldManager Draw GUI, before the pages) adds a rare small wave on the water pages. The map ship is drawn at 0.8 scale.

**The spread as a chart (F125), laid out B+ (2026-11-21, `docs/mockups/map-layouts.html`)**: every drafted page brings a sea stop after its island (`page.passage`: calm, workbench, core, whet, gold, trim; `pages_assign_passages` in `generate_pages` rolls them all different and guarantees one is Calm water or the Shipwright). Drafting shows it on each card's corner (`page_passage_badge`) and, for pages already chosen, where it will sit. Chosen pages sit 70 px left of their old spot (`spread_sea_spots`: `buoy` = the left page's stop in the gutter, `strait` = the right page's past it). The ship sails island → its stop → island → its stop → page turns. **Left page's stop**: `passage_left_draw` (the old buoy; `sea_buoy` holds its look and stamp); once the left island is done it breathes and must be sailed through before the right island (`map_node_blocked_reason`, also blocks node clicks while `map_sailing_to_sea`); arriving runs `passage_arrive` (calm heals if hurt; the Shipwright saves and opens the workbench; the rest `spread_end_apply`) and sets `page.passage_done` (saved with the page). **Right page's stop**: the strait, now one stop (`strait_build` reads the page's passage; `strait_activate` turns an unusable stop into calm via `passage_resolve`); `strait_draw` sails there, applies it, stamps, sails out, TURNING (the workbench there turns the page while you're at the bench, as before). `spread_routes_draw` inks the courses (left island → its stop → right island; right island → its stop → the book's edge). **The boss spread**: `harbour_draw` puts a harbour on the left page, rest (calm) or refit (workbench); choose one, then the boss (`page.harbour_done`, saved; `harbour` holds its runtime state). Pages saved before B+ have no passage and count it as passed; their strait falls back to calm water. Calm water heals `passage_heal_amount()` (`rest_amount` 30% after `on_rest` keepsakes).

## Pages and nodes

- `generate_pages()` fills `pages_shown` with 3 candidate pages (1–2 nodes each) using the `*_chance` odds (retuned in Room End, `Other_5`). Drafting one clones it into `chosen_pages` and adds its nodes to `all_nodes`; the first pick locks one of the other two, which burns away (`page_burn_draw`: the page drawn into `burn_surf`, then through the `shBurn` shader with `u_t`, plus ember particles), and the last is taken for you after `auto_take_t` frames (`auto_take_page`, Draw GUI) (the map lock is a design pillar, keep it).
- Page struct: `index, island_index, num_nodes, nodes (ds_list), layout, margin, x, y, chosen, locked, cleared, is_boss, passage, passage_done, harbour_done`. `draw_page` draws the island (masked with surfaces and shaders `shWhiteFill`, `shErode`) and node icons, and handles node clicks.
- Node templates `node_combat`, `node_event`, `node_shop`, `node_elite`, `node_boss`, `node_treasure`, `node_alignment`, `node_bounty`... copy with `clone_node_static`.
- The ship moves by voyages (`boat_sail_toward(x, y)`, scMap, returns true on arrival): smootherstep eased at both ends, weaving across its course with a heel (`boat_data.tilt`) strongest mid-voyage. Every move uses it (islands, buoy, strait stops, sailing in and out of the book).
- Clicking `next_node` sails the boat; arriving calls `enter_node(node)`, marks it cleared and updates `nodes_til_drafting`, `nodes_til_page_cleared`, `pages_cleared`, `spreads_cleared`.

## Entering a node: `enter_node`

Decides everything random **once, on the node** (so Continue brings back the same thing), then saves, then `room_goto(node.linked_room)`:
- event nodes: `event_roll` (8% become a fight, 8% a shop unless the Dutchman was taken) and `event_name`
- fights: `get_combat_enemies(node, memory_node)` → `node_pick_encounter` stores `encounter` ("Encounter 3", "Elite 1"...) and fills `oWorldManager.room_enemies` by name
- shops: `shop_stock` (`roll_shop_stock`), treasure: `treasure_keepsake`
- `current_node` is set here and cleared on map Room Start and by debug jumps.

## Look (UI rework)

The draft heading is a `ui_label`; Embark is `ui_primary` bottom right (the tip `embark` points there); the chapter end is a `ui_paper` page with `ui_primary` at its bottom right; sea-stop names are ink with a paper halo.

## Chapters

`CHAPTER_SPREADS` (4; Q13 made it 3, Jared made it 4 on 2026-11-21) drafted spreads, then `place_boss_page()` lays a single boss page (not drafted). `CHAPTER_COUNT` (3). Boss win → `CHAPTER_END` screen → `start_new_chapter()` (fresh book, pools refilled, saves) or, after the last chapter, "Voyage complete" back to the menu. `enemy_apply_chapter_scaling` toughens enemies per chapter (`CHAPTER_ENEMY_HP_GROWTH`, `CHAPTER_ENEMY_BONUS_GROWTH`); from chapter 1 every attack move also gains `ENEMY_ATTACK_BOOST` (20%) of its average roll, at least +1 (Q11). The player starts on 60 HP. Only Calm water heals (`rest_amount` 30%, after `on_rest` keepsakes): as a page's sea stop or the harbour's rest (Q14, B+).

## Encounter pools

`possible_encounters`, `possible_elites`, `possible_alignment_encounters` (string keys; refilled when empty), switched to harder sets after `nodes_cleared` thresholds in Room End. Bounties temporarily replace `possible_elites`.
