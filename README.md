# serez-ui

**v2.2.0** · React-style UI library for [Serez-Code](../Serez-code). 24 built-in components, a
transparent Virtual DOM, and hooks — the **same component** runs in the terminal (TUI) or in a real
native window (GUI). Written in pure `.sz`; the JSX layer (`.szx`) compiles away entirely (no web
runtime). Requires Serez-Code **≥ 7.2.0**.

```sz
import "serez-ui"

class Counter:Window {
    public Counter() { super(); this.count = 0 }

    public render() {
        return (
            <div>
                <h1>Counter</h1>
                <hr />
                <h2>{this.count}</h2>
                <Button onClick={() => { this.count = this.count + 1 }}>Increment</Button>
                <Button onClick={() => { this.count = 0 }}>Reset</Button>
            </div>
        )
    }
}

let app = new Counter()
app.runGui("Counter", 520, 420)   // or: app.runTui() for the terminal
```

## Install

```powershell
sz install serez-ui
```

## The model

A component is a class that **extends `Window`** and returns JSX from `render()`. State lives in
`this` fields; mutating it inside an event handler re-renders through the Virtual DOM (diff + patch).

- `render()` — override; returns the VNode tree (JSX).
- `styleVars()` — override; returns `[[name, value], …]` exposed to the reactive CSS (`.szs`).
- `onKey(evt)` / `onMouse(evt)` — optional overrides for raw input.
- `onFrame()` — optional override called once per GUI frame (even without input); do periodic
  work here (poll progress, auto-dismiss a `Toast`, animate) and return `true` to request a
  redraw. The loop doesn't sleep, so **throttle inside** (gate on a clock). In text fields,
  `Ctrl+C` / `Ctrl+V` / `Ctrl+X` use the system clipboard; hovering interactive elements shows
  a hand cursor.
- Run it: `app.runGui(title, w, h)` (native window) or `app.runTui()` (terminal). The event loop
  is a method of your component — it must run with `this` = your top-level app (see note below).
- The GUI **reflows on resize** (autosize): full-width controls stretch/shrink to the window. Cap
  the content with `app.setMaxWidth(px)` / `app.setMinWidth(px)` (`0` = no limit); the content is
  centered when `max-width` is narrower than the window. Call before `runGui`.
- For **structure** that changes with size, read `app.viewportWidth()` / `app.breakpoint()`
  (`"sm"`/`"md"`/`"lg"`; thresholds via `app.setBreakpoints(smMax, mdMax)`, default `600`/`960`)
  inside `render()` — the GUI re-runs `render()` on resize, so you can return a different tree per
  breakpoint (e.g. a `Row` of links on desktop, a single menu button on phones).
- Content taller than the window **scrolls vertically** with the mouse wheel (a thin scrollbar
  appears on the right) — automatic, no config.
- Lifecycle (handled by the run methods): `mount()`, `update()`, `unmount()`.

## `.szx` → `.sz` (the JSX translator)

JSX lives in `.szx` files and is translated to plain `.sz` before running. `sz` does both in one step:

```powershell
sz apps/counter.szx
```

Under the hood: `translate.sz` turns `<tag …>` into `h("tag", props, children)`. The web syntax
**disappears** in translation — the resulting `.sz` has no web runtime.

## Built-in components

Structure uses primitive HTML-like tags the renderer draws directly: `div, h1, h2, h3, p, span,
hr, ul, li, section, form`. Block text (`h1`/`h2`/`h3`/`p`/`span`/`li`/`Label`) **word-wraps** to
the available width and reflows on resize. Layout containers `Row` (children side by side, each at its content
width, with a gap — and it **stacks them vertically when they no longer fit**, unless you set
`wrap={false}`) and `Col` (vertical, like `div`) handle horizontal layout. For interaction:

