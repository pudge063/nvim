# nvim-config

A portable Neovim config built around Python development — LSP
(pyright + ruff), automatic venv detection, Telescope, a file tree, a
built-in terminal, undo-tree, the sonokai theme — with LSP support for
several other languages (C/C++, Lua, YAML, Terraform, Docker, Bash,
CMake) layered on through the same mason pipeline. Installs on a fresh
machine (macOS / Linux) with a single command, no Homebrew on macOS.

Repository: https://github.com/pudge063/nvim.git

**Documentation:**
- [docs/keymaps.md](docs/keymaps.md) — full list of this config's hotkeys, with explanations and examples
- [docs/search.md](docs/search.md) — deep dive on search (Telescope): fuzzy-match syntax, `live_grep` nuances, multi-select
- [docs/ex-commands.md](docs/ex-commands.md) — `:` commands from basics to advanced: ranges, `:substitute`, `:sort`, `:g`/`:v`, ready-made recipes
- [docs/vim-basics.md](docs/vim-basics.md) — plain vim fundamentals (modes, motions, text objects, registers, macros...), independent of this config
- [docs/testing.md](docs/testing.md) — how the tests (`make test`) are structured, what the runner needs, what to watch
- [docs/adr/](docs/adr/) — this config's architectural decisions, in ADR format (why it's built this way)

## Quick start

**Basic install:**
```bash
curl -fsSL https://raw.githubusercontent.com/pudge063/nvim/master/bootstrap.sh | bash
```
One `curl` that: installs Neovim/ripgrep/fd/Node.js/Python as
prebuilt binaries under `~/.local`, clones this repository into
`~/.config/nvim`, syncs plugins, and installs
pyright/ruff/lua_ls/clangd/yamlls/terraformls/dockerls/bashls/cmake/
debugpy/stylua/prettier/taplo through mason.

Afterwards, open a new terminal (so `PATH` picks up the change) and run
`nvim`.

If the one-liner doesn't work, do the same thing by hand:
```bash
git clone https://github.com/pudge063/nvim.git ~/.config/nvim
~/.config/nvim/bootstrap.sh
```

## Updating and removing on your machine

`bootstrap.sh` isn't just an installer — it has three modes (updating
`lazy-lock.json` in the repository itself is a separate topic, see
["Updating lazy-lock.json" below](#updating-lazy-lockjson-for-maintainers)):

```bash
~/.config/nvim/bootstrap.sh              # first-time install (see above)
~/.config/nvim/bootstrap.sh --update      # git pull + resync plugins/tools, WITHOUT reinstalling the binaries
~/.config/nvim/bootstrap.sh --uninstall   # full rollback: remove the config, plugins, binaries
~/.config/nvim/bootstrap.sh --help        # what each mode does, in detail
```

- **`--update`** — the common case: pull in new commits to this
  repository (new plugins, formatters, hotkeys) on an already-set-up
  machine. Doesn't touch the Neovim/ripgrep/fd/Node.js/Python binaries
  themselves — only a `git pull` in `~/.config/nvim` and a plugin/mason-tool
  resync.
- **`--uninstall`** — a full reset to "as if this config never
  existed": removes `~/.config/nvim`, plugin/mason data
  (`~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`), the
  binaries under `~/.local/opt` and their symlinks in `~/.local/bin`,
  and cleans up the `PATH` line added to `.zshrc`/`.bashrc`/`.profile`.
  Asks for confirmation (`-y`/`--yes` skips the prompt). Doesn't touch
  system packages installed via `apt`/`dnf` (git, curl, a compiler) —
  those are shared by the system, not specific to this config.

## Config tree

```
~/.config/nvim/
├── init.lua                   # options -> keymaps -> autocmds -> lazy
├── lua/
│   ├── config/
│   │   ├── options.lua        # indentation, line numbers, undofile, ...
│   │   ├── keymaps.lua        # general mappings
│   │   ├── autocmds.lua       # auto-cd to the project root (.git), symbol-highlight-on-hover colors
│   │   └── lazy.lua           # lazy.nvim bootstrap
│   └── plugins/                # one file = one plugin spec
│       ├── colorscheme.lua    # sonokai (+ monokai-pro/dracula/cyberdream/synthwave84 to pick from)
│       ├── lualine.lua        # status/tabline
│       ├── gitsigns.lua       # change markers in the gutter, hunks, blame
│       ├── telescope.lua      # file/text/symbol search
│       ├── neo-tree.lua       # file tree
│       ├── toggleterm.lua     # terminal inside nvim
│       ├── treesitter.lua     # syntax highlighting
│       ├── completion.lua     # blink.cmp — completion
│       ├── lsp.lua            # mason + pyright/ruff/lua_ls/clangd/yamlls/terraformls/dockerls/bashls/cmake
│       ├── formatting.lua     # conform.nvim (ruff format, stylua, prettier, taplo)
│       ├── python.lua         # venv-selector.nvim
│       ├── dap.lua            # nvim-dap + nvim-dap-ui (debugpy, gdb -i=dap)
│       ├── undotree.lua       # visual undo-history tree
│       ├── autopairs.lua      # auto-close brackets/quotes
│       └── align.lua          # mini.align — manual column alignment
├── bootstrap.sh                # installer/updater/uninstaller (see above)
├── docs/adr/                    # architectural decisions (ADR, MADR format)
├── docs/keymaps.md              # every hotkey this config adds, in detail
├── docs/search.md                # deep dive on search (Telescope)
├── docs/ex-commands.md           # `:` commands, basics to advanced
├── docs/vim-basics.md            # plain vim fundamentals, independent of this config
├── docs/testing.md               # how the test suite works
└── lazy-lock.json              # exact versions of every plugin — committed
```

## OS support

`bootstrap.sh` detects the OS and architecture (Intel/Apple Silicon,
x86_64/arm64) on its own and installs everything it needs as
**prebuilt binaries** from official releases — Neovim, ripgrep, fd, the
`tree-sitter` CLI (needed by nvim-treesitter to compile parsers),
Node.js (needed by mason to install pyright, an npm package), and
Python (needed by mason for pip-based tools: debugpy, cmake-language-server)
go under `~/.local/opt/*` and get symlinked into `~/.local/bin`. No
sudo is required for nvim's own tooling.

### macOS

**No Homebrew.** The only system-level dependency is a compiler and
git from Xcode Command Line Tools (part of macOS, not Homebrew).
`bootstrap.sh` tries to install them itself, without a dialog: it
detects the exact Command Line Tools package label via
`softwareupdate -l` and installs that non-interactively.

If the automatic path doesn't take (happens on some newer macOS
versions), install manually with `xcode-select --install` (a GUI
dialog appears — click Install) and re-run `bootstrap.sh`.

