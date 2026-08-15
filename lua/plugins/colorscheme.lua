-- Several vivid/saturated themes installed side by side, compared live
-- with `:colorscheme <name>`. Only sonokai auto-activates on startup —
-- the others just register their options/highlights so switching is instant.
return {
    {
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent_background = true,
            terminal_colors = true,
            filter = "classic",
        },
        config = function(_, opts)
            require("monokai-pro").setup(opts)
            -- To activate: :colorscheme monokai-pro-classic
        end,
    },
    {
        "Mofiqul/dracula.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent_bg = true,
        },
        config = function(_, opts)
            require("dracula").setup(opts)
            -- To activate: :colorscheme dracula (or dracula-soft)
        end,
    },
    {
        "scottmckendry/cyberdream.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            transparent = true,
            saturation = 1, -- 0 = greyscale, 1 = full vividness (default)
        },
        config = function(_, opts)
            require("cyberdream").setup(opts)
            -- To activate: :colorscheme cyberdream
        end,
    },
    {
        "LunarVim/synthwave84.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("synthwave84").setup({
                glow = {
                    error_msg = true,
                    type2 = true,
                    func = true,
                    keyword = true,
                },
            })
            -- Neon glow wants an opaque background to read right, so no
            -- transparency here. To activate: :colorscheme synthwave84
        end,
    },
    {
        -- Monokai-Pro-inspired but pushed more vivid/saturated. Old-school
        -- vimscript plugin, configured via vim.g.* before the colorscheme
        -- is applied (that's why this uses `init`, not `config`).
        "sainnhe/sonokai",
        lazy = false,
        priority = 1000,
        init = function()
            vim.g.sonokai_style = "default" -- default | atlantis | andromeda | shusia | maia | espresso
            vim.g.sonokai_transparent_background = 1
            -- sonokai_enable_italic actually defaults to 0 — an earlier
            -- version of this file mistakenly turned it on. Comments get
            -- italic from a *separate* flag regardless of that setting,
            -- so kill both explicitly.
            vim.g.sonokai_enable_italic = 0
            vim.g.sonokai_disable_italic_comment = 1
            -- Same accent colors (red/orange/yellow/green/blue/purple)
            -- untouched — only brighten plain text/identifiers, which
            -- default to a slightly dim off-white (#e2e2e3).
            vim.g.sonokai_colors_override = {
                fg = { "#ffffff", "231" },
            }
        end,
        config = function()
            vim.cmd.colorscheme("sonokai")
        end,
    },
}