| Component     | Props | Notes |
|---------------|-------|-------|
| `Button`      | `onClick`, `disabled` | Text is the children · Enter/Space activates when focused |
| `Input`       | `value`, `placeholder`, `type`, `onChange`, `onSubmit`, `disabled` | One line · positionable caret, `type="password"` masks, Enter → `onSubmit` |
| `Textarea`    | `value`, `placeholder`, `rows`, `onChange`, `disabled` | Multi-line · caret + vertical scroll, Enter inserts a newline |
| `Select`      | `value`, `options`, `onChange`, `disabled` | Click / ←→ cycles options |
| `Dropdown`    | `value`, `options`, `onChange`, `disabled` | Real drop list · click or Enter opens, ↑↓ navigate, Enter picks |
| `Checkbox`    | `checked`, `label`, `onChange`, `disabled` | Click or Space toggles |
| `RadioGroup`  | `value`, `options`, `onChange`, `disabled` | One choice · click an option or ↑↓ to move |
| `Slider`      | `value`, `min`, `max`, `step`, `onChange`, `disabled` | Click the track or ←→ to change |
| `ProgressBar` | `value`, `max`, `label` | Non-interactive (skipped by focus) |
| `Label`       | — | Caption text (children); non-interactive |
| `Link`        | `href`, `onClick`, `disabled` | Underlined accent · click or Enter activates |
| `Image`       | `src`, `bytes`, `width`, `height`, `alpha`, `alt` | Raster image (PNG/JPG) from a file (`src`) **or from bytes in memory** (`bytes`, e.g. a fetched image); scales to `width`/`height`, `alpha` fades; `alt` shows if it can't load |
| `Table`       | `columns`, `rows` | Read-only grid (aligned cells, header row) — response headers, metrics, key/value |
| `Modal`       | `open`, `title` | When `open`, dims the background (alpha scrim) and centers a box with the children **on top**, capturing clicks/focus |
| `Tooltip`     | `tip` | Wraps a child; shows a small box with `tip` next to the cursor on hover |
| `Toast`       | `message`, `kind` | Transient banner (`info`/`success`/`warn`/`error`); auto-dismiss it from `onFrame()` |
| `Chart`       | `data`, `type` (`line`/`area`/`bar`), `height`, `color`, `min`, `max`, `dots` | Plots a numeric series with the core vector primitives; non-interactive (sparkline in TUI) |
| `Switch` / `Toggle` | `checked`, `label`, `onChange`, `disabled` | On/off pill switch (same semantics as `Checkbox`); click or Enter/Space toggles |
| `Tabs`        | `tabs`, `active`, `onChange`, `disabled` | Controlled tab bar — draws the strip; **you** render the content per `active`; click or ←→, active underlined |
| `Collapsible` / `Accordion` | `title`, `open`, `onToggle`, `disabled` | Collapsible section — a header (with a chevron) that shows/hides its **children**; click or Enter/Space toggles |
| `FileInput`   | `onChange`, `value`, `label`, `filterName`, `exts`, `save`, `defaultName` | "Choose file…" button → native file dialog; `onChange(path)`, shows the picked file name · Enter/Space opens |
| `DropZone`    | `onDrop`, `label`, `height` | Drop area for OS file drag-drop; highlights while files hover over the window, `onDrop(paths)` on drop |

```sz
<Input value={this.name} placeholder="your name" onChange={(v) => { this.name = v }} />
<Textarea value={this.bio} rows={4} onChange={(v) => { this.bio = v }} />
<Select value={this.mode} options={["fast", "normal", "slow"]} onChange={(v) => { this.mode = v }} />
<Dropdown value={this.lang} options={["es", "en", "fr"]} onChange={(v) => { this.lang = v }} />
<Checkbox checked={this.agreed} label="I agree" onChange={(b) => { this.agreed = b }} />
<RadioGroup value={this.size} options={["S", "M", "L"]} onChange={(v) => { this.size = v }} />
<Slider value={this.vol} min={0} max={100} step={5} onChange={(v) => { this.vol = v }} />
<ProgressBar value={this.vol} max={100} label="level" />
<Switch checked={this.dark} label="Dark mode" onChange={(b) => { this.dark = b }} />
<Chart data={[3, 7, 4, 9, 6, 11, 8]} type="area" height={140} dots={true} />
<Row>
    <Button onClick={save} disabled={!this.canSave}>Save</Button>
    <Button onClick={clear}>Clear</Button>
</Row>

// Tabs draw the strip; you render the panel for the active index:
<Tabs tabs={["Info", "Config", "Logs"]} active={this.tab} onChange={(i) => { this.tab = i }} />
{ this.tab == 0 ? <Info /> : this.tab == 1 ? <Config /> : <Logs /> }

// Collapsible: a header that shows/hides its children (stack a few for an accordion):
<Collapsible title="Details" open={this.open} onToggle={(o) => { this.open = o }}>
    <p>Hidden until the section is expanded.</p>
</Collapsible>

// Files: a native picker button, and a drag-drop area (both need the File permission to read):
<FileInput exts="json" filterName="JSON" onChange={(p) => { this.path = p }} />
<DropZone label="Drop files here" onDrop={(paths) => { this.files = paths }} />

// An image fetched over the network (bytes), drawn scaled — cached by `src` (the URL):
let r = fetch(url, ({"binary", true}))
<Image src={url} bytes={r} width={200} />
```

