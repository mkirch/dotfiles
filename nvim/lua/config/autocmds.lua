-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Ghostty: refresh tab title when cwd changes
if vim.fn.getenv("TERM_PROGRAM") == "ghostty" then
	vim.api.nvim_create_autocmd("DirChanged", {
		callback = function()
			vim.opt.titlestring = "%{fnamemodify(getcwd(), ':t')} — %{expand('%:t')}"
		end,
	})
end

-- Python: 4-space indent, 88-char line width (ruff/black default)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.expandtab = true
		vim.opt_local.textwidth = 88
	end,
})
