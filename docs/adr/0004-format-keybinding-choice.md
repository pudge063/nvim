# ADR-0004: Double-Tap `\\` as a Fast Format Keybinding

## Status
Accepted, 2026-08-16

## Context
Formatting on demand was only reachable via `<leader>mp` (Space, then
`m`, then `p`) — a three-keystroke sequence the user found slow for an
action performed frequently (format-now, distinct from format-on-save).
The request was for a faster binding reachable by pressing the same
key twice, mirroring the existing `jk`-for-Escape pattern already in
`lua/config/keymaps.lua`.

Two candidates were evaluated and rejected before landing on the final
choice:
1. **`<leader><leader>`** (double space) — free of conflicts, but
   rejected by the user in favor of a literal same-key-twice binding
   not built on the leader key.
2. **`ll`** (double `l`) — matches "same key twice" literally, but `l`
   is Vim's native cursor-right motion, used constantly and often in
   rapid bursts (`llll`). Mapping `ll` as a chord forces Neovim to wait
   out `timeoutlen` (default 1000ms) after **every single** `l`
   keypress to determine whether a second `l` is coming — meaning
   ordinary rightward cursor movement would gain a perceptible,
   permanent input lag. This was identified and explicitly rejected
   before implementation, not discovered after the fact.

## Decision
`\\` (backslash, pressed twice) is mapped in `lua/plugins/formatting.lua`,
in both normal and visual mode, to the same `conform.nvim` format
action as `<leader>mp`:
```lua
{
    "\\\\",
    function()
        require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
    end,
    mode = { "n", "v" },
    desc = "Format buffer",
},
```
`<leader>mp` is retained unchanged (for which-key discoverability);
`\\` is purely an additional fast path to the same action.

## Rationale
- `\` has no native Vim meaning in normal mode by default and nothing
  in this config's own keymaps binds it (only `<C-\>`, a distinct
  Ctrl-modified combination, is used elsewhere — see the terminal
  toggle documented in the README's "Про `Ctrl+\`" section) — so
  mapping bare `\` (and by extension `\\`) does not shadow any existing
  single-key command the way `l`, `f`, `q`, or `m` would.
- Because plain `\` is not itself a frequently-pressed standalone
  command, the same `timeoutlen`-wait mechanic that makes `ll`
  problematic is a non-issue here: nobody is pressing `\` alone,
  repeatedly, expecting an immediate distinct action each time.
- Keeping `<leader>mp` alongside `\\` (rather than replacing it) costs
  nothing and preserves which-key discoverability for a user who
  doesn't yet know the fast binding exists.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| `<leader><leader>` (double space) | Explicitly rejected by the user — wanted a literal same-key-twice binding independent of the leader key, not a leader-based one. |
| `ll` (double `l`) | `l` is the native rightward cursor motion, pressed constantly including in rapid repeated bursts; chording it would add a `timeoutlen`-length input delay to ordinary cursor movement — identified as a real, daily-annoyance-level regression and rejected before implementation. |
| `qq` (double `q`) | Considered as a safer alternative to `ll` (native `q` starts/stops macro recording, used far less frequently) but not chosen — the user picked `\\` instead when offered both options. |
| Replacing `<leader>mp` entirely instead of adding `\\` alongside it | Would remove which-key discoverability for a user who forgets the fast binding exists; keeping both costs nothing since they dispatch to the identical function. |

## Consequences
### Positive
- Formatting-on-demand is now reachable in two keystrokes of the same
  key, with no added input latency on any other frequently-used
  command.
- No conflict with any existing keymap in this config, verified by
  grepping the full `lua/` tree for other `\`-prefixed bindings before
  implementation (none exist).

### Negative / Risks
- `\` is Vim's default `mapleader` in a stock, unconfigured Vim
  install (this config's actual `mapleader` is set to Space in
  `lua/config/options.lua`, so no live conflict exists here) — a user
  coming from a different, `\`-leader-based Vim config elsewhere might
  find the binding surprising; accepted, since it only affects this
  config's own key namespace, not any Vim default this config already
  overrides.
- Adding further `\`-prefixed bindings in the future needs to check
  this one first (e.g. a single `\x` binding would not conflict, since
  Neovim disambiguates by the full pressed sequence, but two different
  `\\`-prefixed bindings would) — no tooling enforces this, it's a
  manual-review concern noted here for future editors of this config.

## Compliance / Verification
- Verified directly: after adding the mapping, a headless nvim session
  (`require('lazy').setup('plugins')`) confirmed `\\` resolves to the
  format function via `vim.fn.maparg('\\\\', 'n')`.
- No automated test suite covers keybindings in this config; correctness
  is verified manually per-change, as above.

## Related ADRs
- ADR-0003 (formatter toolchain selection) — the formatters this
  keybinding triggers.
