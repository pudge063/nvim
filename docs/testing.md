# testing

How this config's tests are structured, what the runner needs, which
commands to use, what to watch. CI is deliberately out of scope here —
by agreement, it gets added separately.

## Approach

This config is a set of Lua modules on top of Neovim, not an
application with business logic, so ordinary unit testing isn't quite
the right fit. Instead, the tests run **real Neovim in headless mode**
against **real fixture files** and check the same things you'd check
by hand: did the LSP attach, did ruff catch an error, does the buffer
format, does the file tree toggle correctly, and so on. It's
essentially an automation of the manual checks this config has been
run through all along during development — including a couple of real
bugs those very checks caught (see below).

**Framework**: [plenary.nvim](https://github.com/nvim-lua/plenary.nvim),
busted-style (`describe`/`it`/`assert`). It's already pulled in as a
dependency of telescope/neo-tree, no separate install needed. Other
options (`mini.test`, hand-rolled asserts in plain Lua) were
considered, but plenary is the most widely used and documented choice
specifically for testing nvim configs/plugins.

### Important limitation: what headless mode can't catch

Not every bug shows up in headless mode. A real example from this
repo: a crash in syntax highlighting (`nvim-treesitter` main branch on
Neovim ≥ 0.12) only showed up through the decoration provider during an
**actual screen redraw** — in headless mode, with no UI attached, those
callbacks simply never fire, so the bug doesn't reproduce at all. If
something like that gets fixed, writing a faithful test for it isn't
possible — only a manual check in a real terminal will do. Comments are
left in the code at those spots.

## Environment setup (what the runner needs)

The tests run a **real plugin sync and LSP tool install** in an
isolated environment — not a mock, an honest from-scratch build of the
config (the same thing `bootstrap.sh` does on a real machine). The
runner needs:

| What | Why | How to check |
|---|---|---|
| `nvim` ≥ 0.11 (a stable build, not from old apt/dnf repos) | the config itself requires `vim.lsp.config`/`vim.lsp.enable` | `nvim --version` |
| `git` | cloning lazy.nvim plugins, `.git` fixtures for the gitsigns test | `git --version` |
| `curl`, `tar` | lazy.nvim downloads plugins | — |
| a C compiler (`cc`/`gcc`) | compiling treesitter parsers | `cc --version` |
| the `tree-sitter` CLI | same purpose — `nvim-treesitter` (main branch) compiles parsers through it, not the compiler directly | `tree-sitter --version` |
| `node` + `npm` | mason installs `pyright` (an npm package) | `node --version` |
| `python3` | the thing being tested against — the Python LSP itself | `python3 --version` |
| outbound network (GitHub, PyPI via npm/pip, the mason registry) | the first run downloads everything from scratch | — |

If the runner is already set up via `bootstrap.sh` (e.g. it's the same
image/machine the config itself lives on), everything in the table
above is already present — nothing to install, `make setup` just
verifies it and finishes quickly.

If the runner is clean (a typical CI container) — **run
`bootstrap.sh` first, then the tests**:
```bash
~/.config/nvim/bootstrap.sh   # installs nvim/rg/fd/tree-sitter/node as binaries
cd ~/.config/nvim
make test
```
(`bootstrap.sh` already knows how to install everything in the table
above without sudo, as long as git/a compiler are already in the
image — see [README.md](../README.md).)

## Commands

```bash
make setup       # sync plugins, install mason tools, prepare fixtures (a venv stub, a git repo)
make test        # setup (if needed) + the full test suite
make test-only   # tests only, no setup — faster for repeat runs while iterating
make clean       # tear down the isolated test environment and generated fixtures
```

Tests live in `tests/config/*_spec.lua`, fixtures in
`tests/fixtures/`. Isolation: `make setup` points `$XDG_CONFIG_HOME` at
this repository via a symlink inside a temporary home directory
(`.test-home/`, gitignored), so tests run against a clean environment
and never touch your real `~/.config/nvim` / `~/.local/share/nvim`,
even when run straight from a working copy of the config.

## Test layout

| File | What it checks |
|---|---|
| `smoke_spec.lua` | the config starts without errors, every lazy.nvim plugin is actually on disk, parsers and mason tools are installed |
| `lsp_spec.lua` | pyright + ruff attach, ruff catches an unused import, `gd` jumps to another file (base class), `gr` finds subclasses, `.venv/bin/python` is auto-detected |
| `treesitter_spec.lua` | highlighting is active, parsing a class doesn't crash (regression guard for the main-branch bug) |
| `formatting_spec.lua` | ruff formatting fixes the buffer without touching the file on disk |
| `autopairs_spec.lua` | brackets/quotes close and nest correctly |
| `neotree_spec.lua` | `<leader>e` behaves correctly in all three states (closed / open-unfocused / focused) |
| `autocmds_spec.lua` | `cwd` auto-switches to the project root |
| `gitsigns_spec.lua` | the current branch is detected in the fixture repo |
| `colorscheme_spec.lua` | every installed theme switches without errors, custom overrides (brightness/bold) leave accent colors alone |
| `keymaps_spec.lua` | every hotkey listed in [keymaps.md](keymaps.md) is actually bound |

## Metrics: what to watch

There's no line-coverage percentage here the way `pytest-cov` gives
one for a normal application — no tool that mature exists for Lua
configs on top of Neovim, and building one just to have a percentage
isn't worth it. What's worth watching instead:

1. **Pass/fail per file, not just the overall total.** plenary prints
   `Success: N / Failed: N / Errors: N` for each `*_spec.lua` — when
   CI gets added, it's worth parsing that per line (or turning on
   plenary's JUnit output, which `PlenaryBustedDirectory` supports via
   an extra option), so a failure points at the **area** that broke
   (LSP? formatting? theme?), not just "something's red."
2. **`lsp_spec.lua`'s run time, tracked separately from the rest.**
   It's the only genuinely slow file (a real pyright + ruff startup,
   usually 5-15s per test) — if it starts taking noticeably longer,
   that's a sign of degradation (e.g. pyright re-indexing something it
   shouldn't) before the test formally times out.
3. **"Failed on timeout" vs. "failed on an assert."** A timeout in the
   LSP tests usually means "the server didn't come up/respond in
   time" (the environment is slower than usual — raise the timeout in
   `helpers.wait_for*`), which is not the same as "the server
   responded with something other than expected" (an actual
   regression in the config).
4. **The list of skipped checks (headless limitations).** When editing
   something that used to need a manual check in a real UI (see the
   decoration-provider case above), walk through it by hand in a real
   terminal before merging — a green test run doesn't guarantee it.

## Known bugs these tests caught on their first run

Not staged for demonstration — both surfaced on the first honest run
of the full suite, before the tests were tuned to match existing
behavior:

- **`gI` (go to implementation) doesn't work for Python.** pyright
  doesn't advertise `implementationProvider` in its capabilities at
  all — `lsp_spec.lua` caught this, and the docs and a comment in
  `lsp.lua` were corrected (`gI` used to be described as "the main
  tool for OOP navigation," which is false for Python).
- **`map.callback()` ≠ an actual keypress.** The first call to
  `<leader>e` in a fresh process didn't open the tree when the
  registered `callback` was invoked directly
  (`vim.fn.maparg(...).callback()`) — lazy.nvim's lazy-loading wrapper
  expects dispatch through a real keypress (`nvim_feedkeys`), not a
  direct Lua call. The test was rewritten to use `nvim_feedkeys`,
  which also made it a much more honest check of the real user
  scenario.
