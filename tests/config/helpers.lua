local M = {}

M.fixtures_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h") .. "/fixtures"

--- Open a fixture file by path relative to tests/fixtures.
function M.edit_fixture(relpath)
    vim.cmd("edit " .. vim.fn.fnameescape(M.fixtures_root .. "/" .. relpath))
    return vim.api.nvim_get_current_buf()
end

--- Block until `condition()` returns truthy or `timeout_ms` elapses.
--- Returns the same as vim.wait: true/false, code.
function M.wait_for(condition, timeout_ms)
    return vim.wait(timeout_ms or 10000, condition, 100)
end

--- Wait for at least one LSP client of `name` to attach to `bufnr`.
function M.wait_for_lsp(bufnr, name, timeout_ms)
    local ok = M.wait_for(function()
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
            if client.name == name then
                return true
            end
        end
        return false
    end, timeout_ms)
    assert(ok, ("LSP client %q never attached to buffer %d"):format(name, bufnr))
end

--- Wait until vim.diagnostic.get(bufnr) is non-empty (or timeout).
function M.wait_for_diagnostics(bufnr, timeout_ms)
    return M.wait_for(function()
        return #vim.diagnostic.get(bufnr) > 0
    end, timeout_ms)
end

return M
