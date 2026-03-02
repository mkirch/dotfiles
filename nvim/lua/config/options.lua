-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

-- Ghostty: set tab title to project + file for tab identification
if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
	vim.opt.title = true
	vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} — %{expand('%:t')}"
end

-- Keep 8 lines of context visible above/below cursor
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Relative line numbers for easy jump-counting (5j, 12k, etc.)
vim.opt.relativenumber = true

-- Persistent undo across sessions (survives quitting nvim)
vim.opt.undofile = true
vim.opt.undolevels = 10000

-- Faster completion and CursorHold triggers
vim.opt.updatetime = 200

-- Smoother experience in Ghostty (already true-color capable)
vim.opt.termguicolors = true

-- Python provider: simple lookup, no blocking shell calls
-- The .venv/bin/python is handled by pyright's venvPath config in core.lua
vim.g.python3_host_prog = vim.fn.exepath("python3") or vim.fn.exepath("python") or ""
