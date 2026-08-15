return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "│" },
            change = { text = "│" },
            delete = { text = "_" },
            topdelete = { text = "‾" },
            changedelete = { text = "~" },
        },
        current_line_blame = false, -- toggle on demand with <leader>tb
    },
    config = function(_, opts)
        require("gitsigns").setup(opts)
    end,
    keys = {
        {
            "]h",
            function()
                require("gitsigns").nav_hunk("next")
            end,
            desc = "Next git hunk",
        },
        {
            "[h",
            function()
                require("gitsigns").nav_hunk("prev")
            end,
            desc = "Previous git hunk",
        },
        {
            "<leader>hs",
            function()
                require("gitsigns").stage_hunk()
            end,
            mode = { "n", "v" },
            desc = "Stage hunk",
        },
        {
            "<leader>hr",
            function()
                require("gitsigns").reset_hunk()
            end,
            mode = { "n", "v" },
            desc = "Reset hunk",
        },
        {
            "<leader>hp",
            function()
                require("gitsigns").preview_hunk()
            end,
            desc = "Preview hunk",
        },
        {
            "<leader>hb",
            function()
                require("gitsigns").blame_line({ full = true })
            end,
            desc = "Blame line",
        },
        {
            "<leader>tb",
            function()
                require("gitsigns").toggle_current_line_blame()
            end,
            desc = "Toggle inline blame",
        },
    },
}
