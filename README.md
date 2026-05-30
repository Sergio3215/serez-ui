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

let app  = new Counter()
let loop = new GuiEventLoop(app)   // or: new EventLoop(app) for the terminal
loop.setTitle("Counter")
loop.setSize(520, 420)
loop.start()
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
- Lifecycle (handled by the loops): `mount()`, `update()`, `unmount()`.

## `.szx` → `.sz` (the JSX translator)

JSX lives in `.szx` files and is translated to plain `.sz` before running. The wrapper does both:

```powershell
# Windows
& "tools\szx.ps1" apps\counter.szx

# Linux / macOS
./tools/szx.sh apps/counter.szx
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

The same component runs in two renderers — pick the event loop:

```sz
// Terminal (TUI) — Unicode drawing, keyboard + mouse
let loop = new EventLoop(app)
loop.setQuitKey("q")   // default: q (Esc also quits)
loop.start()

// Native window (GUI) — pixels via the core Gui backend
let loop = new GuiEventLoop(app)
loop.setTitle("My App")
loop.setSize(560, 460)
loop.start()           // quit with Esc or the close button
```

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
loop.setStylesheet(parseCss(File.read("apps/counter.szs")))
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
| `Renderer` / `EventLoop` | TUI rendering + event loop |
| `GuiRenderer` / `GuiEventLoop` | GUI rendering + event loop |
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
    window.sz          Window base class
    components.sz      Button, Input, Select, Checkbox, Textarea
    renderer.sz events.sz event_loop.sz   TUI renderer + loop
    renderer_gui.sz gui_event_loop.sz     GUI renderer + loop
    css.sz             .szs parser (CSS with logic)
    layout.sz          flexbox layout engine
  tools/
    translate.sz       .szx → .sz translator
    szx.ps1 / szx.sh   translate + run wrapper
  apps/                demos (counter, form, todo, gui_form, …)
  Propuesta.md         design contract
```
