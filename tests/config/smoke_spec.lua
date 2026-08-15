-- Baseline sanity: config loads cleanly and every plugin lazy.nvim knows
-- about is actually installed and free of load errors. Catches the class
-- of bug this repo hit repeatedly during development (stale lockfile,
-- wrong branch, plugin crashing on require) before it reaches a real file.
describe("config bootstrap", function()
    it("starts with no error/warning messages", function()
        local messages = vim.fn.execute("messages")
        assert.equals("", vim.trim(messages))
    end)

    it("registers plugins with lazy.nvim and none failed to load", function()
        local ok, lazy_stats = pcall(function()
            return require("lazy").stats()
        end)
        assert.is_true(ok, "lazy.nvim did not load")
        assert.is_true(lazy_stats.count > 0, "no plugins registered")

        local plugins = require("lazy.core.config").plugins
        local broken = {}
        for name, plugin in pairs(plugins) do
            if not plugin._.installed or vim.fn.isdirectory(plugin.dir) == 0 then
                table.insert(broken, name)
            end
        end
        assert.same({}, broken, "plugins missing on disk: " .. table.concat(broken, ", "))
    end)

    it("applies a colorscheme without error", function()
        assert.is_not_nil(vim.g.colors_name)
        assert.is_true(#vim.g.colors_name > 0)
    end)

    it("has treesitter parsers for the languages this config installs", function()
        local langs = { "python", "lua", "vim", "vimdoc", "bash", "markdown", "markdown_inline", "json", "yaml", "toml" }
        local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local missing = {}
        for _, lang in ipairs(langs) do
            if vim.fn.filereadable(parser_dir .. "/" .. lang .. ".so") == 0 then
                table.insert(missing, lang)
            end
        end
        assert.same({}, missing, "missing compiled parsers: " .. table.concat(missing, ", "))
    end)

    it("has mason-installed LSP/formatter tools on disk", function()
        local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
        for _, tool in ipairs({ "pyright-langserver", "ruff", "lua-language-server", "stylua" }) do
            local found = vim.fn.filereadable(mason_bin .. "/" .. tool) == 1
                or vim.fn.executable(mason_bin .. "/" .. tool) == 1
            assert.is_true(found, tool .. " not found in mason bin dir")
        end
    end)
end)
