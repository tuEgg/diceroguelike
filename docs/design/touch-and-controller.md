# Touch and controller support: plan

2026-11-24. Asked: how complex, and plan it in. Short answer: **touch is small, controller is the big one**, and both are much cheaper if we decide the approach now and keep new UI code on the same path.

## Where the code stands

- **All input is the mouse, read in immediate mode.** About 91 `mouse_hovering` calls (the one place hover, layers, sounds and the tooltip anchor are decided), 108 `mb_left` reads, 142 `device_mouse_x_to_gui` / `mouse_x` reads, 33 keyboard reads, zero gamepad reads.
- **Right click is used 11 times**, and it carries real actions: redraw a die, rewrite an intent, take a die back, put a tool down, clear a slot.
- **Hover is how things are explained.** 91 `queue_tooltip` calls: touch has no hover, a controller has no pointer.
- **Dragging is core**: dice to slots, dice to the sacrifice tile, dice to the discard pile, workbench dice and tools, the timeline markers.
- **The web build runs on a Mac, a PC and, soon, probably a phone or tablet.** GameMaker's HTML5 runner already turns a touch into mouse device 0 (left button), which is why touch half works today.

## Touch (about 2 to 4 days)

What already works: taps, and drags (a touch is a left-button drag), as the runner maps them.

What needs work:

1. **No hover.** A tap should show the tooltip, and a second tap act. Cheapest honest version: in `mouse_hovering`, when the last pointer was a touch, treat "pressed this frame" as "hover this frame" and keep the last tapped thing hovered until the next tap elsewhere. Tooltips then open on a tap and stay.
2. **Right-click actions.** Give each a touch route: long press = right click (a timer in one place), plus a visible button where it matters (the ink view already has Reroll and Redraw buttons under each die; Rewrite has its quill icon; take-back could be a small button on the slot).
3. **Target sizes.** Many hit areas are 40 to 60 px at 1920 wide; on a phone that is too small. A global `UI_TOUCH_SCALE` that grows hit areas (not art) when touch is the last input.
4. **Keyboard shortcuts** (Enter ends the turn, Tab ink, Escape pause) need on-screen equivalents: End Turn already is a button, the inkwell is the ink toggle, the cog is the pause button. Probably nothing to add.
5. **Browser chrome**: a fullscreen button, `touch-action: none` and no pinch-zoom on the canvas (the itch.io page and `index.html`), and an orientation lock hint.
6. Test on a real phone and an iPad; Safari audio needs a first tap to unlock (the main menu click does that).

## Controller (about 2 to 3 weeks for a good one)

There is no focus model in an immediate-mode UI, so a controller means choosing one of:

**A. A stick-driven cursor (recommended first step, about 3 to 5 days).** The left stick moves a pointer, A is left click, X or B is right click, shoulder buttons are Tab and End Turn, Start is pause. Everything keeps working, drags included (hold A). It is the Steam Deck answer and the cheapest correct one. Needs: one `input_pointer()` that every `device_mouse_x_to_gui` call goes through (a find-and-replace of 142 reads, then the stick moves a virtual position), the cursor drawn in `cursor_draw`, and the tooltip anchor already follows `hover_rect`.

**B. Real focus navigation (about 2 to 3 weeks).** D-pad or stick moves between things. Needs each screen to register its focusable rects each frame (the `mouse_hovering` call is the natural place: it already knows every rect, layer and sound), a "nearest in direction" picker, and a controller version of every drag (pick up, move the focus, put down). Much nicer to play, much more to build and to keep in step with every new screen.

Plan: do A, ship it, and only start B if controller play becomes a real target (a console port, say).

## What to do now so it stays cheap

1. **Route every pointer read through two functions**, `input_x()` and `input_y()` (GUI coordinates) and one `input_pressed(button)`. Today new code calls `device_mouse_x_to_gui(0)` directly; each one added is another to change later. (A find-and-replace pass over the existing 142 can be done in one commit, with the game behaving identically.)
2. **Keep decisions inside `mouse_hovering`.** Anything new should use it, not its own rectangle test, so touch hover and controller focus only need changing there.
3. **Every right-click action gets a visible control or a keyboard key too**, as a rule for new features. (Accessibility wants this as well.)
4. **No hover-only information**: a tooltip that is the only place a rule is explained fails on touch and on controller. The tooltips already carry keywords and buffs, which is right; the new rule is "also reachable by tap".
5. **Hit areas at least 44 px** in new UI, drawn smaller if needed.

## Order if we go ahead

1. The `input_*` refactor (no visible change, one commit).
2. Touch: hover-on-tap, long press, hit-area scale, browser settings. Test on a phone.
3. Controller A: the stick cursor and the button map. Test on a Steam Deck or any pad.
4. Decide on B with real feedback.
