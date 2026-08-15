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
    end,
})