## Focus & keyboard (GUI)

Every interactive component is **focusable** and gets a focus index in render order. The focused
element shows a ring (text fields highlight their border and draw the caret).

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Move focus to the next / previous component |
| click | Focus that component (and, in a text field, place the caret under the cursor) |
| `←` `→` `Home` `End` | Move the caret (text fields) · change value (Select / Slider) · switch tab (`Tabs`) |
| `Backspace` / `Delete` | Delete before / at the caret (auto-repeat when held) |
| `Enter` / `Space` | Activate the focused Button / Link / Checkbox / Switch / Dropdown · open the dialog (`FileInput`) |
| `Enter` | Newline in a Textarea · `onSubmit` in an Input |
| `↑` `↓` | Navigate options in an open Dropdown / a RadioGroup |
| `Esc` | Close the window |

> Text is drawn with real glyphs on a monospace grid (the core rasterizes a font, so `ñ á é í ó ú
> ¿ ¡` and Unicode like `→` render). Typing goes through your **OS keyboard layout and IME**, so
> accented characters can be typed straight into `Input` / `Textarea` — no programmatic workaround.
> A CJK **IME composition** in progress is drawn underlined at the caret. When the window **loses
> OS focus** the caret stops blinking (and the loop idles), so a background window costs ~0 CPU.

## OS events (drag-drop, gestures)

The GUI surfaces a few window-level OS events as **optional `Window` overrides** (all default to
no-op; return `true` from a handler to request a redraw). The `DropZone` / `FileInput` components
cover the common cases, but you can also handle them directly:

```sz
public bool onFilesDropped(any paths) {        // files dropped on the window (needs File perm to read)
    this.attached = paths
    return true
}
public bool onFilesHovered(any paths) { … }    // files dragged over the window (before dropping)
public bool onPinch(any delta)        { … }    // trackpad pinch/zoom (delta > 0 in, < 0 out)
public bool onTouch(any touches)      { … }    // touchscreen points: flat [id, phase, x, y, …]
```

`app.hoveredFiles()` returns the paths currently being dragged over the window (or `[]`), so a
component can read it from `render()` to highlight a drop target — which is exactly what `DropZone`
does. (winit doesn't report the drop *position*, so with several `DropZone`s the drop routes to the
one under the mouse, or the first.)

## TUI and GUI

The same component runs in two renderers — the event loop is a **method of your component**
(`app` is your top-level variable):

```sz
// Terminal (TUI) — Unicode drawing, keyboard + mouse
app.runTui()                     // quit with q

// Native window (GUI) — pixels via the core Gui backend
app.runGui("My App", 560, 460)   // quit with Esc or the close button
```

> **Why a method and not `new GuiEventLoop(app)`?** serez-code copies objects by value, so an
> external loop holding the app in a field would mutate a throwaway copy (empty window / no
> reaction). Running the loop as a method keeps `this` = your live top-level component.
> `GuiEventLoop` / `EventLoop` still exist as deprecated shims that point you here.

### Retained-mode rendering (core ≥ 7.3)

The GUI renderer no longer rasterizes in `.sz`: it emits **persistent scene nodes**
(`Gui.node*`) with positional reuse — a primitive whose type and values didn't change since
the last frame costs **zero Gui calls**, and the frame is presented with `Gui.renderScene()`,
which skips rasterizing entirely when nothing changed (dirty-skip) and otherwise redraws in
Rust. Nothing changes in your components: same `render()`, same `.szs`, same output — idle
frames and mostly-static frames just got much cheaper. (The heavy lifting lives in the `sw*`
methods of `GuiRenderer`.)

### Secondary windows (panels)

A running `runGui` app can open extra native windows ("panels") whose content is a method of
**the same component** — so handlers mutate your app state directly:

```sz
class App:Window {
    public bool onFrame() {
        if (!this.opened) { this.opened = true; this.openPanel("Herramientas", 340, 220) }
        return false
    }
    public any renderPanel(int id) {
        return h("div", [], [
            h("h2", [], ["Panel " + id]),
            h("Button", [["onClick", () => { this.clicks = this.clicks + 1 }]], ["Sumar"])
        ])
    }
}
```

