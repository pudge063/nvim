-- Buffer-local LSP keymaps (gd, gr, K, ...) are covered in lsp_spec.lua,
-- since they only exist after a client attaches. This file covers the
-- global, always-registered ones.
local function assert_mapped(key, mode)
    local map = vim.fn.maparg(vim.g.mapleader .. key, mode or "n", false, true)
    assert.is_true(next(map) ~= nil, ("<leader>%s is not mapped"):format(key))
    return map
end

describe("global keymaps", function()
    it("telescope pickers", function()
        for _, k in ipairs({ "ff", "fF", "fg", "fG", "fb", "fr", "fh", "fd", "fs", "fS" }) do
            assert_mapped(k)
        end
    end)

    it("file tree, terminal, undo, venv, formatting", function()
        assert_mapped("e")
        assert_mapped("u")
        assert_mapped("tt")
        assert_mapped("cv")
        assert_mapped("mp")
        assert_mapped("uf")
        assert_mapped("uF")
    end)

    it("gitsigns hunk actions", function()
        for _, k in ipairs({ "hs", "hr", "hp", "hb", "tb" }) do
            assert_mapped(k)
        end
        local map = vim.fn.maparg("]h", "n", false, true)
        assert.is_true(next(map) ~= nil, "]h (next hunk) is not mapped")
    end)

    it("window navigation and misc", function()
        for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
            local map = vim.fn.maparg(key, "n", false, true)
            assert.is_true(next(map) ~= nil, key .. " is not mapped")
        end
        local jk = vim.fn.maparg("jk", "i", false, true)
        assert.is_true(next(jk) ~= nil, "jk (insert-mode escape) is not mapped")
    end)
end)