Everything after that follows the Linux path: Neovim/rg/fd/Node/Python
are downloaded from `github.com/.../releases` and `nodejs.org/dist` for
your architecture (`arm64` for Apple Silicon, `x86_64` for Intel).

### Debian / Ubuntu

Checks for `git`, `curl`, `tar`, a compiler, and `gdb` (needed for
C/C++ debugging, see [docs/keymaps.md](docs/keymaps.md#debugging-dap));
anything missing is installed via
`apt-get install -y git curl tar build-essential gdb` (needs sudo).
ripgrep/fd are NOT installed via apt — the versions in Ubuntu LTS
repos are often stale, so they're downloaded as binaries here too, same
as on macOS.

### RockyLinux (and the wider RHEL family: CentOS, Fedora, AlmaLinux)

Same idea, via `dnf install -y git curl tar gcc gcc-c++ make gdb python3`.
No need to enable EPEL for ripgrep/fd — same reason as above: they come
as binaries from GitHub, not the system repos.

### Common to Linux

- The script doesn't touch anything via sudo if `git`/a compiler are
  already installed (typical for dev servers) — in that case the
  whole of `bootstrap.sh` runs without root at all.
- `~/.local/bin` is appended to `PATH` in `~/.zshrc`/`~/.bashrc`/`~/.profile`
  (whichever of those actually exist for you), so new terminals pick it
  up automatically.

## Theme and transparency

**sonokai** is active by default (`sonokai_style = "default"`,
`sonokai_transparent_background = 1`). `lua/plugins/colorscheme.lua`
registers several more themes at the same time — `monokai-pro`,
`dracula`, `cyberdream`, `synthwave84` — they don't activate
themselves, but are already configured and switch instantly:
`:colorscheme dracula`, `:colorscheme cyberdream`,
`:colorscheme monokai-pro-classic`, etc. (the exact variant name is in
a comment next to each theme in the file).

Transparency for every theme except `synthwave84` (its neon look needs
an opaque background to work) is drawn by the terminal
(Ghostty/iTerm2/Alacritty — `background-opacity` in its own settings);
nvim just doesn't paint over it.

## Python: LSP, venv, OOP navigation

- **pyright** — types, completion, code navigation.
- **ruff** — linting and formatting (`<leader>mp`, or automatically on
  save once you opt in — see [docs/keymaps.md](docs/keymaps.md#formatting)).
- **venv**: `pyright` looks at `<project-root>/.venv` on its own; if
  the venv is named differently or isn't at the root, `<leader>cv`
  opens a Telescope list of every environment found
  (poetry/conda/pyenv/hatch/...).
- The project root (`cwd`) switches automatically when you open a file,
  based on the nearest `.git`/`pyproject.toml` up the tree — no need to
  remember to `cd` before `nvim`.

## Editing

- **Brackets/quotes** close themselves, IDE-style (`nvim-autopairs`):
  type `(` — get `()`, cursor between them; nesting works correctly,
  including inside strings/comments (treesitter-aware, doesn't force a
  pair where that would get in the way).
- **Formatting** — ruff (`python`), stylua (`lua`), prettier (`yaml`,
  `markdown`), taplo (`toml`) via `conform.nvim`. Off by default; opt
  in with `<leader>uf`/`<leader>uF`, or format on demand at any time
  with the hotkey (`<leader>mp` or `\\` twice).
- **Column alignment** (not the same as formatting — ruff deliberately
  doesn't do this) — `mini.align`.
- **Line numbers** — absolute by default; `<leader>ur` switches the
  current window to relative (handy for `5j`/`3dd` etc.) and back.
- **End of line** is marked with `↵` (`list`/`listchars`) — shows where
  a line actually ends, not just where `wrap` breaks it visually.

Hotkeys for all of this, and everything else, are in
[docs/keymaps.md](docs/keymaps.md).

## Hotkeys

Full list with explanations and examples in a dedicated file:
**[docs/keymaps.md](docs/keymaps.md)**.

The most common ones for day one:

| key | action |
|---|---|
| `<leader>ff` / `<leader>fg` | find a file / find text in the project |
| `<leader>e` | file tree (open/focus/close) |
| `<C-\>` | terminal inside nvim |
| `gd` / `K` | go to definition / view type and docs |
| `<leader>rn` | rename a symbol across the whole project |
| `<leader>mp` / `\\` (twice) | format the buffer right now |
| `<leader>u` | undo-history tree |

For plain vim (modes, `dd`/`ciw`/macros, etc.), not this config
specifically — see **[docs/vim-basics.md](docs/vim-basics.md)**.

## `Ctrl+\` on macOS, in detail

`Ctrl+\` isn't a "special nvim combination" — it's the standard POSIX
FS character (0x1C), which the terminal driver treats by default as
**SIGQUIT** (abrupt termination of the foreground process). Same on
Linux and macOS: while nvim is the active program in the terminal, it
puts the tty into raw mode itself and intercepts this byte as regular
input, so `Ctrl+\` normally just reaches toggleterm instead of killing
nvim. But on macOS there are a few places this can break before it
ever reaches nvim:

1. **tmux** — if you open nvim inside tmux and `~/.tmux.conf` binds `\`
   to something of its own (a split-pane action, say), tmux intercepts
   the combination before it reaches nvim.
2. **Karabiner-Elements** — if it's installed with custom keyboard
   remaps, `\`/`Ctrl` may be redefined at the OS level, before the
   terminal even sees it.
3. **Keyboard layout** — on non-US layouts (e.g. an ISO/RU layout on a
   built-in Mac keyboard), the physical `\` often moves to a different
   key or needs `Option`/an extra modifier — so `Ctrl+\` simply can't
   be typed as one gesture.
4. **Terminal app settings** (iTerm2/Terminal.app/Ghostty) — under
   Preferences → Keys, something can end up intercepting `\`
   combinations at the application level.

That's why there's a fallback binding, **`<leader>tt`** (Space, then
`t` twice) — it does exactly what `<C-\>` does, but doesn't depend on
layout, tmux, or Karabiner. If `Ctrl+\` doesn't work for you, just use
`<leader>tt` and skip diagnosing tty raw-mode behavior.

## Updating lazy-lock.json (for maintainers)

This is about bumping plugin versions **in the repository itself** —
not to be confused with
[updating on your own machine](#updating-and-removing-on-your-machine)
(`bootstrap.sh --update`), which is the opposite direction: that pulls
already-committed versions, this commits new ones.

```bash
cd ~/.config/nvim
nvim --headless -c "lua require('lazy').sync({ wait = true, show = false })" -c "qa"
git add lazy-lock.json && git commit -m "bump plugins" && git push
```
(`require('lazy').sync({wait=true})`, not a bare `+Lazy! sync` — the
latter doesn't wait for build hooks like compiling treesitter parsers,
see `bootstrap.sh`.)
On other machines, `bootstrap.sh --update` (or just `git pull`) picks
up the new versions on the next nvim launch.

## Troubleshooting

- **`nvim --version` shows an old version / no plugins** — most likely
  a system neovim (`/usr/bin/nvim` from apt/dnf) comes first in
  `PATH`. Open a new terminal (`PATH` only updates for new sessions)
  and check `which -a nvim` — `~/.local/bin/nvim` should be first.
- **`fd`/`rg` not found** — same `PATH` issue, see above; or
  `bootstrap.sh` didn't run to completion (stopped partway) — run it
  again, it's idempotent.
- **pyright can't resolve imports** — see the venv section above:
  `<leader>cv` and pick the right environment, or just name the venv
  `.venv` and put it at the project root — it'll be picked up
  automatically.
- **Ctrl+\ doesn't open the terminal on macOS** — see the section
  above, use `<leader>tt`.
