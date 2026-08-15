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
