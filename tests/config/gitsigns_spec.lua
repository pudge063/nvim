local this_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local helpers = dofile(this_dir .. "helpers.lua")

describe("gitsigns", function()
    it("attaches and reports a branch name inside the fixture git repo", function()
        local git_dir = helpers.fixtures_root .. "/python_project/.git"
        assert.equals(1, vim.fn.isdirectory(git_dir), "fixture .git is missing — run `make setup` first")

        local bufnr = helpers.edit_fixture("python_project/sample.py")
        local ok = helpers.wait_for(function()
            return vim.b[bufnr].gitsigns_head ~= nil
        end, 10000)
        assert.is_true(ok, "gitsigns never attached / reported a HEAD")
        assert.is_true(#vim.b[bufnr].gitsigns_head > 0)

        vim.cmd("bdelete!")
    end)
end)
