# Art tips: fitting relic and core art to the logbook look (H13)

For reworking keepsake (relic), core and item icons so they sit with the UI rework (`docs/design-ui-rework.md`): ink and paper on a chart table at dusk. Written 2026-11-19.

## The rules

1. **Ink first.** One dark-brown outline (ink, about `#2A1D12`) at one weight on every icon: 3 to 4 px at the size it's shown. Mixed line weights are the biggest tell that icons come from different sets.
2. **Colour from the palette only.** Parchment creams, ink, brass, slate, and the four pigments: attack red `#B33A22`, block blue `#6FA8E8`, heal green `#3C9A68`, insight yellow `#F2D24A`. Pull saturated or neon colours toward these. Test: put the icon on a parchment card and squint. If it glows, it's off-style.
3. **One light, one shadow.** Light from the top left; one flat shadow tone (the base colour mixed about 25% toward ink); at most one highlight. No gradients, glows or soft airbrushing.
4. **Draw it like an object on the chart table.** Keepsakes are things a captain would keep: a brass compass, a wax-sealed letter, a carved tooth. A slight three-quarter angle and a small contact shadow under it, so it sits on the table rather than floats.
5. **Cores as engraved medallions.** A brass ring with the core's shape stamped inside: Edge two marks at the rim, Dome a hump, Bell a curve, Weighted and Loaded a slope, Compass a needle, Lodestone a horseshoe magnet. The art then explains the distribution. (Compass and Lodestone reuse Odd and Even's frames in `sCores` until they get their own.)
6. **Silhouette test.** Fill each icon solid black at its real size (about 48 px). If you can't tell two apart, fix the shapes, not the colours. This also helps colour-blind players.
7. **Rarity lives in the frame, not the object.** Grey, green, purple rings or frames (`rarity_colour` in scHelpers), as the reward cards do. Keep the object's own colours honest.

## Converting existing (or AI-made) art quickly

1. Posterize to 4 to 6 colours.
2. Gradient-map (Photoshop or Krita) each tone to its nearest palette colour.
3. Add the ink outline last, on its own layer, at one weight.
4. Add a faint parchment texture on multiply at 8 to 10% opacity, the same texture for every icon.
5. Do a whole set in one sitting, so the line weight and light direction match.
