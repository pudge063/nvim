# vim basics

Nothing here is about plugins or this config specifically — it's plain
vim: the basics that work in any vim/nvim, anywhere. This config's own
hotkeys are in [keymaps.md](keymaps.md), the deep dive on `:` commands
is in [ex-commands.md](ex-commands.md), on search in
[search.md](search.md).

## Contents

- [Modes](#modes)
- [Motions](#motions)
- [Operators + text objects](#operators--text-objects)
- [Copy/paste and registers](#copypaste-and-registers)
- [Visual mode and selections](#visual-mode-and-selections)
- [Moving and reordering lines](#moving-and-reordering-lines)
- [Undo / redo](#undo--redo)
- [Search and replace](#search-and-replace)
- [Repeating a command: the dot](#repeating-a-command-the-dot)
- [Marks](#marks)
- [Macros](#macros)
- [Buffers, windows, tabs — the difference](#buffers-windows-tabs--the-difference)
- [Command line](#command-line)

---

## Modes

The main thing that sets vim apart from familiar editors is modes.
Keys do different things depending on which mode you're in. The
current mode is usually visible at the bottom of the screen (or via
lualine/statusline in this config).

| Mode | How to enter | What happens | How to exit |
|---|---|---|---|
| **Normal** | (default mode) | keys are commands, not text | — |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O` (see below) | type text as usual | `Esc` (or `jk` in this config) |
| **Visual** | `v` | select text character by character | `Esc` |
| **Visual Line** | `V` | select whole lines | `Esc` |
| **Visual Block** | `Ctrl-v` | select a rectangular block (a column) | `Esc` |
| **Command-line** | `:` | type a command (`:w`, `:%s/.../...`) | `Enter` (run) or `Esc` (cancel) |
| **Replace** | `R` | typing overwrites characters under the cursor instead of inserting | `Esc` |
| **Terminal** | enter a terminal window (`<C-\>` in this config) | input goes straight to the shell | `Esc` — back to normal, without killing the process |

The ways into insert mode aren't interchangeable — each has its own role:

| Key | Where the cursor lands |
|---|---|
| `i` | before the character under the cursor |
| `a` | after the character under the cursor |
| `I` | start of the line (first non-blank character) |
| `A` | end of the line |
| `o` | new line **below** the current one, cursor there |
| `O` | new line **above** the current one, cursor there |

## Motions

Motions move the cursor. On their own, or combined with an operator
(see below) — in which case they define **what** the operator acts on.

| Key | Where |
|---|---|
| `h` `j` `k` `l` | left / down / up / right |
| `w` | start of the next word |
| `b` | start of the previous word |
| `e` | end of the current/next word |
| `0` | very start of the line (column 0) |
| `^` | first non-blank character of the line |
| `$` | end of the line |
| `gg` | start of the file |
| `G` | end of the file |
| `{n}G` or `:{n}` | a specific line, e.g. `42G` |
| `f{char}` | next occurrence of a character on the line (e.g. `fx` — next `x`) |
| `t{char}` | up to the next occurrence of a character (stops just before it) |
| `F{char}` / `T{char}` | same, backward |
| `;` / `,` | repeat the last `f`/`t` forward / backward |
| `%` | matching bracket `(){}[]` |
| `{` / `}` | paragraph back/forward (a blank line is a paragraph boundary) |
| `Ctrl-d` / `Ctrl-u` | scroll half a screen down/up |
| `Ctrl-f` / `Ctrl-b` | scroll a full screen forward/back |
| `zz` | scroll so the current line is centered on screen |

## Operators + text objects

This is the essence of vim. Operator + motion/text object = command.
Pattern: `{operator}{motion or text object}`.

Main operators:

| Operator | Action |
|---|---|
| `d` | delete |
| `c` | change — deletes and drops straight into insert mode |
| `y` | yank (copy) |
| `>` / `<` | shift indent right/left |
| `=` | auto-indent (via treesitter in this config) |
| `gu` / `gU` | lowercase / uppercase |

Examples with motions:

| Command | Meaning |
|---|---|
| `dw` | delete to the end of the word |
| `d$` (or `D`) | delete to the end of the line |
| `dd` | delete the whole line |
| `yy` | yank the whole line |
| `cw` | replace a word (delete + insert mode) |
| `>>` | shift the current line's indent right |

**Text objects** — instead of a motion, you name WHAT: a word,
brackets, quotes, a paragraph. `i` = inner (contents only), `a` =
around (contents plus the delimiters). This is what makes learning vim
properly worth it — especially useful in Python code:

| Command | Meaning |
|---|---|
| `ciw` | replace the whole word under the cursor |
| `di"` | delete the contents **inside** quotes: `"cursor here"` → `""` |
| `da"` | delete the string **together with** the quotes |
| `ci(` or `cib` | replace the contents of brackets — perfect for function arguments: `foo(cursor)` clears everything between `(` and `)` |
| `di{` | same for `{}` — e.g. the contents of a dict literal |
| `dap` | delete the whole paragraph, including the trailing blank line |
| `dip` | delete the paragraph, without the trailing blank separator |
| `cit` | replace the contents between HTML/XML tags |

Real example: cursor anywhere inside `def foo(a, b, c):` between the
brackets — `ci(` clears `a, b, c`, leaves `def foo():` with the cursor
inside the brackets in insert mode, ready to type new arguments.

## Copy/paste and registers

| Command | Meaning |
|---|---|
| `y` + motion/object | yank (copy) |
| `p` | paste **after** the cursor/line |
| `P` | paste **before** the cursor/line |
| `x` | delete the character under the cursor (also goes to a register, like a cut) |

Important point: `d`/`c`/`x` also put what they removed into a
register — it's a cut, not a plain erase. That's why `dd` then `p` as
two separate commands swaps a line with its neighbor.

**Registers** — vim has many, not a single clipboard:

| Register | What's in it |
|---|---|
| `"` (unnamed, default) | the last delete/yank |
| `"0` | the last actual **yank** (copy), untouched by later `d`/`c` — useful when you copy, then delete something else, and still want to paste the copy |
| `"a`–`"z` | named registers — persist across operations. `"ayy` yanks a line into register `a`, `"ap` pastes from it |
| `"+` | the **system clipboard** — shareable with other applications. `"+y` / `"+p` |
| `"_` | the black hole — delete **without** overwriting the current register: `"_dd` deletes the line, but `p` afterward pastes whatever was copied earlier |

Example: yank a line (`yy`), then delete something else (`dd`) — a
plain `p` pastes the deleted text, not the yanked one. To paste the
yanked text specifically — `"0p`.

## Visual mode and selections

| Key | Mode |
|---|---|
| `v` | character-wise selection |
| `V` | line-wise selection |
| `Ctrl-v` | block (rectangular) selection — a column of text |
| `gv` | restore the last selection |
| `o` (in visual mode) | jump to the other end of the selection |

In visual mode, operators act on the selection: `d` deletes it, `y`
yanks it, `>`/`<` shift the indent of every selected line at once,
`gu`/`gU` change case, `J` joins the selected lines into one.

**Block selection** (`Ctrl-v`) is especially useful for editing a
column across several lines at once: select the block, `I` types text
at the start of every line in the block, `A` at the end, `Esc` applies
it to every line at once.

## Moving and reordering lines

| Command | Meaning |
|---|---|
| `dd` then `p` | move the line down by one |
| `ddkP` | move the line up by one |
| `J` | join the next line onto the current one (with a space) |
| `gJ` | same, without adding a space |
| `:m +1` | move the current line 1 down (`:move`) |
| `:m -2` | move 1 up |
| `:'<,'>m +3` | in visual mode: shift the selected lines 3 down |

## Undo / redo

Covered above already, for completeness:

| Command | Meaning |
|---|---|
| `u` | undo |
| `Ctrl-r` | redo |
| `g-` / `g+` | step back/forward in time (including abandoned branches, not just the current one) |
| `U` | undo all edits on the last-changed line (legacy, rarely needed) |

`Ctrl-Z` in a terminal is **not** undo — it suspends the process to the
background (shell job control). See
[keymaps.md](keymaps.md#undo--change-history) for the visual tree
(`<leader>u`).

## Search and replace

| Command | Meaning |
|---|---|
| `/text` then `Enter` | search forward through the file |
| `?text` | search backward |
| `n` / `N` | next / previous match (in the search direction) |
| `*` | find the next occurrence of the word under the cursor |
| `#` | same, backward |
| `:s/old/new/` | replace the **first** match on the current line |
| `:s/old/new/g` | replace **every** match on the current line |
| `:%s/old/new/g` | replace across the **whole file** |
| `:%s/old/new/gc` | same, with confirmation per match (`y`/`n`/`a`) |
| `:'<,'>s/old/new/g` | replace only within the selection (visual mode → `:`, range fills in) |

## Repeating a command: the dot

`.` repeats the last change in full. One of the most underrated
commands in vim: do `ciw` + type a new word + `Esc`, then `.` on a
different word repeats the exact same replacement. Combines with
`f`/`;`: `f(ci(new_text<Esc>` then `f(.` finds the next brackets and
repeats the replacement of their contents.

## Marks

| Command | Meaning |
|---|---|
| `m{letter}` | set a mark, e.g. `ma` |
| `` `{letter} `` | jump to the exact mark position |
| `'{letter}` | jump to the marked line (start of line) |
| `` `` `` | jump back to where you were before the last jump |
| `Ctrl-o` / `Ctrl-i` | back/forward through the jump history (jumplist) — like a browser's back button |

## Macros

Recording a sequence of commands to replay.

| Command | Meaning |
|---|---|
| `q{letter}` | start recording into a register, e.g. `qa` |
| `q` | stop recording |
| `@{letter}` | play the macro from a register, e.g. `@a` |
| `@@` | repeat the last macro that ran |
| `5@a` | run macro `a` 5 times in a row |

Example: wrap 10 lines of the form `name` into `"name",` — `qa` →
`I"<Esc>A",<Esc>j` → `q` records the macro, then `9@a` applies it to
the remaining nine lines.

## Buffers, windows, tabs — the difference

A common point of confusion for newcomers:

- **Buffer** — a file loaded into memory. Any number can be open at
  once, even if only one is visible. `:ls` / `<leader>fb` lists them.
- **Window** — a visible area on screen showing a buffer. One window
  shows one buffer. `Ctrl-w s` / `Ctrl-w v` split a window
  horizontally/vertically (in this config, switching between windows
  is `Ctrl-h/j/k/l`, see [keymaps.md](keymaps.md#windows)).
- **Tab** — **not** the same thing as a browser/VSCode tab! It's a
  separate **set of windows** (its own split layout). `:tabnew` — new
  tab, `gt`/`gT` — next/previous.

So you can hold 20 files open as buffers, see 2 windows on screen (a
split), all on one tab. Switching buffers without a split:

| Command | Meaning |
|---|---|
| `:bnext` / `:bprev` | next / previous buffer in the same window |
| `]b` / `[b` | same, one key (see [keymaps.md](keymaps.md#general)) |
| `:b {name or part of a name}` | switch to a buffer by name |
| `Ctrl-^` | jump to the **previous** buffer (alternate file) — a built-in vim command, nothing to configure |
| `<leader>fb` | list of buffers via Telescope — usually more convenient with many buffers open |

## Command line

Everything that starts with `:`. The most common:

| Command | Meaning |
|---|---|
| `:w` | save |
| `:q` | close the window (quits nvim if it's the last one) |
| `:wq` or `:x` | save and close |
| `:q!` | close without saving, discarding unsaved changes |
| `:e {path}` | open a file |
| `:e!` | reread the current file from disk, discarding unsaved changes |
| `:%!{shell command}` | run the whole buffer through an external command and replace it with the command's output |

This is only the basics. Ranges (`'<,'>`, `%`, `/pat1/,/pat2/`),
`:substitute` with capture groups and computed replacements, `:sort`,
`:g`/`:v`, `:normal` over a range, `:argdo`/`:bufdo` and ready-made
recipes (swap quotes, strip blank lines, number lines, etc.) are in a
dedicated file: **[ex-commands.md](ex-commands.md)**.
