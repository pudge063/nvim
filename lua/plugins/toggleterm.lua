return {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
        { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
        -- fallback: on some macOS keyboard layouts/terminal apps Ctrl+\ is
        -- awkward to type or gets intercepted before it reaches nvim.
        { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal", mode = { "n", "t" } },
    },
    opts = {
        direction = "float",
        float_opts = { border = "rounded" },
        shell = vim.o.shell,
        -- opening the terminal (about to run shell commands) and
        -- closing/hiding it (back to editing) both count as "might have
        -- touched files on disk" — see options.lua for the autoread flag
        -- this depends on. Just an mtime stat per open buffer, runs only
        -- at these two moments (no polling), so no perf/interruption cost.
        on_open = function() vim.cmd("checktime") end,
        on_close = function() vim.cmd("checktime") end,
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
