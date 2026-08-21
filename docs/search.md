# search

Deep dive on search (Telescope). Hotkeys are also in
[keymaps.md](keymaps.md#files-and-search-telescope) as a short table;
here's the same, plus the **nuances** that table can't show: how fuzzy
matching actually works, how `find_files` differs from `live_grep`,
what's on by default and what isn't.

Engine: `telescope.nvim` + `telescope-fzf-native.nvim` (compiled via
`make` on install, see `lua/plugins/telescope.lua`) on top of
`ripgrep`/`fd`.

## Contents

- [Which picker for what](#which-picker-for-what)
- [Launch hotkeys](#launch-hotkeys)
- [Hotkeys inside the picker](#hotkeys-inside-the-picker)
- [What's already on by default — an important nuance](#whats-already-on-by-default--an-important-nuance)
- [Fuzzy search (`find_files`, `buffers`, ...): fzf syntax](#fuzzy-search-find_files-buffers--fzf-syntax)
- [`live_grep`: NOT fuzzy search — it's regex ripgrep](#live_grep-not-fuzzy-search--its-regex-ripgrep)
- [Multi-select and quickfix](#multi-select-and-quickfix)
- [Symbols (`lsp_document_symbols` / `lsp_dynamic_workspace_symbols`)](#symbols-lsp_document_symbols--lsp_dynamic_workspace_symbols)

---

## Which picker for what

| Situation | Picker | Hotkey |
|---|---|---|
| Roughly know the file name | `find_files` | `<leader>ff` |
| File might be in `.venv`/`node_modules`/start with a dot | `find_files` + `no_ignore` | `<leader>fF` |
| Searching for text/a variable/a string in file contents | `live_grep` | `<leader>fg` |
| Same, but the text might be inside venv/build output | `live_grep` + `no_ignore` | `<leader>fG` |
| Opened the file before, closed it since | `oldfiles` | `<leader>fr` |
| Jump between open buffers | `buffers` | `<leader>fb` |
| Find a method/class by name **in this file** | `lsp_document_symbols` | `<leader>fs` |
| Find a method/class by name **in the project** | `lsp_dynamic_workspace_symbols` | `<leader>fS` |
| Overview of every error/warning | `diagnostics` | `<leader>fd` |
| How a command/option of nvim itself works | `help_tags` | `<leader>fh` |

## Launch hotkeys

| key | action |
|---|---|
| `<leader>ff` | find file by name |
| `<leader>fF` | find file, including gitignored (venv, node_modules, ...) |
| `<leader>fg` | find text in file contents (grep) |
| `<leader>fG` | same, including gitignored |
| `<leader>fb` | list of open buffers |
| `<leader>fr` | recently opened files |
| `<leader>fh` | search `:help` |
| `<leader>fd` | diagnostics list (errors/warnings) |
| `<leader>fs` | symbols (classes/methods) of the current file |
| `<leader>fS` | symbols (classes/methods) of the whole project |

## Hotkeys inside the picker

Same across every picker, while the Telescope window is open:

| key | action |
|---|---|
| `<C-n>` / `<C-p>` or `↓` / `↑` | next / previous result |
| `<CR>` | open selected (or all marked — see [multi-select](#multi-select-and-quickfix)) |
| `<C-x>` | open in a horizontal split |
| `<C-v>` | open in a vertical split |
| `<C-t>` | open in a new tab |
| `<Tab>` | mark the current item (multi-select), cursor moves on |
| `<S-Tab>` | mark and move up |
| `<C-q>` | send all (or marked) results to the quickfix list and close Telescope |
| `<M-q>` | same, but to the loclist (local to the window, not the session) |
| `<C-u>` / `<C-d>` | scroll the preview window up/down |
| `<C-c>` or `<Esc>` (picker's normal mode) | close Telescope |
| `<Esc>` twice, if the cursor is still in insert (in the prompt line) | first drop to the picker's normal mode, then close |

## What's already on by default — an important nuance

`lua/plugins/telescope.lua` overrides picker defaults **before** the
`ff`/`fF` distinction even applies:

- `find_files` already looks at **hidden files** (`hidden = true`)
  without `<leader>fF` — dotfiles (`.env`, `.gitignore`, etc.) are
  visible in plain `<leader>ff` too.
- `live_grep` already searches hidden files (`--hidden` in
  `vimgrep_arguments`) and applies `--smart-case` (see below) without
  `<leader>fG`.

Because of that, the **only** difference `ff`↔`fF` and `fg`↔`fG` make
is gitignored content (`.venv`, `node_modules`, `dist`, anything in
`.gitignore`) — not hidden files in general, since those are already
included everywhere. The one thing that's always excluded, with no
hotkey to switch it on, is `.git/` itself
(`file_ignore_patterns = { "%.git/" }`).

`--smart-case`: if the query has no uppercase letters, the search is
case-insensitive; as soon as one uppercase letter appears, the search
becomes case-sensitive automatically — no separate flag needed.

## Fuzzy search (`find_files`, `buffers`, ...): fzf syntax

`find_files`, `buffers`, `oldfiles`, `help_tags`, symbols — all of
these are filtered **fuzzily** through `telescope-fzf-native`: the
letters in the query don't have to be adjacent, only in order. Within
that there are operators worth knowing:

| Syntax | Meaning | Example |
|---|---|---|
| `foo bar` (space) | AND: `foo` AND `bar` (in any order of appearance) | `models user` — files where both fragments appear |
| `'foo` | exact substring `foo` (not fuzzy) | `'test_user` — only literal `test_user`, contiguous |
| `^foo` | match must **start** with `foo` | `^main` — files starting with `main` |
| `foo$` | match must **end** with `foo` | `.py$` — only `.py` files |
| `!foo` | **exclude** matches containing `foo` | `!test` — everything except paths with `test` |
| `^foo$` | exact full match | `^__init__.py$` |

Operators combine with spaces: `'user !test .py$` — exact substring
`user`, no `test` in the path, must end in `.py`.

## `live_grep`: NOT fuzzy search — it's regex ripgrep

Key difference from the section above: what you type into `live_grep`
goes **straight to `rg` as a regex pattern** (that's
`vimgrep_arguments` — a real ripgrep invocation on every keystroke),
not filtered fuzzily after the fact. Practical consequences:

- `.` in the query means "any character" (regex), not a literal dot.
  To search for `foo.bar` literally, escape it: `foo\.bar`.
- Full ripgrep regex works: `foo|bar` (alternation), `\bword\b` (word
  boundaries), `^import` (start of line), `TODO:.*fix`, etc.
- The fzf operators (`'`, `^`, `$`, `!`) from the section above **don't
  apply here** — different search engine, not a result sorter.
- Results are laid out line by line as usual — `rg` matches lines, not
  whole files.

## Multi-select and quickfix

Common case: `live_grep` found a dozen matches and you want to open all
of them at once, not one by one. `<Tab>` on each line you need (marks
it), then `<CR>` opens every marked line as a buffer, or `<C-q>` sends
all (or just the marked ones, if any) to the quickfix list — from
there, walk it with `:cnext`/`:cprev`, or run `:cdo` for a batch edit
across every match at once (see [ex-commands.md](ex-commands.md) —
`:argdo`/`:bufdo` work on the same principle).

## Symbols (`lsp_document_symbols` / `lsp_dynamic_workspace_symbols`)

Not text search — a search over the **symbol tree the LSP** (pyright)
builds, so it finds classes/methods/functions as semantic objects, not
by text match. Because of that:

- Only works where the LSP is actually attached and has indexed the
  file (a Python project with an available `.venv`) — files without an
  LSP return an empty list.
- `lsp_dynamic_workspace_symbols` (`<leader>fS`, whole project) can be
  incomplete right after opening a large project — pyright indexes
  asynchronously in the background; the list fills in a few seconds
  later on a repeat call.
- Not the same as `<leader>fg` on `class Foo`: grep only finds literal
  text matches, symbol search finds `Foo` even when the definition is
  formatted unusually or split across lines.
