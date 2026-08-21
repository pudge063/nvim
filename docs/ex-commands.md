# ex-commands

Everything starting with `:` (command-line mode) is plain vim, not a
hotkey of this config — it works anywhere. The basics are also in
[vim-basics.md](vim-basics.md#command-line), here's the full depth,
from `:w` to batch edits across dozens of files.

## Contents

- [Basics](#basics)
- [Ranges — the foundation of everything else here](#ranges--the-foundation-of-everything-else-here)
- [Search and replace: `:substitute`](#search-and-replace-substitute)
- [Sorting: `:sort`](#sorting-sort)
- [Global commands: `:g` and `:v`](#global-commands-g-and-v)
- [`:normal` — run a normal-mode command over a range](#normal--run-a-normal-mode-command-over-a-range)
- [External shell commands](#external-shell-commands)
- [Lines: `:move`, `:copy`](#lines-move-copy)
- [`:argdo` / `:bufdo` — one command across many files](#argdo--bufdo--one-command-across-many-files)
- [Ready-made recipes](#ready-made-recipes)

---

## Basics

| Command | Meaning |
|---|---|
| `:w` | save |
| `:w {path}` | save as, without renaming the current buffer |
| `:q` | close the window (quits nvim if it's the last one) |
| `:wq` / `:x` | save and close (`:x` skips the write if nothing changed) |
| `:q!` | close without saving |
| `:qa!` | close **everything**, discarding all unsaved changes — careful |
| `:e {path}` | open a file |
| `:e!` | reread the current file from disk, discarding unsaved changes |
| `:messages` | recent messages/errors — for when something flashed and vanished |

## Ranges — the foundation of everything else here

Almost every Ex command below takes a line range **before** the
command name: `:{range}{command}`. Without a range, the command
usually applies to the current line only.

| Range | Meaning |
|---|---|
| (nothing) | current line |
| `.` | current line, explicit |
| `$` | last line of the file |
| `%` | whole file (equivalent to `1,$`) |
| `5,10` | lines 5 through 10 |
| `.,+5` | from the current line, 5 down |
| `.,-3` | from the current line, 3 up (usually written `-3,.`) |
| `'<,'>` | the last visual-mode selection — fills in on its own if you press `:` **while still in visual mode** |
| `'a,'b` | from mark `a` to mark `b` (see [vim-basics.md](vim-basics.md#marks)) |
| `/foo/,/bar/` | from the next line containing `foo` to the next containing `bar` |

In practice: select lines with `V` (visual line), press `:` — the
command line fills in `:'<,'>` on its own, then just append the
command (`sort`, `s/.../.../`, anything from this file).

## Search and replace: `:substitute`

```
:[range]s/pattern/replacement/[flags]
```

| Command | Meaning |
|---|---|
| `:s/old/new/` | first match on the current line |
| `:s/old/new/g` | every match on the current line (`g` = global **for the line**, not the file — a common trip-up) |
| `:%s/old/new/g` | across the whole file |
| `:%s/old/new/gc` | same, with confirmation per match: `y`/`n`/`a` (all)/`q` (stop)/`l` (this one and stop) |
| `:%s/old/new/gi` | case-insensitive search |
| `:'<,'>s/old/new/g` | only within the selection (visual mode → `:`, range fills in) |

**The delimiter doesn't have to be `/`** — if the pattern itself
contains `/` (a path, say), pick another character; it's used
consistently across all three parts: `:%s#old/path#new/path#g` or
`:%s,old/path,new/path,g`.

**Capture groups and backreferences**: `\(...\)` in the pattern is a
group, `\1`, `\2`, ... in the replacement refer back to it.
```
:%s/\(foo\) \(bar\)/\2 \1/
```
swaps `foo bar` → `bar foo` everywhere in the file.

**Special characters in the replacement**: `&` = the whole match
(without groups), `\r` (not `\n`!) = line break, `\u`/`\U` = uppercase
the next character/the rest, `\l`/`\L` = lowercase, `\e`/`\E` = close
`\U`/`\L`.
```
:%s/^\w/\u&/
```
capitalizes the first letter of every line.

**Computed replacement** — `\=` evaluates the rest as a Vimscript
expression:
```
:%s/^/\=line('.') . '. '/
```
numbers every line (`1. `, `2. `, ...) — re-evaluated per line,
`line('.')` is the current line number at replacement time.

## Sorting: `:sort`

**Not the same as shell `sort -u`** — the Ex command `:sort` has **no
dash**, flags are letters right after the command name: `:sort u`, not
`:sort -u`.

| Command | Meaning |
|---|---|
| `:sort` | sort the whole file alphabetically |
| `:sort!` | same, reverse order |
| `:sort u` | sort and drop duplicates (`u` = unique) |
| `:sort n` | sort by numeric value instead of lexicographically (`10` after `2`, not before) |
| `:'<,'>sort` | sort only the selection (visual mode → `:`) |
| `:sort /pattern/` | sort by key — whatever comes **after** the pattern match on each line, not the whole line |

Example for `:sort /pattern/`: a list like `user_42: Alice`,
`user_7: Bob` — `:sort /.*: /` sorts by the name (Alice, Bob), ignoring
the `user_N: ` prefix.

## Global commands: `:g` and `:v`

```
:[range]g/pattern/command
```
Finds every line matching the pattern and runs `command` on each
(default `command` is `p`, print). `:v` (or `:g!`) is the same but for
lines that **don't** match.

| Command | Meaning |
|---|---|
| `:g/^$/d` | delete every blank line |
| `:v/^$/d` | delete every NON-blank line (keep only blanks) |
| `:g/TODO/d` | delete every line containing `TODO` |
| `:g/foo/s/bar/baz/g` | replace `bar`→`baz`, but only on lines that contain `foo` |
| `:g/pattern/m$` | move every matching line to the end of the file, preserving relative order |
| `:g/pattern/t$` | copy (don't move) matching lines to the end |
| `:g/foo/normal A;` | append `;` to every line containing `foo` (see next section) |

`:g` + `normal` is the most powerful combination in this file: `:g`
produces a list of lines by condition, `:normal` runs an arbitrary
normal-mode command on each of them, including a macro (`@a`).

## `:normal` — run a normal-mode command over a range

```
:[range]normal {keys}
```
(`:norm` — shorter, same thing.) Runs ordinary normal-mode keystrokes
on every line of the range, as if you'd typed them by hand.

| Command | Meaning |
|---|---|
| `:%normal A;` | append `;` to the end of **every** line in the file |
| `:'<,'>normal I# ` | comment out the selection (Python) — insert `# ` at the start of every line |
| `:%normal @a` | run recorded macro `a` on every line of the file |
| `:g/pattern/normal @a` | same, but only on lines matching `pattern` — combines with the previous section |

Important: `:normal` without a range runs the command once (on the
current line); with a range, once **per line of the range separately**
(the cursor returns to the start of the line before each run).

## External shell commands

| Command | Meaning |
|---|---|
| `:r !{command}` | insert the shell command's output **after** the current line |
| `:.!{command}` | run the **current line** through the shell command, replace it with the output |
| `:%!{command}` | run the **whole buffer** through the command, replace its contents with the output |
| `:'<,'>!{command}` | same, but only for the selection |

Examples:
```
:%!sort -u                " same result as :sort u, via shell sort instead
:%!jq .                   " pretty-print JSON via jq
:%!column -t              " align space-separated columns into a table
:r !date                  " insert the current date as a line
```
Difference between `:%!` and `:%s`/`:sort`: `:%!` hands the buffer to
an **external program** and fully replaces it with the output — works
for anything available as a CLI tool (unlike a regex replace, `:%!` can
do an arbitrarily complex transformation, but needs the tool installed).

## Lines: `:move`, `:copy`

| Command | Meaning |
|---|---|
| `:m +1` | move the current line 1 down |
| `:m -2` | move 1 up (`-2`, since it's counted BEFORE the move) |
| `:m 0` | move to the very start of the file |
| `:m $` | move to the very end |
| `:'<,'>m +3` | shift the selected lines 3 down |
| `:t .` (or `:co .`) | duplicate the current line right below it |
| `:'<,'>t $` | copy the selection to the end of the file |

## `:argdo` / `:bufdo` — one command across many files

Both run a command in turn across every file in a list, but the lists
differ: `:argdo` works on the **argument list** (`:args **/*.py`
populates it via glob), `:bufdo` works on every **already-open
buffer**.

```
:args **/*.py
:argdo %s/foo/bar/ge | update
```
`%s/foo/bar/ge` replaces across each whole file (the `e` flag
suppresses the "pattern not found" error for any file with no match —
without it, `:argdo` stops at the first file that doesn't match),
`| update` saves the file only if it actually changed (no needless
`:w` on files that didn't).

## Ready-made recipes

| Task | Command |
|---|---|
| Replace one character with another, everywhere | `:%s/x/y/g` |
| Replace every `'` with `"` | `:%s/'/"/g` |
| Replace every `"` with `'` | `:%s/"/'/g` |
| Swap `'` and `"` **with each other**, in one pass, no collision | `:%s/['"]/\=submatch(0) == "'" ? '"' : "'"/g` — `\=` computes the replacement as a Vimscript expression per match, so no temporary placeholder character is needed |
| Remove blank lines | `:g/^$/d` |
| Strip trailing whitespace | `:%s/\s\+$//e` (the `e` flag stays quiet if nothing matches) |
| Tabs → spaces (respecting `shiftwidth`) | `:retab` |
| Sort lines and drop duplicates | `:sort u` |
| Number every line | `:%s/^/\=line('.') . '. '/` |
| Wrap every line of the selection in `"..."` plus a comma (code list) | `:'<,'>s/.*/"&",/` |
| Comment out the selection (Python) | `:'<,'>normal I# ` |
| Swap two words on each line | `:%s/\(\w\+\) \(\w\+\)/\2 \1/` |
| Replace `foo`→`bar` across every `.py` file in the project | `:args **/*.py` then `:argdo %s/foo/bar/ge \| update` |

A simpler one-off replacement (no regex, no ranges) is often faster
with a text object (`ciw`, `ci"`) — see
[vim-basics.md](vim-basics.md#operators--text-objects). The Ex commands
in this file earn their keep when the edit isn't "in one spot" but
across the whole file/project.
