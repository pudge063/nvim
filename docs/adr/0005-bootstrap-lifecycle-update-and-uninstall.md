# ADR-0005: `bootstrap.sh` Gains `--update` and `--uninstall` Subcommands

## Status
Accepted, 2026-08-16

## Context
`bootstrap.sh` (ADR-0001) previously only did a fresh install, run as
one long top-to-bottom script. Two gaps existed in practice:
- **Updating** an already-provisioned machine to the latest config
  required either re-running the full install script (redundant:
  re-detects OS/arch and re-fetches Neovim/ripgrep/fd/Node.js binaries
  that haven't changed) or following a manual multi-step recipe
  documented only in the README (`cd` in, run a specific `nvim
  --headless` Lua one-liner, remember it needs `MasonToolsInstallSync`
  too if new mason tools were added — as happened in ADR-0003).
- **Uninstalling** had no supported path at all — a user wanting to
  fully reset (e.g. to test a from-scratch install, or to stop using
  this config) would need to manually track down and remove every
  directory and symlink the installer created, with no authoritative
  list of what those even were.

## Decision
`bootstrap.sh` is restructured into three named commands, dispatched
on `$1`:
- **(no argument)** — `cmd_install`: the original fresh-install
  behavior, unchanged in effect.
- **`--update`**: `git pull --ff-only` in `$CONFIG_DIR`, then re-runs
  the same plugin-sync-plus-tool-install routine as install
  (`sync_plugins_and_tools`, factored out as a shared function so
  install and update cannot drift out of sync with each other). Does
  **not** touch the Neovim/ripgrep/fd/Node.js binaries or re-run OS
  prerequisite detection.
- **`--uninstall`**: removes everything the install path is known to
  have created — `$CONFIG_DIR`, the nvim data/state/cache directories
  (`~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`), the
  `~/.local/opt/{nvim,ripgrep,fd,node}` binary installs, their
  symlinks in `~/.local/bin` (removed only if the symlink actually
  resolves into `$INSTALL_ROOT`, never by name alone), and the exact
  `PATH` line the installer appended to shell rc files. Prints the
  full removal list and requires interactive `y` confirmation unless
  `-y`/`--yes` is passed. Deliberately does **not** remove system
  packages (`git`, `curl`, a compiler) installed via `apt`/`dnf` during
  a fresh install, since those are shared with the rest of the system,
  not owned by this config.

`--help`/`-h` documents all three modes; an unrecognized first argument
prints usage and exits non-zero rather than silently doing nothing.

## Rationale
- Splitting `sync_plugins_and_tools` out as a function shared by
  `cmd_install` and `cmd_update` was chosen specifically so that a
  future change to how plugins/tools get synced (e.g. adding another
  post-sync step) only needs to happen in one place — the exact
  failure mode this ADR's Context section describes for the *previous*
  manual-recipe approach (README and script silently diverging).
- `--update` skipping OS/arch/binary detection entirely, rather than
  re-running the full install idempotently, is a deliberate speed and
  clarity choice: re-running the full installer already **was**
  idempotent (safe to call twice), but re-fetches five GitHub releases
  and re-runs OS prerequisite checks every time even when nothing
  about the machine's toolchain changed — `--update`'s whole purpose is
  "I know my toolchain is fine, just give me the latest config."
- `--uninstall` requiring confirmation by default (rather than acting
  immediately) matches this project's broader default of treating
  `rm -rf`-class operations as needing an explicit human go-ahead;
  `-y`/`--yes` exists specifically so the same script remains usable
  non-interactively (CI, automation) without forcing a design where
  destructive-by-default is the only option.
- Checking `readlink` target prefix before removing a `$BIN_DIR`
  symlink (rather than removing by name alone) exists because
  `~/.local/bin` is a general-purpose personal bin directory — a
  same-named binary the user placed there for an unrelated reason must
  never be deleted just because it shares a name with something this
  script also happens to install.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| Keep `--update` as a documented manual recipe (README-only), no script support | This is exactly the gap that motivated this ADR — a manual recipe silently drifts from what the script actually needs (already happened once: the recipe didn't mention `MasonToolsInstallSync`, which became necessary the moment ADR-0003 added new mason tools). |
| `--uninstall` deletes unconditionally, no confirmation prompt | Rejected as too dangerous for a multi-directory `rm -rf` operation a user might invoke by habit or typo; the `-y`/`--yes` escape hatch already covers the legitimate non-interactive case. |
| `--uninstall` also removes system packages (`git`, `curl`, compiler) installed during install | These are shared system resources that may be used by other tools entirely unrelated to this config; removing them would be a surprising, likely-unwanted side effect disproportionate to "uninstall my nvim config." |
| Separate scripts (`update.sh`, `uninstall.sh`) instead of subcommands of `bootstrap.sh` | Splits the install/update/uninstall lifecycle's shared logic (`fetch_and_unpack`, directory paths, `sync_plugins_and_tools`) across multiple files that would need to stay in sync; a single script with subcommands keeps that logic defined exactly once. |

## Consequences
### Positive
- One command (`bootstrap.sh --update`) replaces a multi-step manual
  recipe, and cannot drift from what a fresh install actually does,
  since both paths call the same `sync_plugins_and_tools` function.
- A user can now fully and confidently reset their environment
  (`--uninstall`) to test a clean install or stop using this config,
  with the exact removal list shown up front before anything happens.
- `-y`/`--yes` makes `--uninstall` usable from automation (e.g. a CI
  job testing the full install/uninstall cycle) without requiring a
  TTY.

### Negative / Risks
- `--uninstall`'s directory list is a hardcoded, manually-maintained
  set of paths — if a future change to `bootstrap.sh` starts writing
  to a new location, `--uninstall` will not know to clean it up unless
  updated in the same change. Mitigated only by code review discipline;
  no automated check ties install-side paths to uninstall-side removal.
- `git pull --ff-only` in `cmd_update` will fail (rather than silently
  doing something unexpected) if the local `$CONFIG_DIR` has diverged
  history or uncommitted conflicting changes — treated as acceptable:
  failing loudly with git's own error message is preferable to any
  form of automatic merge/rebase/discard on a user's local edits.

## Compliance / Verification
- `bash -n bootstrap.sh` confirms syntax validity after the
  restructure; `--help` and an unrecognized-flag case were both
  exercised directly to confirm dispatch and exit codes.
- `--uninstall` was exercised with a `n` (decline) response to confirm
  the confirmation gate aborts cleanly (exit 1, nothing removed) before
  this ADR was written — the destructive path itself is not covered by
  an automated test, consistent with this repo having no test suite;
  manual verification is the standing practice (see ADR-0001's
  Compliance section for the same caveat applied to the base
  installer).

## Related ADRs
- ADR-0001 (binary-only bootstrap) — the base script this ADR adds
  subcommands to; the exact set of directories/symlinks `--uninstall`
  removes is precisely what ADR-0001's install path creates.
- ADR-0002 (plugin/LSP tool management) — `sync_plugins_and_tools`,
  shared between `--update` and fresh install, is this ADR's use of
  that mechanism.
