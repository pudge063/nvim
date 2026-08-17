vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.number = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.wrap = false

-- End-of-line marker. `tab` is set too so real tab characters (Makefiles
-- etc. — this config expandtabs its own edits) render as plain spaces
-- instead of `list`'s default ^I control-character notation.
opt.list = true
opt.listchars = { eol = "↵", tab = "  " }

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true

opt.splitright = true
opt.splitbelow = true

opt.undofile = true
opt.swapfile = false
opt.updatetime = 250

-- Reload buffers changed on disk outside nvim (e.g. a pre-commit hook
-- reformatting a file while it's open) — only takes effect where
-- something actually calls `:checktime` (see toggleterm.lua: wired to
-- terminal open/close, since that's the natural "left nvim, ran shell
-- commands, came back" moment). Never touches buffers with unsaved
-- changes — those just get a warning, not silently overwritten.
opt.autoread = true

-- lets pyright/ruff pick the interpreter venv-selector points at
vim.g.python3_host_prog = vim.fn.exepath("python3")
