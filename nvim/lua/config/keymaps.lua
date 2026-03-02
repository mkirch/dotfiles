-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua

local map = vim.keymap.set

-- Exit insert mode with jk (home row, no hand movement)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Centered scrolling (eyes stay mid-screen)
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up (centered)" })

-- Centered search results
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centered)" })

-- Paste over selection without losing register
map("x", "p", [["_dP]], { desc = "Paste without yank" })

-- Delete single char to black hole (don't pollute register)
map({ "n", "v" }, "x", [["_x]], { desc = "Delete char (no yank)" })

-- Join lines without moving cursor
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- Move lines up/down in visual mode (complement to LazyVim's Alt+j/k)
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode after indent
map("v", "<", "<gv", { desc = "Indent left (stay visual)" })
map("v", ">", ">gv", { desc = "Indent right (stay visual)" })
