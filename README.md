# serez-ui

**v1.0.0** · React-style UI library for [Serez-Code](../Serez-code). Components, a transparent
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
hr, ul, li, section, form`. For interaction there are five form components:

| Component  | Props | Notes |
|------------|-------|-------|
| `Button`   | `onClick`, `disabled` | Text is the children |
| `Input`    | `value`, `placeholder`, `type`, `onChange`, `disabled` | `type="password"` masks |
| `Select`   | `value`, `options`, `onChange`, `disabled` | Click cycles options |
| `Checkbox` | `checked`, `label`, `onChange`, `disabled` | Click toggles |
| `Textarea` | `value`, `placeholder`, `rows`, `onChange`, `disabled` | Multi-line |

```sz
<Input value={this.name} placeholder="your name" onChange={(v) => { this.name = v }} />
<Select value={this.mode} options={["fast", "normal", "slow"]} onChange={(v) => { this.mode = v }} />
<Checkbox checked={this.agreed} label="I agree" onChange={(b) => { this.agreed = b }} />
<Button onClick={save} disabled={!this.canSave}>Save</Button>
```

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

## API surface

| Export | What it is |
|--------|------------|
| `Window` | Base class for components |
| `h` / `VNode` | Hyperscript + Virtual DOM node |
| `diff` / `Patch` | Virtual DOM diffing |
| `useState` / `useEffect` / `memo` | Hooks |
| `app.runTui()` / `app.runGui(title, w, h)` | Window methods — run the app in the terminal / a native window |
| `app.useStylesheet(sheet)` | Window method — attach a `.szs` stylesheet (before `runGui`) |
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
    components.sz      Button, Input, Select, Checkbox, Textarea
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
