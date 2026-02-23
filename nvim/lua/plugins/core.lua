return {

	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight",
		},
	},

	{
		"folke/trouble.nvim",
		opts = { use_diagnostic_signs = true },
	},

	-- LSP: only configure what LazyVim extras don't handle
	-- Python (pyright + ruff) is managed by lazyvim.plugins.extras.lang.python
	-- TypeScript is managed by lazyvim.plugins.extras.lang.typescript
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tailwindcss = {
					filetypes_exclude = { "markdown" },
					filetypes_include = {},
				},
				pyright = {
					settings = {
						python = {
							analysis = {
								autoImportCompletions = true,
								typeCheckingMode = "basic",
								diagnosticMode = "workspace",
								useLibraryCodeForTypes = true,
								autoSearchPaths = true,
								diagnosticSeverityOverrides = {
									reportUnusedImport = "none",
									reportUnusedVariable = "none",
									reportUnusedClass = "warning",
									reportUnusedFunction = "warning",
									reportMissingImports = "warning",
								},
							},
							venvPath = ".",
							venv = ".venv",
						},
					},
				},
			},
			setup = {
				tailwindcss = function(_, opts)
					local ok, tw = pcall(require, "lspconfig.configs.tailwindcss")
					if not ok then
						return
					end
					opts.filetypes = opts.filetypes or {}
					vim.list_extend(opts.filetypes, tw.default_config.filetypes)

					--- @param ft string
					opts.filetypes = vim.tbl_filter(function(ft)
						return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
					end, opts.filetypes)

					opts.settings = {
						tailwindCSS = {
							includeLanguages = {
								elixir = "html-eex",
								eelixir = "html-eex",
								heex = "html-eex",
							},
						},
					}

					vim.list_extend(opts.filetypes, opts.filetypes_include or {})
				end,
			},
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			local desired = {
				"bash",
				"css",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"rust",
				"swift",
				"tsx",
				"typescript",
				"vim",
				"yaml",
			}
			for _, lang in ipairs(desired) do
				if not vim.tbl_contains(opts.ensure_installed, lang) then
					table.insert(opts.ensure_installed, lang)
				end
			end
			opts.auto_install = true
			opts.highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			}
			opts.indent = {
				enable = true,
				disable = { "python" },
			}
			opts.incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			}
		end,
	},

	-- Formatting: ruff for python, conform handles the rest via LazyVim extras
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				python = { "ruff_format" },
			},
			format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			},
		},
	},

	-- Linting: ruff for python
	{
		"mfussenegger/nvim-lint",
		opts = {
			linters_by_ft = {
				python = { "ruff" },
			},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			local lazy_status = require("lazy.status")
			opts.options = opts.options or {}
			opts.options.globalstatus = true
			opts.sections = opts.sections or {}
			opts.sections.lualine_x = opts.sections.lualine_x or {}

			table.insert(opts.sections.lualine_x, 1, {
				lazy_status.updates,
				cond = lazy_status.has_updates,
				color = { fg = "#89b4fa" },
			})
		end,
	},

	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"stylua",
				"shellcheck",
				"shfmt",
				"pyright",
				"ruff",
				"debugpy",
				"eslint_d",
				"prettierd",
				"tailwindcss-language-server",
			},
			automatic_installation = true,
		},
	},
}
