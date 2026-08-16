# serez-ui

React-style UI library for [Serez-Code](https://serezcode.org). 24 built-in components, a
transparent Virtual DOM, and hooks — the **same component** runs in the terminal (TUI) or in a real
native window (GUI). Written in pure `.sz`; the JSX layer (`.szx`) compiles away entirely (no web
runtime). Requires Serez-Code **≥ 9.17.0**.

> **The version floor is real, not a formality.** On an older core the library still *loads* and
> then misbehaves without saying so: a `Window` subclass without a constructor dies at `mount()`
> with `has no field or method named 'effects'` (implicit `super()` landed in core 9.17),
> `useEffect` re-runs `deps []` on every update and never runs cleanups (fixed in 9.16), and
> components living in separate `.szx` files fail at render time with `Unknown class or interface`
> (fixed in 9.15). Check with `sz --version`.

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
- **Child → parent callbacks**: pass a method *without* parentheses and the child invokes it —
  `<TaskRow onPick={this.pick} />` in the parent, `onClick={this.props.onPick}` in the child.
  `this.pick` is a reference bound to the parent, so calling it mutates the parent's state.
  Wrapping it (`onPick={() => this.pick()}`) works too, and is what you need when the child
  supplies no arguments but your method takes some. Requires a core with method references
  (older cores *ran* the method on read instead of referencing it).
- `onKey(evt)` / `onMouse(evt)` / `onFrame()` — optional overrides for raw input and per-frame
  work (poll progress, auto-dismiss a `Toast`, animate). `onKey` fires in **both** loops (v4.26;
  before that it only reached TUI apps): `evt.code` is a key name (`"Enter"`, `"Esc"`, `"Tab"`) or
  a single character, the same shape in the terminal and in a window, so one handler covers both.
  In GUI it runs *alongside* the focused widget, not instead of it — the widget still receives the
  keystroke.
- **Conditional and list children work anywhere** (v4.26): `{cond && <X/>}` and `{items.map(...)}`
  behave identically inside a built-in (`Row`, `Col`, `Modal`, …) and inside a plain tag. Until
  4.26 the built-ins skipped child flattening, so a false condition left a stray `false` painted on
  screen and a `.map()` left a nested array — only inside a built-in, which made it look random.
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
- **Pseudo-states everywhere** (v4.10): `:hover`, `:focus`, `:active` and `:disabled` accept **any**
  property on **any** element, not a fixed subset — and `border-radius` resolves per node
  (tag, class, id or state), so fills, outlines, containers, controls and images all round
  consistently.
- `app.useNativeRenderer(true)` (before `runGui`, core ≥ 9.2) opts into the core's native
  layout/CSS/paint engine — same components, same `.szs`, much faster. **With core ≥ 9.11 the two
  renderers are at full CSS parity** (v4.21): on top of the earlier set (class selectors,
  `color`/`font-scale`/`opacity` inheritance, multi-value `padding`, `width` in px/%,
  `overflow: scroll`, `line-height`, `white-space: nowrap`, `:font` families and
  `position: absolute`), the interpreted renderer caught up on:

  | Group | Properties |
  |---|---|
  | Box | `margin`, `border-width`, `min-width`/`max-width`, `box-shadow` |
  | Flex / grid | `justify-content`, `align-items`, `row-gap`, `display: grid`, `grid-template-rows` |
  | Text | `font-size` in **real px** (text and interactive widgets), `letter-spacing`, `text-decoration`, `text-transform` |
  | Paint | `background-image`, `z-index`, `position: relative`, `cursor` |
  | Transform | `translate`, `rotate`, `scale` |

  Real-px `font-size` and `transform` need the core primitives `Gui.nodeTextPx` and
  `Gui.nodeTransform` (core ≥ 9.10 / ≥ 9.11); on an older core those rules simply don't apply.

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

  There are no grouping parentheses — the sheet scanner closes the condition at the first `)`.
  Note that composite conditions need a core that also understands them: under
  `useNativeRenderer(true)` the stylesheet is handed to the core's own CSS engine, and on an
  older core those rules simply don't apply. The default (interpreted) renderer works on any
  supported core.

  Group many rules under **one** shared condition with **`@when` blocks** — a single logic gate
  for several selectors (tags, `.classes`, `#ids`), so you don't repeat the condition rule by
  rule. The query is the same `.szs` logic (a `styleVars()` variable, or `width`/`height`), not
  just a media query. **`@else`** is the complement of the preceding `@when`, and **`@else (cond)`**
  chains else-if; the branches are mutually exclusive (first match wins), so there's no need to
  negate ranges by hand:

  ```css
  @when (width < 300 and darkMode) {
      body   { color: #fff }
      .card  { padding: 8 }
      #main  { gap: 4 }
  }

  @when (width < 200) { body { color: #100 } }
  @else (width < 400) { body { color: #200 } }
  @else               { body { color: #300 } }
  ```

  Blocks nest (`@when` inside `@when` — conditions are AND-ed) and a rule inside a block may keep
  its own `(cond)`, combined with the block's. `@else` negates the *whole* preceding condition, so
  composites like `(a or b)` complement correctly. Unknown at-rules (`@media`, …) are discarded.
  The same core-parity note applies under `useNativeRenderer(true)`.
- **[Build a GUI app](https://serezcode.org/guides/gui-app)** — step-by-step tutorial from
  `sz install` to a working desktop app.

## Coming from React?

Most of what you already type works. These are the differences worth knowing on
day one:

| React | serez-ui |
|---|---|
| `className="x"` | `class="x"` — `className` is accepted and renamed for you |
| `style={{color:'red'}}` | not supported; styling lives in a `.szs` sheet (you get a warning if you try) |
| `useState` | state is a plain field: `this.count = 0`, mutate it in a handler |
| `useEffect(fn, [x])` | `useEffect(fn, () => [x])` — deps go as a **function**, see below |
| `key={id}` | accepted and ignored (reconciliation is by index) |
| `{/* comment */}` | works |
| `{...props}` | works, including `{...this.props}` |
| `<><A/><B/></>` | works |
| `constructor` optional | optional too — the parent constructor chains on its own (core ≥ 9.16) |

**Why deps are a function.** In React the whole component body re-runs on every
render, so `[x]` is re-evaluated each time. Here an effect is registered **once**
with `addEffect`, so an array literal freezes at the value it had then — the
"run when x changes" mode silently never fired. Passing `() => [x]` re-evaluates
it on every pass, which is the behaviour you expect:

```jsx
this.addEffect(useEffect(() => {
    this.buscar(this.id)
}, () => [this.id]))     // ← función, no array
```

**Where state lives.** A `Window` holds the state; `Component`s are presentational
and take props. That is the one structural habit to change — see the limits below.

## Known limits

Worth knowing before you design around them:

- **`key` is accepted and ignored.** Reconciliation compares children **by index**. Writing
  `key={x.id}` costs nothing and does nothing. The reason it isn't wired up: the diff is a *change
  detector*, not an incremental patcher — the renderer repaints the whole tree whenever the patch
  list is non-empty, and nothing ever reads a patch's contents. Under key matching a pure reorder
  produces *no* patches, so the screen would stop repainting. Keys only pay off once the renderer
  applies patches; see the header of `src/diff.sz`.
- **A closure created in a constructor keeps a cell to that object.** Registering effects or
  callbacks in the constructor works (core ≥ 9.16), but if the component is later *copied* — pushed
  into an array, stored in another object's field, or returned from a function — the copy is a
  different object and the closure still writes to the original. Build it, bind it to a variable,
  and use it from there.
- **Instances of `Component` are ephemeral**, recreated every frame. Keep state in the parent
  `Window` and pass it down as props; a `Component`'s own fields do not survive a re-render.

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
