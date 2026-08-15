return {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
        },
    },
    cmd = "Telescope",
    keys = {
        { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
        { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
        { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
        { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
        -- "Search everything": hidden files + gitignored (venv, node_modules, ...)
        {
            "<leader>fF",
            function()
                require("telescope.builtin").find_files({
                    hidden = true,
                    no_ignore = true,
                    no_ignore_parent = true,
                })
            end,
            desc = "Find files (incl. hidden + gitignored)",
        },
        {
            "<leader>fG",
            function()
                require("telescope.builtin").live_grep({
                    additional_args = function()
                        return { "--hidden", "--no-ignore" }
                    end,
                })
            end,
            desc = "Live grep (incl. hidden + gitignored)",
        },
        -- class/method outline for the current file (great for OOP: jump
        -- straight to any method of the class you're in)
        { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols in file (classes/methods)" },
        -- same but project-wide: find a class/method by name anywhere
        { "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Symbols in project" },
    },
    config = function()
        local telescope = require("telescope")
        telescope.setup({
            defaults = {
                -- always skip .git internals, nothing useful to search there
                file_ignore_patterns = { "%.git/" },
                vimgrep_arguments = {
                    "rg",
                    "--color=never",
                    "--no-heading",
                    "--with-filename",
                    "--line-number",
                    "--column",
                    "--smart-case",
                    "--hidden", -- default live_grep now sees dotfiles too
                },
            },
            pickers = {
                find_files = {
                    hidden = true, -- default find_files now sees dotfiles too
                },
            },
        })
        pcall(telescope.load_extension, "fzf")
    end,
}
