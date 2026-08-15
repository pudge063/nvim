return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "saghen/blink.cmp",
    },
    config = function()
        require("mason").setup()

        require("mason-tool-installer").setup({
            ensure_installed = { "stylua" },
        })

        -- native vim.lsp.config/vim.lsp.enable API (Neovim >= 0.11).
        -- mason-lspconfig installs the servers and calls vim.lsp.enable()
        -- for everything in ensure_installed once they're on disk.
        require("mason-lspconfig").setup({
            ensure_installed = { "pyright", "ruff", "lua_ls" },
        })

        local capabilities = require("blink.cmp").get_lsp_capabilities()
        vim.lsp.config("*", { capabilities = capabilities })

        -- Python: pyright for types/navigation, ruff for lint + format.
        -- venv-selector.lua points both at whichever interpreter you pick,
        -- and pyright also auto-detects a `.venv` in the project root.
        vim.lsp.config("pyright", {
            settings = {
                python = {
                    analysis = {
                        typeCheckingMode = "basic",
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                        diagnosticMode = "openFilesOnly",
                    },
                },
            },
        })

        vim.lsp.config("ruff", {})

        vim.lsp.config("lua_ls", {
            settings = {
                Lua = { diagnostics = { globals = { "vim" } } },
            },
        })

        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = { border = "rounded", source = true },
        })

        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                -- ruff only lints/formats; let pyright own hover to avoid duplicate popups
                if client and client.name == "ruff" then
                    client.server_capabilities.hoverProvider = false
                end

                local opts = { buffer = ev.buf }
                local map = vim.keymap.set
                opts.desc = "Go to definition"
                map("n", "gd", vim.lsp.buf.definition, opts)
                opts.desc = "Go to references"
                map("n", "gr", vim.lsp.buf.references, opts)
                opts.desc = "Hover documentation"
                map("n", "K", vim.lsp.buf.hover, opts)
                opts.desc = "Rename symbol"
                map("n", "<leader>rn", vim.lsp.buf.rename, opts)
                opts.desc = "Code action"
                map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                opts.desc = "Line diagnostics"
                map("n", "<leader>d", vim.diagnostic.open_float, opts)
            end,
        })
    end,
}
