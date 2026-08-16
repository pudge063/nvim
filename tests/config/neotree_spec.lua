-- Exercises the actual <leader>e callback registered in neo-tree.lua
-- (not a reimplementation) through its three states: closed, open+focused
-- elsewhere, open+focused-on-tree.
local function neotree_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
            return win
        end
    end
    return nil
end

--- @param expect_open boolean whether this press should result in the tree
---   being open (true) or closed (false) — neo-tree's first-ever open is
---   noticeably slower than later ones (cold-starts its sources), so poll
---   for the actual expected end state instead of a fixed short sleep.
---
--- Simulates a *real* keypress via feedkeys rather than fetching and
--- calling the mapping's callback directly: lazy.nvim wraps `keys`-defined
--- mappings to lazy-load the plugin on first use, and that wrapper only
--- behaves correctly when driven through the normal key-dispatch path —
--- calling it as a bare Lua function skips whatever it relies on there
--- and silently no-ops on the very first invocation in a process.
local function press_leader_e(expect_open)
    local keys = vim.api.nvim_replace_termcodes("<leader>e", true, false, true)
    vim.api.nvim_feedkeys(keys, "mtx", false)
    vim.wait(3000, function()
        return (neotree_win() ~= nil) == expect_open
    end, 100)
end

describe("neo-tree smart toggle (<leader>e)", function()
    after_each(function()
        pcall(vim.cmd, "Neotree close")
    end)

    it("opens and focuses the tree when it's closed", function()
        assert.is_nil(neotree_win())
        press_leader_e(true)
        local win = neotree_win()
        assert.is_not_nil(win, "tree did not open")
        assert.equals(win, vim.api.nvim_get_current_win())
    end)

    it("focuses (not closes) the tree when it's open but you're elsewhere", function()
        press_leader_e(true) -- open + focus
        local tree_win = neotree_win()
        vim.cmd("wincmd p") -- jump to the previous (non-tree) window
        assert.is_not.equal(tree_win, vim.api.nvim_get_current_win())

        press_leader_e(true)
        assert.is_not_nil(neotree_win(), "tree got closed instead of focused")
        assert.equals(tree_win, vim.api.nvim_get_current_win())
    end)

    it("closes the tree when pressed while already focused on it", function()
        press_leader_e(true) -- open + focus
        assert.is_not_nil(neotree_win())

        press_leader_e(false) -- already focused -> should close
        assert.is_nil(neotree_win(), "tree stayed open")
    end)
end)
