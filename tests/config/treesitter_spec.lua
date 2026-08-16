local this_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local helpers = dofile(this_dir .. "helpers.lua")

describe("treesitter", function()
    it("activates highlighting on a python buffer", function()
        local bufnr = helpers.edit_fixture("python_project/sample.py")
        assert.is_not_nil(vim.treesitter.highlighter.active[bufnr], "no active treesitter highlighter")

        local ok = pcall(vim.treesitter.get_parser, bufnr, "python")
        assert.is_true(ok, "vim.treesitter.get_parser() failed for python")

        vim.cmd("bdelete!")
    end)

    it("correctly parses a class definition (regression: master-branch crash)", function()
        -- This is the scenario that used to crash with
        -- "attempt to call method 'range' (a nil value)" on the old
        -- nvim-treesitter master branch (see treesitter.lua comments).
        local bufnr = helpers.edit_fixture("python_project/sample.py")
        vim.wait(500)

        -- Line 4 (0-indexed 3): "class ConcreteJob(JobBase):"
        local captures = vim.treesitter.get_captures_at_pos(bufnr, 3, 6)
        local kinds = {}
        for _, c in ipairs(captures) do
            kinds[c.capture] = true
        end
        assert.is_true(kinds["type"] == true or kinds["variable"] == true, "expected a class-name capture on 'ConcreteJob'")

        vim.cmd("bdelete!")
    end)
end)
