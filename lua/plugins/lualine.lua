return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
        vim.opt.showtabline = 2 -- always show the top bar, even with one tab
    end,
    opts = {
        options = {
            theme = "auto", -- matches whichever colorscheme.lua theme is active
        },
        -- rendered into the tabline (top of screen) instead of the
        -- statusline (bottom) — same content, just moved up
        tabline = {
            lualine_a = { "mode" },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = { { "filename", path = 1 } }, -- relative path
            lualine_x = { "filetype" },
            lualine_y = { "progress" },
            lualine_z = { "location" },
        },
        sections = {}, -- nothing at the bottom anymore
        inactive_sections = {},
    },
}
