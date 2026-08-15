return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
        check_ts = true, -- treesitter-aware: don't pair inside strings/comments
    },
}
