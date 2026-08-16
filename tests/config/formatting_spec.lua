local this_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local helpers = dofile(this_dir .. "helpers.lua")

describe("formatting (conform.nvim + ruff)", function()
    it("fixes spacing without touching the file on disk", function()
        local bufnr = helpers.edit_fixture("python_project/messy_format.py")
        local before = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

        require("conform").format({ bufnr = bufnr, lsp_fallback = true, async = false, timeout_ms = 5000 })

        local after = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
        assert.is_not.equal(before, after)
        assert.equals("def foo(x):\n    y = 1\n    return x + y", after)
        assert.is_true(vim.bo[bufnr].modified, "buffer should be dirty until :w")

        vim.cmd("bdelete!")
    end)

    it("<leader>mp keymap is bound to format-now, not tied to :w", function()
        local map = vim.fn.maparg(vim.g.mapleader .. "mp", "n", false, true)
        assert.is_true(next(map) ~= nil, "<leader>mp is not mapped")
        assert.equals("Format buffer", map.desc)
    end)
end)
