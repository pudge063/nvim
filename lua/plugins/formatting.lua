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
    },
    opts = {
        formatters_by_ft = {
            python = { "ruff_format", "ruff_organize_imports" },
            lua = { "stylua" },
        },
        format_on_save = {
            lsp_fallback = true,
            timeout_ms = 500,
        },
    },
}
