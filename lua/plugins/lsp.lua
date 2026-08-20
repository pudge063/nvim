return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "saghen/blink.cmp",
        "b0o/schemastore.nvim",
    },
    config = function()
        require("mason").setup()

        -- mason-tool-installer owns the actual blocking install (used by
        -- bootstrap.sh via `:MasonToolsInstallSync`, headless-safe).
        require("mason-tool-installer").setup({
            ensure_installed = {
                "pyright", "ruff", "lua_ls", "clangd",
                "yamlls", "terraformls", "dockerls", "bashls", "cmake",
                "debugpy",
                "stylua", "prettier", "taplo",
            },
        })

        -- native vim.lsp.config/vim.lsp.enable API (Neovim >= 0.11).
        -- mason-lspconfig wires vim.lsp.enable() for everything below
        -- once mason-tool-installer has them on disk.
        require("mason-lspconfig").setup({
            ensure_installed = {
                "pyright", "ruff", "lua_ls", "clangd",
                "yamlls", "terraformls", "dockerls", "bashls", "cmake",
            },
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

        -- C/C++: clangd. Reads compile_commands.json (or falls back to a
        -- guess) for accurate diagnostics/completion; --header-insertion
        -- keeps auto-includes from adding IWYU-style forward decls we don't want.
        vim.lsp.config("clangd", {
            cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=never" },
        })

        -- DevOps/platform: k8s manifests, GitHub/GitLab CI, Ansible, docker-compose
        -- all live in plain .yaml with no discoverable schema of their own, so
        -- SchemaStore.nvim's catalog is what gives yamlls anything to validate against.
        vim.lsp.config("yamlls", {
            settings = {
                yaml = {
                    schemaStore = { enable = false, url = "" }, -- disable built-in, use schemastore.nvim's catalog instead
                    schemas = require("schemastore").yaml.schemas(),
                },
            },
        })

        -- terraformls, dockerls, bashls, cmake: mason-lspconfig enables them
        -- with sane defaults once mason-tool-installer has the binaries down —
        -- no per-server settings needed here.

        vim.diagnostic.config({
            virtual_text = true,
            severity_sort = true,
            float = { border = "rounded", source = true },
        })

        -- <leader>rn (below) triggers this like VSCode's F2: it edits every
        -- file the rename touches, in memory, across all open/newly-opened
        -- buffers — but leaves them dirty, silently, unless something saves
        -- them. Wrap the default handler to auto-save exactly the buffers
        -- the workspace edit touched (never unrelated dirty buffers).
        local default_rename_handler = vim.lsp.handlers["textDocument/rename"]
        vim.lsp.handlers["textDocument/rename"] = function(err, result, ctx, config)
            default_rename_handler(err, result, ctx, config)
            if not result then
                return
            end
            local uris = {}
            for uri in pairs(result.changes or {}) do
                uris[uri] = true
            end
            for _, change in ipairs(result.documentChanges or {}) do
                if change.textDocument and change.textDocument.uri then
                    uris[change.textDocument.uri] = true
                end
            end
            for uri in pairs(uris) do
                local bufnr = vim.uri_to_bufnr(uri)
                if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].modified then
                    vim.api.nvim_buf_call(bufnr, function()
                        vim.cmd("silent update")
                    end)
                end
            end
        end

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

                -- Highlight other occurrences of the symbol under the cursor
                -- (colors set in autocmds.lua's ColorScheme handler, linked
                -- to Visual so they're visible under any theme). Not every
                -- server advertises this (e.g. ruff doesn't), hence the
                -- capability check.
                if client and client:supports_method("textDocument/documentHighlight") then
                    local group = vim.api.nvim_create_augroup("lsp-document-highlight-" .. ev.buf, { clear = true })
                    vim.api.nvim_create_autocmd("CursorHold", {
                        group = group,
                        buffer = ev.buf,
                        callback = vim.lsp.buf.document_highlight,
                    })
                    vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
                        group = group,
                        buffer = ev.buf,
                        callback = vim.lsp.buf.clear_references,
                    })
                    vim.api.nvim_create_autocmd("LspDetach", {
                        group = group,
                        buffer = ev.buf,
                        callback = vim.lsp.buf.clear_references,
                    })
                end

                local opts = { buffer = ev.buf }
                local map = vim.keymap.set
                opts.desc = "Go to definition"
                map("n", "gd", vim.lsp.buf.definition, opts)
                -- split first, then jump in it — vim.lsp.buf.definition()
                -- always jumps in the current window, so this is the trick
                -- to land the definition beside the original file instead
                -- of replacing it.
                opts.desc = "Go to definition (vertical split)"
                map("n", "<leader>gd", function()
                    vim.cmd("vsplit")
                    vim.lsp.buf.definition()
                end, opts)
                opts.desc = "Go to declaration"
                map("n", "gD", vim.lsp.buf.declaration, opts)
                opts.desc = "Go to references"
                map("n", "gr", vim.lsp.buf.references, opts)
                -- pyright doesn't advertise implementationProvider at all
                -- (verified in tests/config/lsp_spec.lua), so this is a
                -- no-op for Python — kept for LSPs that do support it.
                opts.desc = "Go to implementations (not supported by pyright)"
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
