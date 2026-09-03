local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })

map("n", "<leader>ur", function()
	vim.wo.relativenumber = not vim.wo.relativenumber
	vim.notify("Relative line numbers: " .. (vim.wo.relativenumber and "ON" or "OFF"), vim.log.levels.INFO)
end, { desc = "Toggle relative line numbers" })

-- window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- buffer cycling (matches the ]h/[h hunk-motion convention in gitsigns.lua)
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

-- fix space delay in terminal
vim.keymap.set("t", "<Space>", "<Space>")

-- remove all buffers which not shown in any window
vim.keymap.set("n", "<leader>bc", function()
  local buffers = vim.api.nvim_list_bufs()
  local closed = 0
  for _, buf in ipairs(buffers) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.fn.buflisted(buf) == 1 then
      -- проверяем, открыт ли буфер хоть в одном окне
      local wins = vim.fn.win_findbuf(buf)
      if #wins == 0 then
        vim.api.nvim_buf_delete(buf, { force = false })
        closed = closed + 1
      end
    end
  end
  vim.notify(closed .. " buffer(s) closed", vim.log.levels.INFO)
end, { desc = "Close buffers not shown in any window" })
