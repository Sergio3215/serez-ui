# serez-ui

**v1.3.0** · React-style UI library for [Serez-Code](../Serez-code). Components, a transparent
Virtual DOM, and hooks — the **same component** runs in the terminal (TUI) or in a real native
window (GUI). Written in pure `.sz`; the JSX layer (`.szx`) compiles away entirely (no web runtime).

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
- Run it: `app.runGui(title, w, h)` (native window) or `app.runTui()` (terminal). The event loop
  is a method of your component — it must run with `this` = your top-level app (see note below).
- The GUI **reflows on resize** (autosize): full-width controls stretch/shrink to the window. Cap
  the content with `app.setMaxWidth(px)` / `app.setMinWidth(px)` (`0` = no limit); the content is
  centered when `max-width` is narrower than the window. Call before `runGui`.
- For **structure** that changes with size, read `app.viewportWidth()` / `app.breakpoint()`
  (`"sm"`/`"md"`/`"lg"`; thresholds via `app.setBreakpoints(smMax, mdMax)`, default `600`/`960`)
  inside `render()` — the GUI re-runs `render()` on resize, so you can return a different tree per
  breakpoint (e.g. a `Row` of links on desktop, a single menu button on phones).
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
hr, ul, li, section, form`. Layout containers `Row` (children side by side, each at its content
width, with a gap) and `Col` (vertical, like `div`) handle horizontal layout. For interaction:

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

```sz
<Input value={this.name} placeholder="your name" onChange={(v) => { this.name = v }} />
<Textarea value={this.bio} rows={4} onChange={(v) => { this.bio = v }} />
<Select value={this.mode} options={["fast", "normal", "slow"]} onChange={(v) => { this.mode = v }} />
<Dropdown value={this.lang} options={["es", "en", "fr"]} onChange={(v) => { this.lang = v }} />
<Checkbox checked={this.agreed} label="I agree" onChange={(b) => { this.agreed = b }} />
<RadioGroup value={this.size} options={["S", "M", "L"]} onChange={(v) => { this.size = v }} />
<Slider value={this.vol} min={0} max={100} step={5} onChange={(v) => { this.vol = v }} />
<ProgressBar value={this.vol} max={100} label="level" />
<Row>
    <Button onClick={save} disabled={!this.canSave}>Save</Button>
    <Button onClick={clear}>Clear</Button>
</Row>
```

## Focus & keyboard (GUI)

Every interactive component is **focusable** and gets a focus index in render order. The focused
element shows a ring (text fields highlight their border and draw the caret).

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Move focus to the next / previous component |
| click | Focus that component (and, in a text field, place the caret under the cursor) |
| `←` `→` `Home` `End` | Move the caret (text fields) · change value (Select / Slider) |
| `Backspace` / `Delete` | Delete before / at the caret (auto-repeat when held) |
| `Enter` / `Space` | Activate the focused Button / Link / Checkbox / Dropdown |
| `Enter` | Newline in a Textarea · `onSubmit` in an Input |
| `↑` `↓` | Navigate options in an open Dropdown / a RadioGroup |
| `Esc` | Close the window |

> Text is drawn with real glyphs on a monospace grid (the core rasterizes a font, so `ñ á é í ó ú
> ¿ ¡` and Unicode like `→` render). Typing goes through your **OS keyboard layout and IME**, so
> accented characters can be typed straight into `Input` / `Textarea` — no programmatic workaround.

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

Beyond colors, the sheet understands `direction: column` (lay a `Row` out vertically) and
`font-scale: N` (integer text-size multiplier for `h1`/`h2`/`h3`/`p`/`span`/`li`).

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
                       RadioGroup, Slider, ProgressBar, Label, Link, Row, Col
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
