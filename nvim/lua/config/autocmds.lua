-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Python-specific autocmds
vim.api.nvim_create_autocmd("FileType", {
	pattern = "python",
	callback = function()
		-- Set tab settings for Python (PEP 8 recommends 4 spaces)
		vim.opt_local.tabstop = 4
		vim.opt_local.shiftwidth = 4
		vim.opt_local.expandtab = true
		vim.opt_local.textwidth = 88 -- Black's default line length
		-- Enable virtual text for diagnostics
		vim.diagnostic.config({
			virtual_text = {
				severity = vim.diagnostic.severity.WARN,
			},
		}, { bufnr = 0 })
	end,
})

-- Detect uv-managed projects and configure LSP accordingly
-- uv sync creates .venv in the project root, and pyproject.toml indicates a uv project
local function is_uv_project(cwd)
	local pyproject = vim.fn.findfile("pyproject.toml", cwd .. ";")
	local venv = vim.fn.finddir(".venv", cwd .. ";")
	return pyproject ~= "" and venv ~= ""
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile", "DirChanged" }, {
	pattern = { "*.py", "pyproject.toml" },
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		local cwd = vim.fn.getcwd()

		-- Check if we're in a uv-managed project
		if is_uv_project(cwd) then
			local venv_path = vim.fn.finddir(".venv", cwd .. ";")
			venv_path = vim.fn.fnamemodify(venv_path, ":p")
			local python_path = venv_path .. "bin/python"
			local python_path_win = venv_path .. "Scripts\\python.exe"

			-- Check for Python executable (Unix or Windows)
			local has_python = vim.fn.executable(python_path) == 1 or vim.fn.executable(python_path_win) == 1

			if has_python then
				vim.schedule(function()
					local clients = vim.lsp.get_active_clients({ bufnr = buf })
					for _, client in ipairs(clients) do
						if client.name == "pyright" then
							-- Ensure pyright uses the .venv from uv sync
							-- Pyright should auto-detect via venvPath/venv settings,
							-- but we can force a workspace configuration update
							local config = client.config.settings or {}
							config.python = config.python or {}
							config.python.venvPath = "."
							config.python.venv = ".venv"
							-- Notify pyright to reload configuration
							vim.lsp.buf_notify(buf, "workspace/didChangeConfiguration", {
								settings = config,
							})
						end
					end
				end)
			end
		end
	end,
})

-- Set Python path for Neovim's Python provider when in uv projects
vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
	pattern = "*.py",
	callback = function()
		local cwd = vim.fn.getcwd()
		if is_uv_project(cwd) then
			local venv_path = vim.fn.finddir(".venv", cwd .. ";")
			venv_path = vim.fn.fnamemodify(venv_path, ":p")
			local python_path = venv_path .. "bin/python"
			if vim.fn.executable(python_path) == 1 then
				-- Update Neovim's Python provider to use uv's venv
				vim.g.python3_host_prog = python_path
			end
		end
	end,
})