- `openPanel(title, w, h) -> id` / `closePanel(id)` / `panelCount()` — requires `runGui` running.
- `renderPanel(id)` returns the panel's vdom (`null` = empty panel). It re-renders every frame
  with its **own renderer and its own retained scene** (the core keeps one scene per window).
- v1 input: panels route `Button`/`Link` clicks (per-window, event-accurate edge from the core —
  a short click between two frames is never lost). Text editing (Input/Textarea focus) lives in
  the main window for now.
- Closing a panel with the OS `X` just removes it from the app (the main loop keeps running).

> **Semantics notes (core ≥ 7.3):** two old gotchas are gone — closures now share the captured
> variable with the enclosing scope at ANY nesting level (cell semantics; counters work), and a
> parameter named like a function (`h`, …) no longer shadows it in CALLS. Naming params `width`/
> `height` instead of `w`/`h` remains good hygiene, but it is no longer load-bearing.

### Native renderer (core ≥ 9.2, experimental)

Retained-mode removed the *rasterizing* cost, but layout and CSS matching still ran interpreted.
The native renderer hands those to the core too: every component is **lowered to HTML-like
primitives** (`div`/`row`/`p`/`textbox`/…) and `Gui.renderTree` resolves the `.szs`, lays out
and rebuilds the scene **in Rust** — measured ~1000× faster on that phase for app-sized trees.
All 24 built-in components work under this path (clicks, focus order, overlays and text editing
included) and your components and `.szs` don't change:

```sz
let app = new MyApp()
app.useNativeRenderer(true)   // opt-in — call before runGui()
app.runGui("My App", 800, 600)
```

Off by default while the path matures. Known gaps vs the interpreted renderer: descendant
`.szs` selectors (`.a .b`, used by some focus rings) are inert, and `Slider` drags by
click-to-set + keyboard (no continuous drag yet). Both renderers draw the same UI from the
same source — flip the flag off and you are back on the classic path.

## CSS with logic (`.szs`)

Style with a CSS dialect that supports **reactive conditions**. A selector can carry a condition
evaluated against the state exposed by `styleVars()`:

```css
/* counter.szs */
:import {
    count: count;
}

body (count == 0) { background-color: #0f172a; }
body (count != 0) { background-color: #14532d; }

h1     { color: #ffd166; }
Button { background-color: #2563eb; color: #ffffff; }
```

```sz
app.useStylesheet(parseCss(File.read("apps/counter.szs")))   // before app.runGui(...)
```

The component exposes its state to the sheet via `styleVars()`:

```sz
public any styleVars() { return [["count", this.count]] }
```

### Responsive (`.szs` media queries)

The current `width` and `height` (px) are always available as condition variables — no
`:import` needed — so a stylesheet can adapt the UI to the window size and reflows live on resize:

```css
body (width < 600)  { background-color: #1e1b4b; }   /* phone-ish */
body (width >= 600) { background-color: #0f172a; }

Row (width < 600)   { direction: column; }            /* stack the row when narrow */

h1  (width < 600)   { font-scale: 2; }                /* smaller heading on small screens */
h1  (width >= 960)  { font-scale: 4; }
```

Properties the renderer reads today (the parser accepts any `property: value`; unknown ones are
ignored):

| Property | Applies to | Values |
|----------|-----------|--------|
| `background-color` | body, Button, Input, Select, Checkbox, Dropdown, Textarea, Switch, Tabs, Chart (series color) | hex / name |
| `color` | text tags + controls | hex / name |
| `direction` | `Row` | `column` (stack vertically) |
| `font-scale` | h1/h2/h3/p/span/li | integer (text-size multiplier) |
| `white-space` | h1/h2/h3/p/span/li | `nowrap` (one line, may clip) |
| `text-align` | h1/h2/h3/p/span/li/Label | `left` / `center` / `right` |
| `padding` | containers (div, Col, section, form, ul) | integer px (inner spacing) |
| `margin-bottom` | any tag | integer px (extra space below) |
| `gap` | `Row` | integer px (space between children) |
| `display` | any tag | `none` (hide the element) |
| `font-family` | text tags + controls (set it on `body` for the whole app) | family name or `:font` alias |
| `border-radius` | Button, Input, Textarea, Select, Dropdown, ProgressBar | integer px (rounded corners) |

Sizes are plain integers (pixels) — no `px` unit.

### Fonts (`:font` + `font-family`)

