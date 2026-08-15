local this_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
local helpers = dofile(this_dir .. "helpers.lua")

local function lsp_definition(bufnr, line, character)
    local params = vim.lsp.util.make_position_params(0, "utf-8")
    params.position = { line = line, character = character }
    local results = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 8000)
    if not results then
        return nil
    end
    for _, res in pairs(results) do
        if res.result and res.result[1] then
            return res.result[1]
        end
    end
    return nil
end

describe("python LSP (pyright + ruff)", function()
    it("both servers attach to a python buffer", function()
        local bufnr = helpers.edit_fixture("python_project/sample.py")
        helpers.wait_for_lsp(bufnr, "pyright", 15000)
        helpers.wait_for_lsp(bufnr, "ruff", 15000)
        vim.cmd("bdelete!")
    end)

    it("ruff reports an unused import", function()
        local bufnr = helpers.edit_fixture("python_project/unused_import.py")
        helpers.wait_for_lsp(bufnr, "ruff", 15000)
        local got = helpers.wait_for_diagnostics(bufnr, 10000)
        assert.is_true(got, "no diagnostics appeared")

        local found = false
        for _, d in ipairs(vim.diagnostic.get(bufnr)) do
            if d.source == "Ruff" and d.message:lower():find("unused") then
                found = true
            end
        end
        assert.is_true(found, "expected an 'unused import' diagnostic from Ruff")
        vim.cmd("bdelete!")
    end)

    it("gd follows a class up to its base class in another file", function()
        local bufnr = helpers.edit_fixture("python_project/sample.py")
        helpers.wait_for_lsp(bufnr, "pyright", 15000)
        -- give pyright a moment to finish indexing the small fixture package
        vim.wait(1000)

        -- line 4 (0-indexed 3): "class ConcreteJob(JobBase):", JobBase at col 18
        local loc = lsp_definition(bufnr, 3, 18)
        assert.is_not_nil(loc, "textDocument/definition returned nothing")
        assert.is_true(loc.uri:find("pkg/base.py") ~= nil, "expected definition in pkg/base.py, got " .. tostring(loc.uri))

        vim.cmd("bdelete!")
    end)

    it("gr (references) finds the subclass from the base class", function()
        -- NOTE: pyright does not advertise `implementationProvider` at all
        -- (verified: client.server_capabilities.implementationProvider is
        -- nil), so `gI` — despite being mapped and useful for LSPs that do
        -- support it — is a dead end for Python specifically. `gr` on the
        -- base class is the realistic way to find its subclasses. See the
        -- correction in KEYMAPS.md.
        local base_buf = helpers.edit_fixture("python_project/pkg/base.py")
        helpers.wait_for_lsp(base_buf, "pyright", 15000)
        local sample_buf = helpers.edit_fixture("python_project/sample.py") -- get it into the workspace
        helpers.wait_for_lsp(sample_buf, "pyright", 15000)
        vim.wait(1500) -- let pyright finish indexing the newly-opened file
        vim.api.nvim_set_current_buf(base_buf)

        local params = vim.lsp.util.make_position_params(0, "utf-8")
        -- line 1 (0-indexed 0) of base.py: "class JobBase:", JobBase at col 6
        params.position = { line = 0, character = 6 }
        params.context = { includeDeclaration = true }
        local results = vim.lsp.buf_request_sync(base_buf, "textDocument/references", params, 8000)

        local found_subclass_ref = false
        if results then
            for _, res in pairs(results) do
                for _, loc in ipairs(res.result or {}) do
                    if loc.uri:find("sample.py") then
                        found_subclass_ref = true
                    end
                end
            end
        end
        assert.is_true(found_subclass_ref, "expected a reference to JobBase in sample.py (ConcreteJob(JobBase))")

        vim.cmd("bufdo bdelete!")
    end)

    it("falls back to <project-root>/.venv/bin/python when no venv is manually selected", function()
        local venv_python = helpers.fixtures_root .. "/python_project/.venv/bin/python"
        assert.equals(1, vim.fn.executable(venv_python), ".venv/bin/python fixture is missing — run `make setup` first")

        local bufnr = helpers.edit_fixture("python_project/sample.py")
        helpers.wait_for_lsp(bufnr, "pyright", 15000)
        vim.wait(500)

        local client
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })) do
            client = c
        end
        assert.is_not_nil(client)
        assert.equals(venv_python, client.config.settings.python.pythonPath)

        vim.cmd("bdelete!")
    end)
end)
