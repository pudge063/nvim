return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
        {
            "<leader>mp",
            function()
                require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
            end,
            mode = { "n", "v" },
            desc = "Format buffer",
        },
        {
            "\\\\",
            function()
                require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 1000 })
            end,
            mode = { "n", "v" },
            desc = "Format buffer",
        },
        {
            "<leader>uf",
            function()
                vim.b.disable_autoformat = not vim.b.disable_autoformat
                vim.notify(
                    "Format on save (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"),
                    vim.log.levels.INFO
                )
            end,
            desc = "Toggle format on save (this buffer)",
        },
        {
            "<leader>uF",
            function()
                vim.g.disable_autoformat = not vim.g.disable_autoformat
                vim.notify(
                    "Format on save (global): " .. (vim.g.disable_autoformat and "OFF" or "ON"),
                    vim.log.levels.INFO
                )
            end,
            desc = "Toggle format on save (globally)",
        },
    },
    opts = {
        formatters_by_ft = {
            python = { "ruff_format", "ruff_organize_imports" },
            lua = { "stylua" },
            yaml = { "prettier" },
            toml = { "taplo" },
            markdown = { "prettier" },
        },
        format_on_save = function(bufnr)
            if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                return
            end
            return { lsp_fallback = true, timeout_ms = 500 }
        end,
    },
}
