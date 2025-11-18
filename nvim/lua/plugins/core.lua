return {

	-- Configure LazyVim appearance
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight",
		},
	},

	-- change trouble config
	{
		"folke/trouble.nvim",
		-- opts will be merged with the parent spec
		opts = { use_diagnostic_signs = true },
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tailwindcss = {
					-- exclude a filetype from the default_config
					filetypes_exclude = { "markdown" },
					-- add additional filetypes to the default_config
					filetypes_include = {},
					-- to fully override the default_config, change the below
					-- filetypes = {}
				},
				pyright = {
					settings = {
						python = {
							analysis = {
								autoImportCompletions = true,
								typeCheckingMode = "basic", -- Can be "off", "basic", or "strict"
								diagnosticMode = "workspace",
								-- Support for uv and pyproject.toml
								useLibraryCodeForTypes = true,
								autoSearchPaths = true,
								-- uv projects use pyproject.toml for dependency management
								diagnosticSeverityOverrides = {
									reportUnusedImport = "none", -- ruff handles this
									reportUnusedClass = "warning",
									reportUnusedFunction = "warning",
									reportUnusedVariable = "warning",
								},
							},
							-- uv sync creates .venv in project root
							-- Pyright will auto-detect this via venvPath/venv
							venvPath = ".",
							venv = ".venv",
							-- Ensure pyright respects pyproject.toml (uv's standard)
							defaultVenvPath = ".",
						},
					},
				},
				ruff_lsp = {
					init_options = {
						settings = {
							-- Only run ruff as linter, not formatter (conform.nvim handles formatting)
							args = {},
							-- Respect pyproject.toml and ruff.toml (uv projects use pyproject.toml)
							organizeImports = true,
							-- Ruff will automatically find and use pyproject.toml/ruff.toml
							-- in the workspace root (where uv sync creates it)
						},
					},
				},
			},
			setup = {
				tailwindcss = function(_, opts)
					local ok, tw = pcall(require, "lspconfig.server_configurations.tailwindcss")
					if not ok then
						return
					end
					opts.filetypes = opts.filetypes or {}

					-- Add default filetypes
					vim.list_extend(opts.filetypes, tw.default_config.filetypes)

					-- Remove excluded filetypes
					--- @param ft string
					opts.filetypes = vim.tbl_filter(function(ft)
						return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
					end, opts.filetypes)

					-- Additional settings for Phoenix projects
					opts.settings = {
						tailwindCSS = {
							includeLanguages = {
								elixir = "html-eex",
								eelixir = "html-eex",
								heex = "html-eex",
							},
						},
					}

					-- Add additional filetypes
					vim.list_extend(opts.filetypes, opts.filetypes_include or {})
				end,
				ruff_lsp = function(_, opts)
					local on_attach = opts.on_attach
					opts.on_attach = function(client, bufnr)
						if client.name == "ruff_lsp" then
							-- Disable hover provider to avoid conflicts with pyright
							client.server_capabilities.hoverProvider = false
							-- Disable document formatting (conform.nvim handles this)
							client.server_capabilities.documentFormattingProvider = false
							client.server_capabilities.documentRangeFormattingProvider = false
						end
						if on_attach then
							on_attach(client, bufnr)
						end
					end
				end,
				pyright = function(_, opts)
					-- Ensure pyright works well with ruff_lsp
					opts.settings = opts.settings or {}
					opts.settings.python = opts.settings.python or {}
					opts.settings.python.analysis = opts.settings.python.analysis or {}
					-- Disable pyright linting for things ruff handles better
					opts.settings.python.analysis.diagnosticSeverityOverrides =
						vim.tbl_extend("force", opts.settings.python.analysis.diagnosticSeverityOverrides or {}, {
							reportUnusedImport = "none",
							reportUnusedVariable = "none",
							reportMissingImports = "warning",
						})
				end,
			},
		},
	},
	-- change some telescope options and a keymap to browse plugin files
	{
		"nvim-telescope/telescope.nvim",
		keys = {
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
		},
		-- change some options
		opts = {
			defaults = {
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
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
			-- Optimize tree-sitter for better performance
			opts.auto_install = true
			opts.highlight = {
				enable = true,
				-- Use nvim-treesitter for indentation (better than built-in)
				additional_vim_regex_highlighting = false,
			}
			opts.indent = {
				enable = true,
				disable = { "python" }, -- Python indentation can be problematic, use built-in
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
			-- Note: Text objects require nvim-treesitter-textobjects plugin
			-- LazyVim's python extra may include this, or add separately if needed
		end,
	},

	{
		"stevearc/conform.nvim",
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.python = { "ruff_format" }
			-- Configure ruff_format to respect pyproject.toml
			opts.formatters = opts.formatters or {}
			opts.formatters.ruff_format = {
				prepend_args = {},
				-- ruff_format will automatically respect pyproject.toml/ruff.toml
			}
			-- Format on save
			opts.format_on_save = {
				timeout_ms = 500,
				lsp_fallback = true,
			}
		end,
	},

	{
		"mfussenegger/nvim-lint",
		opts = function(_, opts)
			opts.linters_by_ft = opts.linters_by_ft or {}
			opts.linters_by_ft.python = { "ruff" }
			-- Configure ruff linter
			opts.linters = opts.linters or {}
			opts.linters.ruff = {
				args = {
					"--quiet",
					"--format=json",
					"--stdin-filename",
					"$FILENAME",
					"-",
				},
				-- ruff will automatically respect pyproject.toml/ruff.toml
			}
			-- Auto-lint on save
			opts.autosave = true
		end,
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
			table.insert(opts.sections.lualine_x, "😄")
		end,
	},

	-- add any tools you want to have installed below
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				-- Lua
				"stylua",
				-- Shell
				"shellcheck",
				"shfmt",
				-- Python
				"pyright",
				"ruff",
				"ruff-lsp",
				"debugpy",
				"mypy", -- Optional: additional type checker
				-- JavaScript/TypeScript
				"eslint_d",
				"prettierd",
				-- Web
				"tailwindcss-language-server",
			},
			-- Auto-update on startup
			automatic_installation = true,
		},
	},
}
