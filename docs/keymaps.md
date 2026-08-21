# keymaps

Complete list of hotkeys added by this config — not built-in vim
commands, those are in [vim-basics.md](vim-basics.md).

`<leader>` = **Space**. All examples are normal mode unless stated
otherwise.

## Contents

- [Files and search (Telescope)](#files-and-search-telescope)
- [File tree](#file-tree)
- [Code navigation / LSP / OOP](#code-navigation--lsp--oop)
- [Completion (blink.cmp)](#completion-blinkcmp)
- [Formatting](#formatting)
- [Alignment](#alignment)
- [Brackets and quotes (autopairs)](#brackets-and-quotes-autopairs)
- [Git (gitsigns)](#git-gitsigns)
- [Python venv](#python-venv)
- [Debugging (DAP)](#debugging-dap)
- [Terminal](#terminal)
- [Undo / change history](#undo--change-history)
- [Windows](#windows)
- [General](#general)

---

## Files and search (Telescope)

Table below covers the common cases. Full breakdown — multi-select,
fuzzy-match syntax, how `live_grep` differs from `find_files`, what's
already on by default — is in **[search.md](search.md)**.

| key | action | when to use |
|---|---|---|
| `<leader>ff` | find file by name (hidden files shown by default) | open a file, roughly knowing its name |
| `<leader>fF` | same, plus files from `.gitignore` (venv, node_modules...) | the file lives inside `.venv`/`node_modules` |
| `<leader>fg` | find text in file contents (grep, hidden files included by default) | find where a variable/string is used |
| `<leader>fG` | same, plus `.gitignore` content | the text may be inside venv/build output |
| `<leader>fb` | list of open buffers | jump between already-open files |
| `<leader>fr` | recently opened files | "opened this recently, closed it" |
| `<leader>fh` | search `:help` | how something works in nvim itself |
| `<leader>fd` | diagnostics list (errors/warnings) | overview of every problem in project/file |
| `<leader>fs` | symbols (classes/methods) of **current file** | jump to a method quickly |
| `<leader>fS` | symbols (classes/methods) of **whole project** | find a class/method by name without knowing the file |

Inside Telescope, while the picker window is open:

| key | action |
|---|---|
| `<C-n>` / `<C-p>` or `↓`/`↑` | next / previous result |
| `<CR>` | open selected (or all marked — see `<Tab>`) |
| `<C-x>` / `<C-v>` / `<C-t>` | open in horizontal / vertical split / new tab |
| `<Tab>` | mark item for multi-select |
| `<Esc>` (twice, if still in insert mode) | close Telescope |
| `<C-q>` | send all (or marked) results to the quickfix list |

Fuzzy-match syntax (`'exact`, `^prefix`, `suffix$`, `!exclude`) and why
`live_grep` is regex ripgrep, not fuzzy — in [search.md](search.md).

## File tree

| key | action |
|---|---|
| `<leader>e` | **smart toggle**: tree closed → open and focus; open but unfocused → focus it; already focused → close |

Inside the tree (neo-tree), when focused:

| key | action |
|---|---|
| `<CR>` / `o` | open file / expand directory |
| `s` | open file in **vertical split** |
| `S` | open file in **horizontal split** |
| `t` | open file in a new tab |
| `w` | open with window picker, if there's more than one split |
| `a` | create file (directory — end the name with `/`) |
| `d` | delete |
| `r` | rename |
| `y` / `x` / `p` | copy / cut / paste (file) |
| `H` | show/hide hidden files |
| `R` | refresh the tree |
| `<C-l>` (or your usual window-nav — see [Windows](#windows)) | back to the editor |

## Code navigation / LSP / OOP

Works in any file with an attached LSP (Python — anywhere a
`.venv`/pyright is available).

| key | action | when |
|---|---|---|
| `gd` | Go to definition | jump to the class/function/variable's definition |
| `<leader>gd` | Go to definition (**vertical split**) | same, opens the definition alongside instead of replacing the current window |
| `gD` | Go to declaration | jump to the declaration — rarely needed, useful for `.pyi` stubs |
| `gr` | Go to references | every place the symbol under the cursor is used |
| `gI` | Go to **implementations** | not supported by every LSP — **pyright doesn't support it at all** (`implementationProvider` isn't declared; verified by the `lsp_spec.lua` test). For Python use `gr` on the base class instead — see the workflow below |
| `gy` | Go to type definition | from a variable to its type/class definition |
| `K` | Hover | show type/signature/docstring under the cursor |
| `<leader>rn` | Rename | rename the symbol **everywhere in the project** — safe refactor |
| `<leader>ca` | Code action | quick fixes: auto-import, "implement abstract methods", etc. Works in visual mode on a selection |
| `<leader>ci` | Incoming calls | who calls this method (call hierarchy, inward) |
| `<leader>co` | Outgoing calls | what this method calls (call hierarchy, outward) |
| `<leader>d` | Full diagnostic for the line | complete error/warning text under the cursor, for when it doesn't fit on one line to the right |
| `<C-h>` (**insert mode**) | Signature help | argument hints while typing a call |

Other occurrences of the symbol under the cursor are also highlighted
automatically once the cursor rests (`CursorHold`) — no key needed,
works wherever the LSP advertises `documentHighlight`.

> `<C-h>` appears twice in this config: in normal mode it moves to the
> window on the left (see [Windows](#windows)), in insert mode it's
> signature help. No conflict — different modes.

Typical OOP workflow (Python, pyright):
1. `class Foo(Base):` → cursor on `Base`, `gd` — jump to the base class.
2. Cursor on the **base class name** (not a method — see the `gI`
   caveat above), `gr` — find every place it's referenced, including
   subclass declarations (`class Foo(Base):`).
3. `<leader>fs` — scan through all methods of the current class.
4. `<leader>rn` on a method name — rename it everywhere, including
   overrides and call sites.

`gI` isn't dead weight — just keep in mind it won't work for Python
(the LSP replies "method not supported"); for languages whose LSP does
support implementations (e.g. `gopls` for Go) it's still a real, useful
hotkey.

## Completion (blink.cmp)

Triggers automatically in insert mode as you type.

| key | action |
|---|---|
| `<C-space>` | open the menu manually / show docs for the selected item |
| `<Up>` / `<Down>` or `<C-p>` / `<C-n>` | next / previous item |
| `<CR>` | accept the selected item |
| `<C-e>` | close the menu without accepting |
| `<Tab>` / `<S-Tab>` | jump between snippet placeholders (**not** menu navigation) |
| `<C-k>` | toggle signature help |
| `<C-b>` / `<C-f>` | scroll docs up/down |

## Formatting

Formats with ruff (Python), stylua (Lua), prettier (YAML, Markdown) and
taplo (TOML) — see also
[the ruff section in README](../README.md#python-lsp-venv-oop-navigation).

| key | action |
|---|---|
| `<leader>mp` / `\\` (twice) | format the buffer **right now** — independent of saving, works in visual mode on a selection too |
| `<leader>uf` | toggle format-on-save — current buffer only |
| `<leader>uF` | same, globally, for all buffers |

Format-on-save is **off by default** — opt in with `<leader>uf`
(buffer) or `<leader>uF` (global) once you want it. For Python, ruff
also runs `ruff_fix` and `ruff_organize_imports` before `ruff_format`,
so a format pass fixes lint issues and import order, not just style.

## Alignment

`mini.align` — manual column alignment, which ruff deliberately doesn't
do since it isn't part of PEP8.

| key | action |
|---|---|
| `ga` + motion/selection, then a character | align on that character. Example: select lines in visual mode, `ga=` — every `=` lines up in one column |
| `gA` + same | same, with a live preview before applying |

Example: given
```python
x = 1
foo = 2
qux = 3
```
select all three lines (`Vjj`), press `ga=` — get:
```python
x   = 1
foo = 2
qux = 3
```

## Brackets and quotes (autopairs)

Works on its own, no hotkeys — `nvim-autopairs`:
- type `(` → get `()`, cursor between them;
- same for `[`, `{`, `"`, `'`;
- nesting works like an IDE: `(["{` → `(["{}"])`.
- Inside strings/comments (treesitter-aware) pairs aren't forced where
  that would usually get in the way.

## Git (gitsigns)

Change markers on the left margin (added/modified/removed) show up on
their own for any file inside a git repository — the hotkeys below are
for navigating and acting on them.

| key | action |
|---|---|
| `]h` | next changed hunk |
| `[h` | previous changed hunk |
| `<leader>hs` | stage hunk (works in visual mode on part of a hunk too) |
| `<leader>hr` | reset hunk to the version in git |
| `<leader>hp` | preview hunk diff in a popup |
| `<leader>hb` | blame the current line (who changed it, when) |
| `<leader>tb` | toggle persistent inline blame (shown to the right of the line) |

## Python venv

| key | action |
|---|---|
| `<leader>cv` | pick a virtual environment (Telescope picker: finds `.venv`, poetry, conda, pyenv, etc.) |

If the venv is named `.venv` and sits at the project root, it's picked
up automatically — `<leader>cv` isn't needed (see README).

## Debugging (DAP)

Breakpoint-based debugging — nvim-dap. Works out of the box for Python
(debugpy installed via mason). For C/C++ — through gdb's native DAP
mode (`gdb -i=dap`, needs gdb ≥ 12 on `$PATH`), including attaching to
a remote gdbserver (OpenOCD/J-Link) for embedded targets — that only
covers attaching to an already-running gdbserver stub, not flashing.

| key | action | when / why |
|---|---|---|
| `<leader>db` | toggle breakpoint | set/remove a breakpoint on the current line |
| `<leader>dB` | conditional breakpoint | breakpoint with a condition (prompts for the expression) |
| `<leader>dc` | continue / start | start debugging (picks a config if there's more than one) or resume after a stop |
| `<leader>di` | step into | enter the function being called |
| `<leader>do` | step over | run the line without entering calls |
| `<leader>dO` | step out | leave the current function |
| `<leader>dt` | terminate | end the debug session |
| `<leader>dr` | toggle REPL | debugger console — evaluate expressions in the current context |
| `<leader>du` | toggle UI | call stack, variables and breakpoints panels (nvim-dap-ui) |

## Terminal

| key | action |
|---|---|
| `<C-\>` | open/collapse the floating terminal |
| `<leader>tt` | same thing — fallback for macOS, where `Ctrl+\` sometimes gets intercepted before nvim sees it (details in README) |
| `<Esc>` (cursor in the terminal) | leave terminal-mode for normal mode without killing the process inside |

## Undo / change history

| key | action |
|---|---|
| `<leader>u` | open/close the visual undo tree (undotree) |

Plain `u` / `Ctrl-r` / `g-` / `g+` — see
[vim-basics.md](vim-basics.md#undo--redo). Undo history survives an
nvim restart (`undofile = true`).

## Windows

| key | action |
|---|---|
| `<C-h>` | window to the left (including the file tree, if that's where it is) |
| `<C-j>` | window below |
| `<C-k>` | window above |
| `<C-l>` | window to the right |

## General

| key | action |
|---|---|
| `jk` (insert mode) | leave insert mode — alternative to `Esc`, no reach to the corner of the keyboard |
| `<leader>w` | save file |
| `<leader>q` | close window/buffer |
| `]b` | next buffer |
| `[b` | previous buffer |
| `<leader>ur` | toggle relative line numbers (default is absolute) |
