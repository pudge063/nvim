# ADR-0002: Plugin Management via lazy.nvim + Tool Installation via Mason

## Status
Accepted, 2026-08-15

## Context
The config needs a plugin manager (to install/update ~15 Neovim
plugins, pin exact versions for reproducibility across machines) and a
way to install LSP servers and formatters (`pyright`, `ruff`,
`lua_ls`, `stylua`, and later `prettier`/`taplo` — see ADR-0003) that
themselves are not Neovim plugins but standalone binaries/npm
packages. Both need to work non-interactively from `bootstrap.sh`
(headless, `curl | bash`), not just inside an interactive nvim session
a human is driving.

## Decision
**lazy.nvim** is the plugin manager (`lua/config/lazy.lua` bootstraps
it; `lazy-lock.json` pins exact plugin commits and is committed to the
repo). **mason.nvim** + **mason-lspconfig.nvim** +
**mason-tool-installer.nvim** manage LSP servers and formatters as a
separate concern from plugins — `mason-tool-installer`'s
`ensure_installed` list in `lua/plugins/lsp.lua` is the single source
of truth for which external tools must be present
(`pyright, ruff, lua_ls, stylua, prettier, taplo`), and its
`:MasonToolsInstallSync` command is what `bootstrap.sh` calls headlessly
to install them all synchronously.

Headless synchronization does **not** use a bare `+Lazy! sync` ex-command
— `bootstrap.sh` calls `require('lazy').sync({ wait = true, show =
false })` from Lua instead, then separately polls the filesystem for
compiled treesitter parser `.so` files, because `+Lazy! sync` does not
reliably block until post-install build hooks (like
nvim-treesitter's parser compilation) finish, and re-invoking
`nvim-treesitter`'s installer from a second nvim process to force
completion is itself flaky (races the plugin's own module/rtp setup
right after a fresh clone).

## Rationale
- Splitting "plugins" (lazy.nvim) from "external dev tools" (mason)
  keeps each system's version-pinning scoped correctly: `lazy-lock.json`
  pins Neovim plugin *code*, which should track this repo's git
  history; mason-installed tools are *runtime dependencies* whose
  latest version is generally what's wanted (mason itself doesn't
  produce a lockfile-style pin in this config) — conflating the two
  would make it unclear which mechanism owns which upgrade path.
- `mason-tool-installer`'s `ensure_installed` list, rather than
  installing tools ad hoc via `:MasonInstall` per-machine, makes the
  required-tools list an explicit, diffable, version-controlled fact
  about the repo — anyone reading `lsp.lua` sees the complete list of
  external tools this config depends on.
- The Lua-`sync`-plus-filesystem-poll pattern exists specifically
  because headless correctness (bootstrap.sh must not report success
  before parsers actually finished compiling) was observed to fail
  with the more obvious `+Lazy! sync` one-liner — documented in-line in
  `bootstrap.sh` so a future edit doesn't "simplify" it back into the
  broken form.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| A single system for both plugins and tools (e.g. installing pyright/ruff as if they were lazy.nvim plugins via a generic "run this shell command" spec) | lazy.nvim is not designed to manage arbitrary non-plugin binaries; mason already solves exactly this (registry of LSP servers/formatters/linters with per-OS binary resolution) far more robustly. |
| Manual per-tool install instructions in the README instead of `mason-tool-installer` | Not automatable from `bootstrap.sh`, and drifts silently — a machine could be missing a tool with no clear signal until a feature (e.g. yaml formatting) silently doesn't work. |
| Bare `+Lazy! sync` for headless install, accepting the parser-compile race | Produces intermittent bootstrap failures (parsers not ready when nvim is first opened) — unacceptable for a script whose entire purpose is a reliable one-shot setup. |

## Consequences
### Positive
- Exactly one place (`lsp.lua`'s `ensure_installed`) to add a new
  required external tool — both interactive `nvim` (mason auto-installs
  on config load) and headless `bootstrap.sh`/`--update` pick it up
  identically.
- `lazy-lock.json` gives every machine running this config the exact
  same plugin versions, making "works on my machine" plugin-version
  drift a non-issue.
- The filesystem-poll pattern makes `bootstrap.sh` fail loudly (a
  logged warning) rather than silently if parser compilation genuinely
  doesn't finish in time, instead of reporting false success.

### Negative / Risks
- Two separate version-management mechanisms (lazy-lock.json pins
  exact plugin commits; mason tools are not pinned to exact versions
  in this config) means a mason tool upgrading upstream (e.g. a new
  `ruff` major version changing formatting output) can change behavior
  without a corresponding, reviewable commit in this repo — accepted as
  a risk since these are fast-moving, generally backward-compatible
  dev tools, not application dependencies.
- The 180-second polling timeout in `bootstrap.sh` is a fixed budget;
  on an unusually slow machine/network, parsers might still be mid-
  compile when the script moves on — mitigated by the explicit warning
  message telling the operator they'll finish on next `nvim` launch,
  rather than failing the whole script.

## Compliance / Verification
- `bootstrap.sh` re-running is idempotent and is the practical
  regression check for this ADR — there is no separate automated test.
- A `git diff` on `lazy-lock.json` after any `bootstrap.sh --update`
  or manual `lazy sync` is the direct, human-reviewable record of what
  plugin-version changes were pulled in.

## Related ADRs
- ADR-0001 (binary-only bootstrap) — the Node.js/compiler foundation
  mason's own tool installs (npm-packaged `pyright`, `prettier`) run on
  top of.
- ADR-0003 (formatter toolchain selection) — the concrete list of
  formatters this ADR's `ensure_installed` mechanism is used to deliver.
- ADR-0005 (bootstrap install/update/uninstall lifecycle) — `--update`
  re-invokes this same sync mechanism; `--uninstall` removes the data
  directory (`~/.local/share/nvim`) mason/lazy write into.
