# serez-ui

React-style UI library for [Serez-Code](https://serezcode.org). 24 built-in components, a
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

## Quick use

A component is a class that **extends `Window`** and returns JSX from `render()`. State lives in
`this` fields; mutating it inside an event handler re-renders through the Virtual DOM (diff + patch).

- `render()` — override; returns the VNode tree (JSX).
- `styleVars()` — override; exposes state to the reactive CSS (`.szs`).
- `onKey(evt)` / `onMouse(evt)` / `onFrame()` — optional overrides for raw input and per-frame
  work (poll progress, auto-dismiss a `Toast`, animate).
- **Run it**: `app.runGui(title, w, h)` (native window) or `app.runTui()` (terminal). The event
  loop is a method of your component, so `this` stays your live top-level app.
- **JSX**: it lives in `.szx` files; `sz apps/counter.szx` translates to plain `.sz` and runs in
  one step — the web syntax disappears, there is no web runtime.
- **Style**: attach a `.szs` stylesheet (CSS with reactive conditions and `width`/`height` media
  queries) with `app.useStylesheet(parseCss(File.read("counter.szs")))` before `runGui`.
- **Focus marks are opt-in** (v4.4): clicking a widget leaves no ring by default. Declare
  `Input:focus { border-color: #22d3ee }` per widget or a global `*:focus { border: 2px solid #f43f5e }`
  in the `.szs` to mark the focused widget (`:active-focus` is an accepted alias).
- **Secondary windows**: `openPanel(title, w, h)` opens extra native windows whose content comes
  from your `renderPanel(id)` override. Since v4.4 each panel carries its **own full input state**
  — focus, caret/selection, editable `Input`/`Textarea`, `Dropdown`, undo — isolated from the main
  window; the keyboard follows whichever window has OS focus. `closePanel(id)` is safe to call
  from a panel's own callbacks.
- **Responsive by default**: the GUI reflows on resize, block text word-wraps, and content taller
  than the window scrolls with the mouse wheel. For structural changes read `app.breakpoint()`
  (`"sm"`/`"md"`/`"lg"`) inside `render()`.
- `app.useNativeRenderer(true)` (before `runGui`, core ≥ 9.2) opts into the core's native
  layout/CSS/paint engine — same components, same `.szs`, much faster. With core ≥ 9.3 both
  renderers are at visual parity: class selectors, color/`font-scale`/`opacity` inheritance,
  multi-value `padding`, `width` in px/%, `overflow: scroll` clipping, `line-height`,
  `white-space: nowrap`, custom `:font` families and `position: absolute` badges render the same
  on both paths.

## Documentation

The full reference lives on the Serez-Code site:

- **[Component catalog](https://serezcode.org/docs/serez-ui/components)** — the 24 built-in
  components (`Button`, `Input`, `Textarea`, `Select`, `Dropdown`, `Checkbox`, `RadioGroup`,
  `Slider`, `ProgressBar`, `Label`, `Link`, `Row`/`Col`, `Image`, `Table`, `Modal`, `Tooltip`,
  `Toast`, `Chart`, `Switch`/`Toggle`, `Tabs`, `Collapsible`/`Accordion`, `FileInput`,
  `DropZone`) with props, keyboard behavior and examples.
- **[serez-ui guide](https://serezcode.org/docs/serez-ui)** — the component model, the
  `.szx` → `.sz` JSX translator, focus & keyboard navigation, OS events (file drag-drop,
  gestures), secondary windows (panels), retained-mode and the native renderer, and the complete
  API surface.
- **[`.szs` reference](https://serezcode.org/docs/serez-ui/szs)** — CSS with logic: reactive
  conditions against `styleVars()`, `width`/`height` media queries, the supported property table,
  and custom fonts (`:font` + `font-family`). Conditions combine with `and` / `or` / `not`
  (media-query style; `&&` / `||` / `!` are accepted aliases), with the usual precedence —
  `not` binds tighter than `and`, and `and` tighter than `or`:

  ```css
  body  (width > 600 and flag == true)  { background-color: #c12; }
  .item (selected or hovered)           { border-color: #3b82f6; }
  .row  (not hidden)                    { display: flex; }
  ```
- **[Build a GUI app](https://serezcode.org/guides/gui-app)** — step-by-step tutorial from
  `sz install` to a working desktop app.

## Permissions

`serez.json` declares the permissions the library needs:

```json
{ "permissions": ["Env", "Terminal", "Gui"] }
```

`Terminal` for the TUI loop (raw mode, keyboard, mouse), `Gui` for the native window.

## Packaging

Ship a serez-ui app as a self-contained `.exe` / `.msi` (the runtime travels inside, no Serez-Code
needed on the target machine) with [serez-pack](https://serezcode.org/docs/serez-pack).

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
