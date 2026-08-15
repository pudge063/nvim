describe("autopairs", function()
    before_each(function()
        vim.cmd("enew")
        vim.bo.filetype = "python"
    end)

    after_each(function()
        vim.cmd("bdelete!")
    end)

    it("closes a bracket immediately after typing it", function()
        local keys = vim.api.nvim_replace_termcodes("i(", true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)
        assert.equals("()", vim.api.nvim_get_current_line())
    end)

    it("nests multiple pairs in the correct order", function()
        local keys = vim.api.nvim_replace_termcodes('i(["{', true, false, true)
        vim.api.nvim_feedkeys(keys, "x", false)
        assert.equals('(["{}"])', vim.api.nvim_get_current_line())
    end)
end)