By default — with no `font-family` set — the UI uses a modern system stack: **Segoe UI**
(proportional) for text and controls, and **Cascadia Mono** (falling back to Consolas) for
`Input`/`Textarea`; if neither is installed it falls back to the core's monospace grid. Override it
per tag (or on `body` for the whole app). Declare font files in a `:font` block (loaded lazily by
the renderer) and pick families per tag — system-installed fonts work by name without any block.
Custom families render **proportionally** (real glyph advances); `Input`/`Textarea` text stays
monospace so the caret math holds.

```css
:font {
    Titular: fonts/Georgia.ttf;        /* alias: path to a .ttf/.otf (e.g. a Google Font) */
}

body { font-family: "Segoe UI"; }      /* default for the whole app (system font) */
h1   { font-family: "Titular"; }       /* the :font alias */
```

Any of these can carry a condition — `Button (width < 600) { font-scale: 1; }` — re-checked each
frame against `styleVars()` plus the built-in `width`/`height`.

## API surface

| Export | What it is |
|--------|------------|
| `Window` | Base class for components |
| `h` / `VNode` | Hyperscript + Virtual DOM node |
| `diff` / `Patch` | Virtual DOM diffing |
| `useState` / `useEffect` / `memo` | Hooks |
| `app.runTui()` / `app.runGui(title, w, h)` | Window methods — run the app in the terminal / a native window |
| `app.useStylesheet(sheet)` | Window method — attach a `.szs` stylesheet (before `runGui`) |
| `app.setMaxWidth(px)` / `app.setMinWidth(px)` | Window methods — clamp the GUI content width (`0` = no limit; centers under max-width) |
| `app.viewportWidth()` / `app.breakpoint()` | Window methods — live viewport width (px) / current breakpoint (`sm`/`md`/`lg`) for a responsive `render()` |
| `app.setBreakpoints(smMax, mdMax)` | Window method — set the `sm`\|`md` and `md`\|`lg` width thresholds (default `600` / `960`) |
| `app.onFrame()` | Window override — per-frame hook; return `true` to redraw |
| `app.onFilesDropped(paths)` / `onFilesHovered(paths)` | Window overrides — OS file drag-drop (dropped / hovering) |
| `app.onPinch(delta)` / `onTouch(touches)` | Window overrides — trackpad pinch / touchscreen points |
| `app.hoveredFiles()` | Window method — paths being dragged over the window right now (`[]` if none) |
| `app.openPanel(title, w, h)` / `closePanel(id)` / `panelCount()` | Window methods — secondary native windows (see panels) |
| `app.renderPanel(id)` | Window override — vdom of panel `id` (`null` = empty) |
| `app.useNativeRenderer(b)` | Window method — render through the core's primitives engine (experimental, core ≥ 9.2; before `runGui`) |
| `Renderer` / `GuiRenderer` | TUI / GUI renderers (used internally by the run methods) |
| `parseCss` | `.szs` stylesheet parser |

## Permissions

`serez.json` declares the permissions the library needs:

```json
{ "permissions": ["Env", "Terminal", "Gui"] }
```

`Terminal` for the TUI loop (raw mode, keyboard, mouse), `Gui` for the native window.

## Packaging

Ship a serez-ui app as a self-contained `.exe` / `.msi` (the runtime travels inside, no Serez-Code
needed on the target machine) with [serez-pack](../serez-pack).

## Repo structure

```
serez-ui/
  index.sz             public entry — re-exports the whole API
  src/
    vnode.sz h.sz      Virtual DOM node + hyperscript
    diff.sz patch.sz   diffing + patching
    state.sz effect.sz memo.sz   hooks
    window.sz          Window base class + the GUI/TUI event loops (runGui/runTui)
    components.sz      Button, Input, Textarea, Select, Dropdown, Checkbox,
                       RadioGroup, Slider, ProgressBar, Label, Link, Row, Col,
                       Image, Table, Modal, Tooltip, Toast, Chart, Switch/Toggle,
                       Tabs, FileInput, DropZone
    renderer.sz events.sz   TUI renderer + event helpers
    renderer_gui.sz    GUI renderer (pixels via the core Gui backend)
    event_loop.sz gui_event_loop.sz   deprecated loop shims → app.runTui/runGui
    css.sz             .szs parser (CSS with logic)
    layout.sz          flexbox layout engine
  tools/
    translate.sz       .szx → .sz translator (run a .szx directly with `sz file.szx`)
  apps/                demos (counter, form, todo, gui_form, …)
  Propuesta.md         design contract
```
