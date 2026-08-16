local this_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local helpers = dofile(this_dir .. "helpers.lua")

describe("cwd auto-switch to project root", function()
    it("chdirs to the directory containing pyproject.toml on open", function()
        local start_cwd = vim.fn.getcwd()
        helpers.edit_fixture("python_project/sample.py")
        vim.wait(200)

        local expected_root = vim.fs.normalize(helpers.fixtures_root .. "/python_project")
        assert.equals(expected_root, vim.fs.normalize(vim.fn.getcwd()))

        vim.cmd("bdelete!")
        vim.fn.chdir(start_cwd)
    end)

    it("does not chdir for unnamed/unlisted buffers", function()
        local start_cwd = vim.fn.getcwd()
        vim.cmd("enew")
        vim.wait(200)
        assert.equals(start_cwd, vim.fn.getcwd())
        vim.cmd("bdelete!")
    end)
end)
