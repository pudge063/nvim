# ADR-0001: Binary-Only, Package-Manager-Free Bootstrap

## Status
Accepted, 2026-08-15

## Context
This config needs to install cleanly onto machines this user actually
works from: personal macOS laptops with no Homebrew installed, and
disposable Linux dev servers (Debian/Ubuntu or RHEL-family) where
`sudo` may or may not be available and distro package repositories
often ship stale versions of fast-moving tools (`ripgrep`, `fd`,
Neovim itself). The installer (`bootstrap.sh`) has to produce a
working, fully-featured setup (LSP, Telescope, treesitter) from a
single command, without assuming any package manager beyond what the
OS ships by default, and without requiring interactive prompts that
would break `curl | bash` usage.

## Decision
`bootstrap.sh` installs Neovim, ripgrep, fd, the `tree-sitter` CLI, and
Node.js as **prebuilt binary releases fetched directly from their
GitHub Releases / nodejs.org**, unpacked under `~/.local/opt/<tool>`
and symlinked into `~/.local/bin`. No Homebrew, no `apt`/`dnf` package
for any of these five tools, on either OS.

The **only** things installed via a system package manager are the
bare prerequisites needed to fetch and use the above: `git`, `curl`,
`tar`, and a C compiler (needed by treesitter to compile parsers) —
and only on Linux, only if missing (`apt-get install` on Debian/Ubuntu,
`dnf install` on RHEL-family), gated behind `sudo`. On macOS the
equivalent (git + compiler) comes from Xcode Command Line Tools, which
the script attempts to install non-interactively via the
`softwareupdate` CLT trick — never via Homebrew.

Architecture detection (`uname -m` → `x86_64`/`arm64`) picks the right
release asset per tool; OS detection (`uname -s`) picks the right
Neovim release name (`nvim-macos-*` vs `nvim-linux-*`) and Linux distro
family for the prerequisite step.

## Rationale
- Distro-packaged `ripgrep`/`fd` on Debian/Ubuntu LTS are frequently
  version-locked far behind upstream (missing flags Telescope's config
  relies on, e.g. `--smart-case` behavior nuances) — fetching the
  GitHub release sidesteps this permanently rather than chasing PPAs.
- Homebrew is explicitly avoided on macOS because it is not guaranteed
  to be present on a fresh laptop, and installing Homebrew itself is a
  heavier, slower, more failure-prone operation (its own network
  fetch + ruby bootstrap) than fetching five static binaries directly.
- Installing everything under `~/.local` means **no `sudo` is ever
  needed for the tools nvim actually depends on** — only for the small,
  genuinely-system-level prerequisite packages, and only when they're
  missing at all (common on a fresh Linux dev server, rare on an
  already-provisioned one).
- A single script working identically on both target OSes (same
  fetch/unpack/symlink functions, only the release-asset URL template
  differs) keeps the installer's surface area small enough to actually
  maintain.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| Homebrew on macOS for Neovim/ripgrep/fd | Requires Homebrew to be present or installs it as a heavyweight prerequisite; also loses control over exact pinned versions vs. a direct GitHub release fetch. |
| Distro packages on Linux (`apt install neovim ripgrep fd-find`) | Versions in Debian/Ubuntu LTS repos lag upstream significantly; `fd-find` is even packaged under a different binary name (`fdfind`) on Debian, an extra inconsistency to work around for no benefit. |
| A language-specific package manager (e.g. `cargo install ripgrep fd-find`) | Requires a working Rust toolchain as a prerequisite — heavier and slower than downloading a static binary, and not needed for anything else in this config. |
| Docker/devcontainer-based distribution | Adds a container runtime as a hard dependency and doesn't match how this user actually works (editing directly on the host, including bare-metal dev servers). |

## Consequences
### Positive
- Works identically, with the same script, on a brand-new macOS laptop
  with zero developer tooling and on a minimal Linux dev server.
- No `sudo` required at all on a machine that already has `git`, `curl`,
  `tar`, and a compiler — the common case for pre-provisioned dev
  servers.
- Tool versions are exactly whatever the latest GitHub release is at
  install time, not whatever a distro happened to package — predictable
  and current.

### Negative / Risks
- No automatic security-patch delivery the way a system package manager
  provides — a stale install only gets newer binaries via re-running
  `bootstrap.sh`, mitigated by `--update` (ADR-0005) making that a
  single command rather than a full reinstall.
- Depends on GitHub Releases / nodejs.org being reachable and rate-limit
  headroom on the (unauthenticated) GitHub API call in `gh_latest_tag`
  — accepted as a risk given this only runs at install/update time, not
  on every nvim startup.
- Binaries under `~/.local/opt` and their symlinks are specific to this
  script's own bookkeeping; `--uninstall` (ADR-0005) has to know this
  exact layout to clean up correctly rather than being able to defer to
  a package manager's own removal command.

## Compliance / Verification
- `bootstrap.sh` is idempotent by construction (`fetch_and_unpack`
  always `rm -rf`s the destination before unpacking) — re-running it is
  the de facto regression check; there is no separate automated test
  suite for the installer.
- Nothing currently enforces that a contributor adding a new external
  tool dependency follows this same binary-only pattern — that's a
  manual review expectation when reading a `bootstrap.sh` diff.

## Related ADRs
- ADR-0002 (plugin/LSP tool management via lazy.nvim + mason) — the
  layer above this one; mason's own tool installs (pyright, ruff,
  stylua, prettier, taplo) run entirely on top of the Node.js/compiler
  foundation this ADR establishes.
- ADR-0005 (bootstrap install/update/uninstall lifecycle) — extends
  this same script with the update and full-removal commands.
