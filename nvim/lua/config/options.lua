-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Python-specific settings
-- Try to find python3, fallback to python
vim.g.python3_host_prog = vim.fn.exepath("python3") or vim.fn.exepath("python") or ""
-- Prefer uv's python if available (uv manages Python installations)
-- Note: When working in a uv project, the autocmd will override this with the .venv python
if vim.fn.executable("uv") == 1 then
	-- Try to find Python via uv (silently fail if not available)
	local handle = io.popen("uv python find --python 3.12 2>/dev/null || uv python find --python 3.11 2>/dev/null || uv python find --python 3.10 2>/dev/null || echo ''")
	if handle then
		local uv_python = handle:read("*a")
		handle:close()
		if uv_python and uv_python ~= "" then
			uv_python = vim.fn.trim(uv_python)
			if vim.fn.executable(uv_python) == 1 then
				vim.g.python3_host_prog = uv_python
			end
		end
	end
end
