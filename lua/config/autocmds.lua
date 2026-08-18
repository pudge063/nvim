-- Auto-switch nvim's cwd to the project root of whatever file you open,
-- so Telescope/grep/fd always search the right project regardless of
-- where nvim itself was launched from.
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(ev)
        local bufname = vim.api.nvim_buf_get_name(ev.buf)
        if bufname == "" or not vim.bo[ev.buf].buflisted then
            return
        end
        local root = vim.fs.root(bufname, { ".git", "pyproject.toml", "setup.py" })
        if root and root ~= vim.fn.getcwd() then
            vim.fn.chdir(root)
        end
    end,
})

-- Make plain code text (variables/identifiers/parameters) bold so it reads
-- as more prominent, without touching any theme's actual colors. Runs on
-- every `:colorscheme` switch, so it applies no matter which of the
-- installed themes (sonokai, dracula, cyberdream, ...) is active.
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        for _, group in ipairs({ "@variable", "@parameter", "Identifier" }) do
            local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
            if ok then
                hl.bold = true
                vim.api.nvim_set_hl(0, group, hl)
            end
        end

        -- LSP "highlight other occurrences of the symbol under the cursor"
        -- (wired up in lsp.lua's LspAttach). The default LspReference*
        -- groups just link to CurrentWord, which on these themes is bold-only
        -- — indistinguishable from the bold-identifier tweak above. Link to
        -- Visual instead: every theme defines it with a background distinct
        -- from normal text, so occurrences stay visible no matter which
        -- colorscheme is active.
        for _, group in ipairs({ "LspReferenceText", "LspReferenceRead", "LspReferenceWrite" }) do
            vim.api.nvim_set_hl(0, group, { link = "Visual" })
        end
    end,
})
