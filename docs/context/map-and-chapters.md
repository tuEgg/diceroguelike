# World map, book and chapters

Room `rmMap`, object `oWorldManager` (persistent for the run). Logic in `oWorldManager` Step/Draw GUI/Room Start/Room End, helpers in `scripts/scMap`.

## The book

- Drawn in `oWorldManager/Draw_64`: covers, then turned pages on the left and unread pages on the right, placed by **depth from the open spread** (`page_offset` px apart), so the open spread never moves. `page_image_indices` (from `generate_book_pages`, `CHAPTER_SPREADS + 2` pages) picks each page's paper art.
- Chapters still to come get `future_pages_per_chapter` extra pages behind, each with a divider tab on its first page (`draw_chapter_tab`, colour `chapter_tab_colour`). Tunable numbers sit at the top of that block.
- `draw_voyage_progress` draws the marker track under the book (one per spread, diamond per boss).
- Page turning: `current_page_turn` goes 1 → -1 in `WORLD_STATE.TURNING`; the finished spread's islands/icons follow via `draw_page_turning`.

## States (`world_state`, enum `WORLD_STATE`)

`OPENING` (book opens) → `DRAFTING` (pick pages; Embark) → `EXPLORING` (sail node to node) → `TURNING` (spread done: heal or core choice, page turns). The rest heal is `ceil(max_hp * rest_amount)` (25%, raised by Salted Pork via `on_rest`), rounding up like the healing potion, and its tooltip shows the real percentage → `DRAFTING`... and `CHAPTER_END` after a boss. `world_finish_spread_if_done()` (Room Start and Step) moves EXPLORING to TURNING or CHAPTER_END. The choice (TURNING state, oWorldManager Draw GUI): "Heal X HP" on the left page, "Gain a random core" on the right, Continue below; each is greyed with a reason when it can't be taken (full health, no free item slot). The heal amount is worked out once per spread end (`rest_heal_preview`). The choice waits for the page turn to finish.

## Pages and nodes

- `generate_pages()` fills `pages_shown` with 3 candidate pages (1–2 nodes each) using the `*_chance` odds (retuned in Room End, `Other_5`). Drafting one clones it into `chosen_pages` and adds its nodes to `all_nodes`; the first pick locks one of the other two (the map lock is a design pillar, keep it).
- Page struct: `index, island_index, num_nodes, nodes (ds_list), layout, margin, x, y, chosen, locked, cleared, is_boss`. `draw_page` draws the island (masked with surfaces and shaders `shWhiteFill`, `shErode`) and node icons, and handles node clicks.
- Node templates `node_combat`, `node_event`, `node_shop`, `node_elite`, `node_boss`, `node_treasure`, `node_alignment`, `node_bounty`... copy with `clone_node_static`.
- Clicking `next_node` sails the boat; arriving calls `enter_node(node)`, marks it cleared and updates `nodes_til_drafting`, `nodes_til_page_cleared`, `pages_cleared`, `spreads_cleared`.

## Entering a node: `enter_node`

Decides everything random **once, on the node** (so Continue brings back the same thing), then saves, then `room_goto(node.linked_room)`:
- event nodes: `event_roll` (8% become a fight, 8% a shop unless the Dutchman was taken) and `event_name`
- fights: `get_combat_enemies(node, memory_node)` → `node_pick_encounter` stores `encounter` ("Encounter 3", "Elite 1"...) and fills `oWorldManager.room_enemies` by name
- shops: `shop_stock` (`roll_shop_stock`), treasure: `treasure_keepsake`
- `current_node` is set here and cleared on map Room Start and by debug jumps.

## Chapters

`CHAPTER_SPREADS` (7) drafted spreads, then `place_boss_page()` lays a single boss page (not drafted). `CHAPTER_COUNT` (3). Boss win → `CHAPTER_END` screen → `start_new_chapter()` (fresh book, pools refilled, saves) or, after the last chapter, "Voyage complete" back to the menu. `enemy_apply_chapter_scaling` toughens enemies per chapter (`CHAPTER_ENEMY_HP_GROWTH`, `CHAPTER_ENEMY_BONUS_GROWTH`).

## Encounter pools

`possible_encounters`, `possible_elites`, `possible_alignment_encounters` (string keys; refilled when empty), switched to harder sets after `nodes_cleared` thresholds in Room End. Bounties temporarily replace `possible_elites`.
