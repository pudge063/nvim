# ADR-0003: Formatter Toolchain — One Formatter per Filetype via conform.nvim

## Status
Accepted, 2026-08-16

## Context
The config formats Python (`ruff_format` + `ruff_organize_imports`)
and Lua (`stylua`) on save via `conform.nvim`, established when this
config was first built. The user's day-to-day work expanded to include
editing YAML (`.gitlab-ci.yml` and similar CI configs), TOML
(`pyproject.toml` and similar), and Markdown files with no formatter
configured for any of them — hand-broken indentation in a
`.gitlab-ci.yml` was silently left broken by both `<leader>mp` and
format-on-save, since `conform.nvim` has no formatter mapped for a
filetype it simply skips it without error.

## Decision
`lua/plugins/formatting.lua`'s `formatters_by_ft` gains three entries,
each using `conform.nvim`'s built-in formatter definition (no custom
config needed):
- `yaml = { "prettier" }`
- `toml = { "taplo" }`
- `markdown = { "prettier" }`

Both `prettier` and `taplo` are added to `mason-tool-installer`'s
`ensure_installed` list in `lsp.lua` (ADR-0002) so they install
automatically via `bootstrap.sh` / `:MasonToolsInstallSync`, the same
path as every other formatter this config uses. No LSP servers for
YAML/TOML/Markdown were added — this decision is scoped to formatting
only, not diagnostics/completion for those filetypes.

## Rationale
- One formatter per filetype, not a general-purpose multi-language
  formatter, keeps `formatters_by_ft` self-documenting: reading the
  table tells you exactly what runs on save for any given file, with
  no need to check a separate formatter-specific config file for
  language-selection logic.
- `prettier` was chosen for both YAML and Markdown (rather than a
  YAML-specific tool like `yamlfmt` for one and something else for the
  other) because a single already-mason-available tool covering two of
  the three needed filetypes is simpler to install and maintain than
  three single-purpose tools, and `prettier`'s YAML/Markdown output is
  uncontroversial (2-space indent, consistent quoting) for this user's
  files (CI configs, docs) which have no competing style convention to
  preserve.
- `taplo` for TOML specifically (not `prettier`, which does not support
  TOML) is the de facto standard formatter for the language, already
  packaged in mason's registry — no alternative was seriously in
  contention.
- Reusing the existing `mason-tool-installer` mechanism (ADR-0002)
  rather than inventing a separate install path for these two new
  tools keeps exactly one way to add a required external tool to this
  config.

## Alternatives Considered
| Option | Rejected because |
|---|---|
| `yamlfmt` for YAML instead of `prettier` | Would mean three different formatter binaries for three filetypes instead of two, for no output-quality benefit on this user's files; `prettier` was already the natural choice for Markdown, so reusing it for YAML avoids installing a fourth tool. |
| `markdownlint --fix` (or `mdformat`) for Markdown instead of `prettier` | `markdownlint` is primarily a linter with a `--fix` mode, not a formatter-first tool, and conform.nvim's ecosystem treats `prettier` as the standard Markdown formatter; no project-specific Markdown style rules exist here that would need `markdownlint`'s rule-configuration surface. |
| Adding YAML/TOML/Markdown LSP servers (yamlls, taplo-as-LSP, marksman) at the same time | Out of scope for this decision — the triggering problem was specifically "formatting doesn't fix broken indentation," not "no diagnostics/completion for these filetypes." Bundling unrelated LSP setup into this change would have obscured what this ADR is actually deciding. |
| A generic filter/normalize step in `format_on_save` instead of per-filetype formatters | conform.nvim's `formatters_by_ft` table already is the generic, filetype-dispatched mechanism — building a parallel one would duplicate existing plugin functionality for no benefit. |

## Consequences
### Positive
- `.gitlab-ci.yml`, `pyproject.toml`, and `README.md`-style files now
  format correctly both via `<leader>mp`/`\\` on demand and
  automatically on save, closing the gap that prompted this decision.
- No new formatter-specific keybindings or toggles needed — the
  existing `<leader>mp`/`<leader>uf`/`<leader>uF` mechanism (format now
  / toggle autoformat per-buffer / toggle globally) covers the new
  filetypes automatically, since it dispatches generically through
  `conform.nvim`.

### Negative / Risks
- `prettier` reformats YAML/Markdown to its own opinionated style
  (2-space indent, specific quote/spacing conventions) — a file
  authored to match a different upstream project's YAML style (e.g. a
  GitLab CI template copied from elsewhere) will be reformatted away
  from that style on save. Accepted: consistent formatting was exactly
  the goal, and `<leader>uf` (buffer-local autoformat-off toggle,
  pre-existing) is the escape hatch for the rare file where that's
  undesirable.
- Literal block scalars in YAML (`- |` shell-script blocks, as used
  in `.gitlab-ci.yml`'s `before_script`) are content, not YAML
  structure — `prettier` does not reformat their interior indentation,
  which is correct behavior but means "formatting fixed everything"
  is not literally true for such blocks; verified directly (see
  Compliance below) rather than assumed.

## Compliance / Verification
- Verified against this project's actual `.gitlab-ci.yml`: intentionally
  broken indentation (`stages :`, double-spaced `name:  ghcr.io/...`,
  `-  static-k8s`) was corrected by `require('conform').format(...)`
  run headlessly, confirming the formatter is wired up and functions
  correctly end-to-end, not just configured.
- No automated test suite covers editor configuration; correctness is
  verified manually per-change as above, and by opening the relevant
  filetype and confirming `:ConformInfo` lists the expected formatter
  as attached.

## Related ADRs
- ADR-0002 (plugin/LSP tool management) — the `mason-tool-installer`
  mechanism this decision's `prettier`/`taplo` installs run through.
- ADR-0004 (format keybinding choice) — the `\\` double-tap keybinding
  added alongside this change, for triggering the same formatters this
  ADR configures.
