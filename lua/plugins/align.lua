-- Manual column alignment (e.g. lining up `=` or `:` across several lines).
-- Different from ruff's formatting.lua: this is for cases you want to
-- align by hand, not something ruff/PEP8 has an opinion about.
return {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
        require("mini.align").setup()
    end,
}
