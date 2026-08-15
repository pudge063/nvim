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

        -- mason-tool-installer owns the actual blocking install (used by
        -- bootstrap.sh via `:MasonToolsInstallSync`, headless-safe).
        require("mason-tool-installer").setup({
            ensure_installed = { "pyright", "ruff", "lua_ls", "stylua" },
        })

        -- native vim.lsp.config/vim.lsp.enable API (Neovim >= 0.11).
        -- mason-lspconfig wires vim.lsp.enable() for everything below
        -- once mason-tool-installer has them on disk.
        require("mason-lspconfig").setup({
            ensure_installed = { "pyright", "ruff", "lua_ls" },
        })

        local capabilities = require("blink.cmp").get_lsp_capabilities()
        vim.lsp.config("*", { capabilities = capabilities })

        -- Python: pyright for types/navigation, ruff for lint + format.
        -- venv-selector.lua points both at whichever interpreter you pick;
        -- pythonPath below is just the automatic fallback for the common
        -- case of a `.venv` sitting in the project root (see LspAttach).
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

                -- If nobody picked a venv via venv-selector yet, fall back to
                -- <project-root>/.venv so imports/go-to-definition work out
                -- of the box for the common "venv lives in the repo" case.
                if client and client.name == "pyright" and client.config.root_dir then
                    local venv_python = client.config.root_dir .. "/.venv/bin/python"
                    if not client.config.settings.python.pythonPath and vim.uv.fs_stat(venv_python) then
                        client.config.settings.python.pythonPath = venv_python
                        client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                    end
                end

                local opts = { buffer = ev.buf }
                local map = vim.keymap.set
                opts.desc = "Go to definition"
                map("n", "gd", vim.lsp.buf.definition, opts)
                opts.desc = "Go to declaration"
                map("n", "gD", vim.lsp.buf.declaration, opts)
                opts.desc = "Go to references"
                map("n", "gr", vim.lsp.buf.references, opts)
                opts.desc = "Go to implementations (subclasses/overrides)"
                map("n", "gI", vim.lsp.buf.implementation, opts)
                opts.desc = "Go to type definition"
                map("n", "gy", vim.lsp.buf.type_definition, opts)
                opts.desc = "Hover documentation"
                map("n", "K", vim.lsp.buf.hover, opts)
                opts.desc = "Rename symbol"
                map("n", "<leader>rn", vim.lsp.buf.rename, opts)
                opts.desc = "Code action"
                map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                opts.desc = "Line diagnostics"
                map("n", "<leader>d", vim.diagnostic.open_float, opts)
                opts.desc = "Signature help"
                map("i", "<C-h>", vim.lsp.buf.signature_help, opts)
                opts.desc = "Incoming calls (who calls this)"
                map("n", "<leader>ci", vim.lsp.buf.incoming_calls, opts)
                opts.desc = "Outgoing calls (what this calls)"
                map("n", "<leader>co", vim.lsp.buf.outgoing_calls, opts)
            end,
        })
    end,
}
