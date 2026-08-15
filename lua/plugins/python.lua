return {
    "linux-cultist/venv-selector.nvim",
    ft = "python",
    dependencies = {
        "neovim/nvim-lspconfig",
        "nvim-telescope/telescope.nvim",
    },
    opts = {
        options = {},
    },
    keys = {
        { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select python venv" },
    },
}
