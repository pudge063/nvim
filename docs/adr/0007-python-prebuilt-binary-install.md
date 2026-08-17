# ADR-0007: Python via python-build-standalone Prebuilt Binary

## Status
Accepted, 2026-08-17

## Context
`mason-tool-installer`'s `ensure_installed` list (ADR-0002) includes two
packages that install into a Python venv rather than via npm or a GitHub
release binary: `debugpy` and `cmake-language-server` (both PyPI packages,
installed by mason's `pypi` manager, which runs `python3 -m venv` then
`pip install` inside it). On a macOS laptop with no Homebrew and no
python.org installer, `python3` was not on `PATH` at all, which surfaced as
mason failing both installs with "cannot find python3 in installation
PATH." `bootstrap.sh`'s Linux branch had been coping with a narrower version
of the same problem — Debian/Ubuntu ships `python3` but not the `venv`
module, requiring the separate `python3-venv` apt package, called out in
the script as an explicit special case.

Apple no longer bundles a working `python3` with the OS or Xcode Command
Line Tools by default, so — consistent with ADR-0001's decision to never
install anything via Homebrew — there was no existing mechanism in this
script to get a working Python onto a fresh macOS machine at all.

## Decision
`bootstrap.sh` gains a `[6/7]` step that fetches a prebuilt CPython build
from `astral-sh/python-build-standalone`'s GitHub Releases (the
`*-install_only.tar.gz` asset for the machine's target triple), unpacks it
under `~/.local/opt/python`, and symlinks `python3`/`pip3` into
`~/.local/bin` — the same `fetch_and_unpack` + `link` pattern already used
for Neovim/ripgrep/fd/Node.js. This runs on **both** macOS and Linux,
replacing reliance on whatever `python3` the system happens to provide.

The Python minor version is pinned via `PYTHON_VERSION="3.12"` (analogous
to `NODE_VERSION`), but not the full patch version, because
python-build-standalone's asset filenames embed the exact patch and a
release-date build tag (e.g. `cpython-3.12.14+20260814-x86_64-unknown-linux-gnu-install_only.tar.gz`)
that isn't predictable ahead of time. A new `gh_release_asset_url()` helper
(alongside the existing `gh_latest_tag()`) fetches a specific tagged
release's asset list and greps for the one matching `PYTHON_VERSION` and
the current OS/arch target — the `+` in the filename is percent-encoded as
`%2B` in the actual download URL, which the matching pattern accounts for.

The Debian/Ubuntu-only `python3-venv` apt package is removed from the Linux
prerequisites branch: python-build-standalone's `install_only` build
already bundles `venv` and `pip`, so the special case no longer applies on
either OS.

## Rationale
- Keeps exactly one binary-fetch mechanism (`fetch_and_unpack`/`link`) for
  every external tool this script installs, rather than adding a
  Python-specific install path — consistent with ADR-0001's stated goal of
  a single, small, maintainable installer surface.
- python-build-standalone is the de facto standard source for portable,
  redistributable CPython builds (used by `uv`, `rye`, and others for the
  same purpose) — official GitHub Releases, no Homebrew, no compiling from
  source, fitting ADR-0001's "prebuilt binary from GitHub Releases" pattern
  exactly.
- Fixing this once for both OSes (rather than macOS-only) removes the
  `python3-venv` apt special-case entirely instead of leaving two different
  Python provisioning paths to maintain.
- Pinning only the minor version (not the patch) avoids the fragility of
  hardcoding a value that changes on every upstream release, at the cost of
  one extra API call (`gh_release_asset_url`) beyond what `gh_latest_tag`
  alone provides.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| Homebrew (`brew install python@3.12`) on macOS only | Violates ADR-0001's explicit "never via Homebrew" decision; also leaves Linux's `python3-venv` special case in place. |
| Tell the user to install Python manually (python.org installer) | Breaks the `curl \| bash` non-interactive install story that motivates ADR-0001; also what the user was already doing (a python.org framework build under `/Library/Frameworks/...`) and explicitly asked to move away from. |
| macOS-only fix, leave Linux's system `python3` + `python3-venv` apt package as-is | Would fix the reported bug with less code change, but keeps two different Python provisioning mechanisms (fetched binary vs. distro package) for no benefit, and leaves the `python3-venv` wart in place. |
| Build CPython from source in `bootstrap.sh` | Heavy (needs a full C toolchain, OpenSSL/zlib dev headers, `./configure && make`, tens of minutes), and python-build-standalone already solves exactly this problem upstream. |

## Consequences
### Positive
- `debugpy` and `cmake-language-server` (and any future PyPI-sourced mason
  package) now install correctly on a fresh macOS machine with zero
  pre-existing Python setup, matching the zero-dependency install story
  already true for Neovim/ripgrep/fd/Node.js.
- Removes the `python3-venv` apt special case from the Linux prerequisites
  branch — one less distro-specific wart, and one less thing that can be
  silently missing.
- Both OSes now get the exact same, predictable Python version (whatever
  `PYTHON_VERSION` says), rather than whatever the system happened to ship.

### Negative / Risks
- Adds a second GitHub API call pattern (`gh_release_asset_url`, matching
  by tag + regex instead of `gh_latest_tag`'s "latest release" lookup) —
  more surface area than the simpler per-tool URL templates used for
  ripgrep/fd/Node.js.
- The percent-encoding detail (`+` → `%2B` in the actual asset URL) is
  exactly the kind of thing that silently breaks if python-build-standalone
  changes its release asset naming convention — verified directly against
  a live release at the time of writing (see Compliance below), not
  assumed from documentation.
- `bootstrap.sh --update` does not re-run this step (by design — see
  ADR-0005, binaries are only touched by a full install), so an existing
  install with a broken/missing `python3` needs a full `bootstrap.sh`
  re-run, not just `--update`, to pick this up.

## Compliance / Verification
- Verified directly against the live `astral-sh/python-build-standalone`
  release tagged `20260814`: `gh_release_asset_url` correctly resolved the
  asset URL for all four target triples this script supports
  (`x86_64`/`aarch64` × `apple-darwin`/`unknown-linux-gnu`).
- Ran the full fetch → unpack → symlink → `python3 -m venv` → `pip install`
  sequence end-to-end against the real Linux x86_64 asset in an isolated
  temp `INSTALL_ROOT`/`BIN_DIR`, confirming the resulting `python3` and
  `pip3` work and can create a functioning venv.
- No automated test suite covers `bootstrap.sh` (see ADR-0001); correctness
  here was verified manually as above, same as the rest of the script.

## Related ADRs
- ADR-0001 (binary-only, package-manager-free bootstrap) — this decision
  extends that pattern to Python instead of introducing an exception to it.
- ADR-0002 (plugin/LSP tool management) — `debugpy` and
  `cmake-language-server`, the two mason packages this decision unblocks,
  are both installed through the mechanism ADR-0002 establishes.
- ADR-0005 (bootstrap install/update/uninstall lifecycle) — the Python step
  follows the same "full install only, not `--update`" rule as every other
  binary this script fetches, and `--uninstall` was extended to clean up
  `~/.local/opt/python` and its symlinks alongside the rest.
