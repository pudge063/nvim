return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
        {
            "<leader>e",
            function()
                local tree_win
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
                        tree_win = win
                        break
                    end
                end
                if not tree_win then
                    vim.cmd("Neotree toggle") -- unlike `show`, this also focuses on open
                elseif vim.api.nvim_get_current_win() == tree_win then
                    vim.cmd("Neotree close")
                else
                    vim.api.nvim_set_current_win(tree_win)
                end
            end,
            desc = "Focus/open file tree (close if already focused)",
        },
    },
    opts = {
        filesystem = {
            filtered_items = {
                visible = true,
                hide_dotfiles = false,
                hide_gitignored = false,
            },
            follow_current_file = { enabled = true },
            -- Deleting/renaming *through* neo-tree's own mappings (`d`, `r`,
            -- ...) already refreshes the tree. This is for the other case:
            -- a file removed some other way (shell in a toggleterm split,
            -- `rm`, git checkout, LSP rename touching disk) — without an OS
            -- file watcher neo-tree only notices on its own next :write or
            -- manual `R` refresh, so a deleted file lingers in the tree.
            use_libuv_file_watcher = true,
        },
        window = { width = 32 },
    },
}
