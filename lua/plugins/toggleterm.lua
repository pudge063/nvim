return {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
        { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    },
    opts = {
        direction = "float",
        float_opts = { border = "rounded" },
        shell = vim.o.shell,
    },
    config = function(_, opts)
        require("toggleterm").setup(opts)
        -- easy escape from terminal mode
        vim.api.nvim_create_autocmd("TermOpen", {
            pattern = "term://*toggleterm#*",
            callback = function(ev)
                vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], { buffer = ev.buf })
            end,
        })
    end,
}
