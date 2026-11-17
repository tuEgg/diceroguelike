# Getting Tides of Fortune on itch.io

Three steps: a private page you test yourself, then a hidden page you share with playtesters, then public when you're ready. Export steps and the smoke test are in `docs/web-build.md`.

## 1. Private page (today)

1. Export HTML5 as a zip with `index.html` at the top level (`docs/web-build.md`).
2. itch.io > Dashboard > **Create new project**.
   - Title: Tides of Fortune. Project URL: something short, e.g. `tides-of-fortune`.
   - Kind of project: **HTML**. Upload the zip, tick **This file will be played in the browser**.
   - Embed: viewport **1280 x 720**, tick **Fullscreen button**, leave **Mobile friendly** off and **Automatically start on page load** off (a click to start lets the browser play sound).
   - Pricing: **No payments**.
   - Visibility: **Draft**.
3. Save and view the page. Run the smoke test there (it's the real thing players will get).

## 2. Playtester page

A draft page has a secret link you can send to people (itch.io shows it on the edit page; if not, switch Visibility to **Restricted** and add people). Before sending it, fill in the page so testers know what they're looking at:

- **Short description** (one line): e.g. "A dice-building roguelike: sail through a captain's logbook, building your dice and reading your enemies."
- **Cover image** (630 x 500) and 3 to 5 **screenshots** (take them in the desktop build at 1920 x 1080: map, a fight, the shop, a reward).
- **Description**: what it is, that it's an early playtest build, mouse controls, roughly how long a run takes, and how to give feedback.
- **Genre** Strategy; **tags** roguelike, deckbuilder, dice, turn-based, pirates.
- **Feedback**: turn on **Comments**, or link a short form. Ask testers what confused them, where they died, and what they skipped.

## 3. Public

Switch Visibility to **Public** when you're happy. Each update after that: export, upload the new zip (replace the old file), and post a short devlog on the page saying what changed.

## Worth knowing

- **Licence:** GameMaker's free licence is for non-commercial games. A free (no payments) itch.io page fits that, but check GameMaker's licence page before you take money for it.
- **Updating faster later:** itch.io's command-line uploader, `butler`, can push a build folder in one command. Claude can set that up once you've made an itch.io API key (you keep the key; it never goes in the repo).
- **Known web-build rough edges** (KANBAN): shapes drawn in code (button panels, pips, icon outlines) look a little jagged in the browser (B118, parked until real UI art); the desktop build is smooth. Art (F50) is placeholder.
- **AI disclosure:** itch.io asks; tick **Code** and **Text & Dialog** (tutorial notes, tips and some in-game text were written with Claude Code). The insight icons and UI shapes are drawn in code, not generated images.
- **What to ask testers:** what confused them, where they died and to what, what they never used (consumables, the workbench, Quill), and what made them want another run. Bring the answers back and we pick the next batch from KANBAN ("Waiting for playtest feedback").
