# QML / Quickshell Notes

Cross-cutting gotchas and conventions that would otherwise get restated as comments in
every file that runs into them. If you're about to write a comment explaining one of
these patterns.

---

> NOTE: This documentation was written by Claude, and checked by Squirrel Modeller

## 1. Reactivity pitfalls

### A component's own size must never depend on its own `visible`

`Item.visible`, when read, reflects effective (ancestor-cascaded) visibility - it's
`false` whenever ANY ancestor is invisible, not just when the item's own flag was set to
`false`. So `implicitWidth: visible ? 30 : 0` is dangerous: the moment that component
sits anywhere that also computes an ANCESTOR's visibility FROM that same width (any
overflow/fit-count/responsive-collapse logic), you get a real circular dependency -
`fitCount -> visible -> (cascades down) -> this implicitWidth -> fitCount again`.

Size should be unconditional. Let the PARENT decide inclusion/exclusion purely via
`visible` on the wrapper - never let a child's own size double as a visibility signal.

### `Layout` exclusion requires real `visible: false`

A `Layout`-managed container (`GridLayout`, `RowLayout`, etc.) fully excludes an
invisible child from both its allocated space and the surrounding
`columnSpacing`/`rowSpacing` - but only when the child's own `visible` is `false`.
`Layout.preferredWidth: 0` on a child that's still `visible: true` does NOT achieve the
same exclusion - the layout still reserves one spacing-gap for it. If a wrapper needs to
be hidden for multiple independent reasons (not enabled, not enough room, ...), combine
them into ONE `visible` expression on that wrapper rather than splitting the logic across
an inner component's visibility and an outer `Layout.preferredWidth` hack.

### `Repeater.itemAt(...).someProperty` doesn't reliably track custom properties

Reading a property through `Repeater.itemAt(index).someProperty`, called from inside
another property's binding evaluation, does not reliably register as a tracked
dependency for that outer property - at least for custom QML-declared (JS-computed)
properties on the delegate. Native, C++-backed properties a type explicitly mirrors (e.g.
`Loader.implicitWidth`, forwarded from the loaded `item` with a proper NOTIFY signal) DO
propagate reliably through the same access pattern.

If you need to PULL a live value through `itemAt()` from another property's computation,
only do it for native-mirrored properties. For a custom property, have the delegate PUSH
its own value into a plain `property var` map on the parent instead
(`var m = Object.assign({}, root._map); m[id] = newValue; root._map = m;`), and read that
map directly - a same-object property read, which QML always tracks reliably.

### "Binding loop detected" is a real reentrancy guard, not noise

It fires when the engine detects a property already mid-evaluation on the call stack and
something tries to read/re-enter it. Qt doesn't recurse or crash - it silently returns the
property's LAST CACHED VALUE and aborts the nested evaluation, which can leave that
property stale across multiple further, unrelated dependency changes. Treat any instance
of this warning as a real dependency cycle to find and remove at the source. Don't assume
a value "still ends up correct" just because the warning stops appearing.

### A `Loader`'s own `visible` and its loaded item's `visible` are independent

A `Layout` that manages a `Loader` as a direct child only consults the LOADER's own
`visible` for sizing/spacing - it does not look through to a deeply-nested descendant's
self-managed `visible`. If a loaded widget hides itself internally (backing
hardware/service unavailable) but the wrapping Loader's `visible` isn't also tied to that
same condition, the Layout still reserves full space for the now content-less Loader.
Make whatever decides the outer wrapper's `visible` either the single source of truth for
ALL exclusion reasons, or keep it reliably in sync with the loaded item's own
self-reported state.

---

## 2. Container-aware (responsive) widgets

Several widgets (`WeatherDisplay`, `WeatherReport`, `PanelHeader`, `SysTray`) size or
reflow themselves based on the space they're actually given, rather than the screen or a
guessed constant. Two rules keep this from becoming circular or arbitrary:

- **`implicitWidth`/`implicitHeight` must have zero dependency, even indirect, on any
  breakpoint derived from the widget's own laid-out `width`/`height`** (e.g. a `compact`
  or `narrow` flag). Measure the FULLY-EXPANDED content size unconditionally (with
  `TextMetrics`, or by reading a child's own `implicitWidth` before any compacting is
  applied), and derive `implicitWidth`/`implicitHeight` from that measurement, never from
  a state that depends on the current `width`. Otherwise you get the same two-stable-
  points binding loop as the `visible` pitfall above, just one level removed.
- **Breakpoints should come from the content's own measured needs, not a tuned pixel
  constant** where possible (e.g. "the width needed to show icon+temp+condition without
  humidity" rather than a guessed `180`). A hardcoded threshold has no relationship to
  what the content actually needs once fonts/scale change; a measured one still holds.

A widget's `width`/`height` bindings should stay permanently bound to an
auto-vs-override expression (`override ? overrideSize : content.implicitSize`) rather
than using `Binding { when: overriding }` to force a value and then "release" control
back to auto-sizing - releasing a `Binding` doesn't revert to the previous binding, it
just stops updating, leaving the property stuck at its last forced value.

### Desktop widget fixed-size override

`DesktopWidgetStore.getSize(key)`/`setSize(key, w, h)` store a per-axis fixed size (`0`
on either axis = auto, fall back to that axis's own content-implicit size) alongside each
widget's position. `DesktopWidget.qml` and `DesktopConfigOverlay.qml`'s drag-preview both
read it the same way, so what you configure in the overlay matches what actually renders.
