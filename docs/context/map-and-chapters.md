# World map, book and chapters

Room `rmMap`, object `oWorldManager` (persistent for the run). Logic in `oWorldManager` Step/Draw GUI/Room Start/Room End, helpers in `scripts/scMap`.

## The book

- Drawn in `oWorldManager/Draw_64`: covers, then turned pages on the left and unread pages on the right, placed by **depth from the open spread** (`page_offset` px apart), so the open spread never moves. `page_image_indices` (from `generate_book_pages`, `CHAPTER_SPREADS + 2` pages) picks each page's paper art.
- Chapters still to come get `future_pages_per_chapter` extra pages behind, each with a divider tab on its first page (`draw_chapter_tab`, colour `chapter_tab_colour`). Tunable numbers sit at the top of that block.
- `draw_voyage_progress` draws the marker track under the book (one per spread, diamond per boss).
- Page turning: `current_page_turn` goes 1 → -1 in `WORLD_STATE.TURNING`; the finished spread's islands/icons follow via `draw_page_turning`.

## States (`world_state`, enum `WORLD_STATE`)

`OPENING` (book opens) → `DRAFTING` (pick pages; Embark) → `EXPLORING` (sail node to node) → `STRAIT` (spread done: sea stops on the map) → `TURNING` (the page turns) → `DRAFTING`... and `CHAPTER_END` after a boss. `world_finish_spread_if_done()` (Room Start and Step) moves EXPLORING to STRAIT or CHAPTER_END. STRAIT was added last in the enum so saved numbers keep their meaning.

**The spread as a chart (F125)**: chosen pages sit 70 px left of their old spot, leaving room for a sea stop past each island (`spread_sea_spots`: the buoy past the left page, the strait past the right). While sailing a spread (EXPLORING or STRAIT), oWorldManager Draw GUI draws `spread_routes_draw` (dotted S-curves, `route_draw`: each island's nodes in order, left island → buoy → right island and left → right directly, right island → each strait stop; taken strong, possible faint, passed by fainter), then `sea_buoy_draw` and `strait_draw`, all spread long; plus courses in from the book's left edge and out from each strait stop to its right edge (`book_left_x`, `book_right_x`, set each frame; the boss spread gets just the course in). The ship sails in from the left edge after Embark (`boat_data.entering`), and after a strait stop sails out to the right edge (`strait.leaving`) before TURNING, then on off the book while the page turns; it fades past the book's edges. **The strait (F112, scMap)**: the end of a spread is a fork of sea stops on the map, no panel. `strait_build` plans it when the spread starts (reset in `start_drafting`): the Shipwright's buoy (workbench, can be taken if `workbench_useful()`) plus two rolled by `spread_end_roll_options`; `strait_activate` (on reaching STRAIT) works out the heal and adds calm water if none can be taken. The stops are positioned by `strait_stop_spot` (core "The wreck", trim "Squall", whet "Whetstone reef", gold "Flotsam"; `strait_stop_info` names them and reuses `spread_end_option_info`), or "Calm water" if none can be taken; the heal is `ceil(max_hp * rest_amount)` after `on_rest` keepsakes. `strait_draw(ax, ay)` (oWorldManager Draw GUI, under the ship, at the outer side of the right page) draws each stop (`sea_stop_draw`, code-drawn badges) with a dotted course (`sea_route_draw`); click sails the ship there. On arrival you heal (if hurt) and `spread_end_apply` runs (trim and whet open the dice picker); an ink stamp shows what you got, and once it fades (and the picker is closed) the state goes to TURNING. The buoy instead sets TURNING and goes to the workbench, so the page turns when you come back. TURNING now just turns the page and calls `start_drafting`. Between a spread's pages, `sea_buoy_draw(x, y)` draws the Shipwright's buoy (`oWorldManager.sea_buoy`, one per spread) all spread; it can be sailed to (`active`) once the left island is done while `can_visit_workbench` and `workbench_useful()`: it opens the workbench (`visited`); clicking the next island sails past (island clicks are blocked while sailing to it).

## Pages and nodes

- `generate_pages()` fills `pages_shown` with 3 candidate pages (1–2 nodes each) using the `*_chance` odds (retuned in Room End, `Other_5`). Drafting one clones it into `chosen_pages` and adds its nodes to `all_nodes`; the first pick locks one of the other two (the map lock is a design pillar, keep it).
- Page struct: `index, island_index, num_nodes, nodes (ds_list), layout, margin, x, y, chosen, locked, cleared, is_boss`. `draw_page` draws the island (masked with surfaces and shaders `shWhiteFill`, `shErode`) and node icons, and handles node clicks.
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

The draft heading is a ; Embark is  bottom right (the tip  points there); the chapter end is a  page with  at its bottom right; sea-stop names are ink with a paper halo.

## Chapters

`CHAPTER_SPREADS` (7) drafted spreads, then `place_boss_page()` lays a single boss page (not drafted). `CHAPTER_COUNT` (3). Boss win → `CHAPTER_END` screen → `start_new_chapter()` (fresh book, pools refilled, saves) or, after the last chapter, "Voyage complete" back to the menu. `enemy_apply_chapter_scaling` toughens enemies per chapter (`CHAPTER_ENEMY_HP_GROWTH`, `CHAPTER_ENEMY_BONUS_GROWTH`).

## Encounter pools

`possible_encounters`, `possible_elites`, `possible_alignment_encounters` (string keys; refilled when empty), switched to harder sets after `nodes_cleared` thresholds in Room End. Bounties temporarily replace `possible_elites`.
