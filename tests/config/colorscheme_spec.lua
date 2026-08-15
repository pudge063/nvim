describe("colorscheme", function()
    it("sonokai is active by default", function()
        assert.equals("sonokai", vim.g.colors_name)
    end)

    it("switches cleanly to every other installed theme", function()
        for _, name in ipairs({ "dracula", "dracula-soft", "cyberdream", "synthwave84", "monokai-pro-classic" }) do
            local ok, err = pcall(vim.cmd.colorscheme, name)
            assert.is_true(ok, ("colorscheme %q failed: %s"):format(name, tostring(err)))
        end
        vim.cmd.colorscheme("sonokai") -- restore, in case other specs run in this process
    end)

    it("keeps keyword color untouched by the brightness/italic overrides", function()
        vim.cmd.colorscheme("sonokai")
        local kw = vim.api.nvim_get_hl(0, { name = "@keyword", link = false })
        assert.equals(0xfc5d7c, kw.fg)
    end)

    it("bolds plain-text groups on every theme switch (ColorScheme autocmd)", function()
        vim.cmd.colorscheme("dracula")
        local var_hl = vim.api.nvim_get_hl(0, { name = "@variable", link = false })
        assert.is_true(var_hl.bold)
        vim.cmd.colorscheme("sonokai")
    end)
end)
