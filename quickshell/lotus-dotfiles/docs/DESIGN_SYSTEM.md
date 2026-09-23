# Lotus Paper design system

`Theme.qml` is the source of truth. Components must consume its semantic tokens instead of declaring private palettes or spacing scales.

## Direction

The two images in `docs/references/` define the target character: warm paper panels, dark hand-inked outlines, hard offset shadows, compact mono typography and small pastel controls. The interface should look drawn and tactile without becoming childish or noisy.

Design dials:

- Layout variance: 7/10. Use deliberate asymmetry and separate top islands.
- Motion intensity: 4/10. Prefer short tactile transitions over decorative loops.
- Visual density: 5/10. Keep widgets compact, but preserve clear group spacing.

## Color rules

- Use `canvas`, `surface`, and `surfaceRaised` for most area.
- Use `ink` for borders and primary text. Never use pure black.
- Give each interactive control one dominant pastel accent.
- Use multiple accents across a composition, but do not blend them into gradients.
- Reserve coral for destructive or urgent states and gold for warnings.
- Preserve at least 4.5:1 contrast for body text when practical. Never place muted text on pastel fills without checking it.

## Geometry and spacing

- Use the 4 px spacing scale from `Theme.qml`.
- Keep both side islands at `sideIslandHeight` and the media island at `mediaIslandHeight`; derive the reserved top zone from the taller media token and `islandMargin`.
- Use 2 px outlines on standard controls and containers.
- Use the 6 px hard shadow without blur. A control moves toward its shadow when pressed.
- Use `radiusControl` for controls, `radiusCard` for widgets and `radiusPanel` for large windows.
- Align related elements to a shared edge. Asymmetry belongs between groups, not inside a sloppy group.
- Keep interactive targets at least 32 px high. Prefer the 38 px standard control height.

## Typography

- Use Maple Mono for display, body and numeric text during the first design phase.
- Use weight and size for hierarchy. Do not introduce a second font until a real component proves it is needed.
- Use uppercase labels sparingly for status and compact metadata.
- Use tabular-looking alignment for clocks, durations, percentages and hardware metrics.

## Icons

- Use project-owned SVG icons in `assets/icons/`.
- Standardize artwork to 16, 20 and 24 px view boxes with a consistent visual stroke.
- Prefer outlined icons with rounded joins that match the dark border language.
- Do not mix emoji, random Nerd Font glyphs and SVG icons in the same interface.
- Add an icon only when a component needs it. Do not build a speculative icon pack.

## Motion and states

- Animate opacity, translation and scale. Avoid animating width, height or anchored positions.
- Use `motionFast` for press and hover feedback, `motionNormal` for controls and `motionSlow` for window entry.
- Every interactive component needs hover, pressed, keyboard-focus and disabled states.
- Data widgets need loading, empty and error presentations before they are considered complete.
- Avoid permanent decorative animation. Activity indicators may animate only while work is happening.

## Reference boundaries

The reference images guide visual language and composition. Do not copy usernames, locations, task text, music choices or application lists. Use real local data once services are connected.
