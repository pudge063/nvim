# ADR-0006: Documentation Split by Topic Scope, Not One Big README

## Status
Accepted, 2026-08-16

## Context
This config's documentation started as `README.md` plus a full hotkey
reference (`KEYMAPS.md`) and a config-independent Vim fundamentals
reference (`VIM-BASICS.md`), split out from an originally-monolithic
README as the config grew (see git history: "Split docs: dedicated
KEYMAPS.md and VIM-BASICS.md"). As the config's search tooling
(Telescope) and the user's day-to-day need for advanced `:`-command
recipes (range operations, `:substitute` with capture groups, `:sort`,
`:g`) grew, two more topics reached the point where a single summary
table was no longer enough to cover their real nuances (e.g. exactly
what Telescope already searches by default vs. what each hotkey
variant adds, or the difference between `:sort u` and shell `sort -u`)
without making the file containing them unwieldy for its original,
narrower purpose.

## Decision
Documentation is split by **topic scope**, not by document length or
by "everything in one README": each file answers one class of question,
and cross-links to the others rather than duplicating their content.

- **`README.md`** — project overview, installation, what's inside,
  short "first day" cheat-sheet, links out to everything else.
- **`KEYMAPS.md`** — complete reference of hotkeys *this config adds*,
  organized by feature area, with short "when to use" guidance per row.
- **`VIM-BASICS.md`** — vanilla Vim knowledge that has nothing to do
  with this config specifically (modes, motions, registers, marks,
  macros) — portable to any Vim/Neovim setup.
- **`SEARCH.md`** *(new)* — deep dive on Telescope specifically: which
  picker for which situation, the fzf fuzzy-match operator syntax
  (`'`, `^`, `$`, `!`), and the specific, easy-to-miss fact that
  `live_grep` is regex-based ripgrep matching, not fuzzy matching —
  split out because this level of detail doesn't belong in `KEYMAPS.md`'s
  scannable hotkey table, but is exactly what "why didn't my search find
  X" questions need.
- **`EX-COMMANDS.md`** *(new)* — `:`-command reference from basics
  through advanced recipes (ranges, `:substitute` with `\=`-computed
  replacements, `:sort`, `:g`/`:v`, `:normal` over a range, `:argdo`/
  `:bufdo`, a cookbook of ready-made recipes) — split out of
  `VIM-BASICS.md`'s "Командная строка" section, which is retained only
  as a short table of the half-dozen most common commands plus a link
  here, for the same "scannable summary vs. full depth" reason as
  `SEARCH.md`.
- **`docs/adr/`** *(new)* — architectural decisions for this config
  itself, in MADR-derived format (this file is one), so that "why is
  it built this way" has a durable, dated, falsifiable record instead
  of living only in commit messages or in this user's memory.

Each file that has a narrower-scope deep-dive elsewhere links to it
inline at the point where the summary stops being enough (e.g.
`KEYMAPS.md`'s Telescope table links to `SEARCH.md`'s explanation of
what's already searched by default), rather than requiring the reader
to already know the deep-dive file exists.

## Rationale
- One file per topic scope keeps each document's table of contents
  meaningful — `KEYMAPS.md`'s ToC is genuinely "every hotkey area,"
  not diluted by paragraphs of `:substitute` regex syntax that share no
  reader intent with "what does `<leader>ff` do."
- Splitting by scope rather than by length means a file only grows when
  its actual subject matter grows — `EX-COMMANDS.md` existing
  separately means `VIM-BASICS.md`'s command-line section can stay a
  six-row table indefinitely even as `EX-COMMANDS.md` itself grows a
  cookbook of a dozen more recipes, without the two competing for the
  same document's attention.
- Cross-linking instead of duplicating content means a fact only has
  one place it can go stale — e.g. the note that `find_files` already
  searches hidden files by default lives once, in `SEARCH.md`, and
  `KEYMAPS.md`'s hotkey table links to it rather than restating (and
  risking under-explaining, or drifting from) the same nuance.
- ADRs living in the repo itself (`docs/adr/`), not in this user's
  memory or in scattered commit messages, means a future contributor
  (including this user, months later) can answer "why `\\` and not
  `<leader><leader>`" or "why binary installs and not Homebrew" by
  reading a self-contained file, with the rejected alternatives and
  the reasoning still attached — not by reconstructing it from git
  blame or asking again.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| Keep growing `KEYMAPS.md`/`VIM-BASICS.md` in place instead of splitting further | Already rejected once by this project's own history (the original README → KEYMAPS.md/VIM-BASICS.md split) for the same reason it would recur here: a document trying to serve both "quick scannable reference" and "full depth on one narrow topic" serves neither well as it grows. |
| A single combined `ADVANCED.md` for both search nuances and Ex-command recipes | These are genuinely different subjects (a plugin's search UI vs. vanilla Vim's command-line) with different reader intents ("why didn't Telescope find X" vs. "how do I batch-edit these lines") — combining them would reintroduce exactly the scope-mixing this ADR's Decision is designed to avoid. |
| No ADRs; keep architectural reasoning in commit messages and PR descriptions only | Commit messages answer "what changed," not "what alternatives were rejected and why" — this repo's own bootstrap.sh already carries several inline comments doing informal ADR-style reasoning (e.g. the `+Lazy! sync` vs. `lazy.sync({wait=true})` comment) precisely because that reasoning needed to survive; a proper ADR directory generalizes that instinct instead of leaving it ad hoc per-comment. |

## Consequences
### Positive
- Each doc file has a single, statable purpose — a reader (or an LLM
  assistant working on this repo later) can pick the right file to
  read or edit without opening all of them.
- New topics that reach "needs its own deep dive" status have a clear,
  precedented pattern to follow (split out, link from the summary
  location) rather than each future split being a one-off judgment
  call.
- `docs/adr/` gives every non-obvious architectural choice in this
  config (installation strategy, tool management, formatter selection,
  keybinding choices, this documentation structure itself) a
  consistent, self-contained record.

### Negative / Risks
- More files means more places a cross-link can silently go stale if a
  section heading is renamed without updating the anchor links that
  point to it elsewhere — no automated link checker exists for this
  repo's Markdown; mitigated only by checking links manually when
  renaming a heading.
- ADR numbering (`0001`, `0002`, ...) is sequential and manually
  assigned — two concurrent edits both claiming the "next" number would
  collide; low risk given this repo has a single primary editor, and
  the same scheme is already proven at larger scale in the sibling
  `fm-pivlab-2` project.

## Compliance / Verification
- Nothing enforces this structure automatically (no lint rule "does
  this doc file exceed N topics") — maintaining the split is a manual
  editorial judgment applied consistently going forward, same as the
  original KEYMAPS.md/VIM-BASICS.md split was.
- The practical check is whether `README.md`'s documentation list
  (top of the file) still accurately names every doc file and its
  scope in one line each — if it stops fitting that pattern, the split
  itself needs revisiting.

## Related ADRs
- None of the other ADRs in this directory depend on this one
  structurally, but this ADR documents the convention all of them
  (and any added later) are expected to follow.
