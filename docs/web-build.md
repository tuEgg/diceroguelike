# Web build (H07)

How to export Tides of Fortune for the browser, put it on itch.io privately, and what to check. The desktop build is the reference; the web build is for early playtests.

## What the code does differently in a browser

All of it is behind `IS_BROWSER` (scDisplay), so the desktop build is unchanged.

- The game always draws at 1920x1080. The canvas is the biggest 16:9 box that fits the page, and it refits when the page or itch.io's frame changes size (`apply_browser_resolution`, `browser_check_resize`, called from oSettingsMenu's Step).
- There's no Resolution option in Settings, and fullscreen isn't restored at start-up (browsers only allow it after a click). The Fullscreen toggle still works.
- There's no Exit button on the main menu, and double Escape doesn't quit (a web page can't quit).
- Saves and settings use the same `file_text_*` calls; in a browser GameMaker keeps them in the browser's local storage.
- HTML5 options: WebGL is required (the map's shaders need it), and the canvas is centred. The page behind the game is dark navy (a small script in the HTML5 options, "Prepend JavaScript"), so the bars beside a 16:9 game don't show white.
- Sounds are set to Compressed, so GameMaker encodes them as Ogg in every build (the WAV files in the project stay as they are).

## Export

1. In GameMaker, open the target menu (top right, the platform drop-down) and pick **HTML5**. If HTML5 isn't in the list, tell Claude: it depends on your GameMaker licence, and GX.games is the fallback.
2. Quick check first: press **Run** with HTML5 selected. It opens in your browser from a local server. (This is an IDE run, so the F1 debug tools are on. In a browser F5 reloads the page and F6/F11/F12 belong to the browser, so use F1 and the in-menu buttons.)
3. For itch.io: **Build > Create Executable**, choose a folder or zip. You need a zip with `index.html` at its top level (not inside a sub-folder).

## Upload to itch.io privately

1. itch.io > Dashboard > **Create new project**.
2. Kind of project: **HTML**. Upload the zip and tick **This file will be played in the browser**.
3. Embed options: viewport **1280 x 720**, tick **Fullscreen button**, leave **Automatically start on page load** off (a click to start lets the browser play sound).
4. Visibility: **Draft** to test alone, or **Restricted** to share with chosen playtesters. Save, then open the page.

## Smoke test

Write down anything that breaks, with the browser name. Red errors in the browser console (F12 > Console) are the most useful thing to copy back.

- Loads to the main menu. No Exit button. Music and click sounds play after your first click.
- The game is 16:9 and centred. Resize the browser window: it refits. itch.io's fullscreen button fills the screen, and Escape leaves it.
- Clicks land where they should: main menu, Settings sliders, map nodes, dragging dice into slots, the F1-free buttons.
- The map: island shapes look like the desktop build (these use surfaces and two shaders). Wonky rectangles and the book look right.
- Text is crisp, in the right fonts.
- Play a whole fight: dice, slots, insight panel, tooltips, rewards.
- Settings: no Resolution row; volume changes stick after reloading the page; Fullscreen toggles.
- Saving: play into the map, reload the page, **Continue** works.
- It runs smoothly on the map and in combat (note any stutter, and on which screen).
- Try a second browser (Chrome plus Firefox or Safari).
