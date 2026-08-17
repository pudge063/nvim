-- `master` branch is frozen/legacy and crashes on Neovim >= 0.12 (injection
-- query predicates call an internal treesitter API that changed shape —
-- shows up as "attempt to call method 'range' (a nil value)" while hovering
-- or scrolling). `main` is the actively maintained branch, but it has a
-- different, minimal API: nothing is auto-enabled, you wire up highlight
-- yourself, and `.install()` requires the `tree-sitter` CLI (see
-- bootstrap.sh) to compile parsers, not just a C compiler.
local langs = {
    "python", "lua", "vim", "vimdoc", "bash", "c", "cpp",
    "markdown", "markdown_inline", "json", "yaml", "toml",
}

return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    -- Installing via the build hook (not a manual .install() call in
    -- config()) is the officially documented path, and lazy.nvim properly
    -- waits for build hooks to finish before a plugin counts as synced —
    -- calling require('nvim-treesitter').install() by hand from config()
    -- races against the plugin's own fresh git clone and unreliably drops
    -- some languages (observed: "attempt to call field 'install' (a nil
    -- value)" while the module was still mid-load).
    build = ":TSUpdate " .. table.concat(langs, " "),
    lazy = false,
    config = function()
        require("nvim-treesitter").setup()

        -- self-heal: on a slow first bootstrap the build hook can still be
        -- mid-compile when bootstrap.sh's own wait gives up; quietly finish
        -- whatever's missing on a later, ordinary launch. pcall guards the
        -- rare case this races the plugin's own module load right after a
        -- fresh clone (harmless — it'll just retry next launch too).
        -- default install_dir is stdpath('data')/site, not the plugin's
        -- own directory under .../lazy/nvim-treesitter
        local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
        local missing = {}
        for _, lang in ipairs(langs) do
            if vim.fn.filereadable(parser_dir .. "/" .. lang .. ".so") == 0 then
                table.insert(missing, lang)
            end
        end
        if #missing > 0 then
            pcall(function()
                require("nvim-treesitter").install(missing)
            end)
        end

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "python", "lua", "vim", "help", "sh", "c", "cpp", "markdown", "json", "yaml", "toml" },
            callback = function()
                vim.treesitter.start()
            end,
        })
    end,
}
