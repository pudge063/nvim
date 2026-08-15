return {
    "saghen/blink.cmp",
    version = "1.*",
    event = "InsertEnter",
    opts = {
        -- Enter accepts, Up/Down/C-n/C-p select, Tab/S-Tab only for snippet jumps
        keymap = { preset = "enter" },
        appearance = { nerd_font_variant = "mono" },
        sources = {
            default = { "lsp", "path", "buffer" },
        },
        completion = {
            documentation = { auto_show = true },
        },
    },
}
