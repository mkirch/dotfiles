<div align="center">
  <h1>@mkirch's Dotfiles and Settings</h1>
  <img src="https://img.shields.io/github/languages/top/mkirch/dotfiles?color=blue&label=Shell&logo=gnu-bash&logoColor=white" alt="Shell">
  <img src="https://img.shields.io/github/languages/top/mkirch/dotfiles?color=blue&label=Lua&logo=lua&logoColor=white" alt="Lua">
  <img src="https://img.shields.io/github/last-commit/mkirch/dotfiles?color=green&label=Last%20Commit&logo=git&logoColor=white" alt="Last Commit">
  <img src="https://img.shields.io/github/issues/mkirch/dotfiles?color=yellow&label=Issues&logo=github&logoColor=white" alt="Issues">
  <img src="https://img.shields.io/github/license/mkirch/dotfiles?color=blue&label=License&logo=open-source-initiative&logoColor=white" alt="License">
</div>

This repository contains my personal dotfiles. These are the base configurations I use for my development environment setup.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Environment Variables](#environment-variables)
- [Configuration Files](#configuration-files)
- [Scripts](#scripts)
- [Fonts](#fonts)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)

## Installation

```bash
# Clone the repository
git clone https://github.com/mkirch/dotfiles.git

# Navigate to the directory
cd dotfiles

# Optionally create a .env file in the repo with your personal settings
# (it will be copied to ~/.dotfiles.env by update.sh)
cp .env.example .env
$EDITOR .env

# Sync the configs into place (copies .env → ~/.dotfiles.env)
./scripts/update.sh
```

## Usage

`DOTLOC` is automatically detected from the repository location when you're inside the cloned directory. Create a `.env` file in the repo root with your personal settings—it will be automatically copied to `~/.dotfiles.env` by `update.sh` and sourced by both `~/.zshenv` and `~/.zshrc`. After making edits to `.env`, rerun `./scripts/update.sh` to resync everything back into `$HOME`.

## Environment Variables

- `DOTLOC`: Absolute path to this repository; auto-detected from repo location (optional override).
- `DEV_HOME`: Root directory for personal projects (defaults to `$HOME/Developer`).
- `WHISPER_CPP_DIR`: Location of the compiled `whisper.cpp` checkout; used by `scripts/whisper_transcription.sh`.
- `CURSOR_USER_DATA_DIR` / `CURSOR_EXTENSIONS_DIR`: Personal/Work profile directories that stay outside the repo.
- `CLAUDE_BINARY`: Optional path to a local Claude CLI build.

Create a `.env` file in the repo root (copy from `.env.example`), update the values for your machine, and keep it out of source control (already gitignored). The `update.sh` script will copy it to `~/.dotfiles.env`, which is then sourced by both `~/.zshenv` and `~/.zshrc`. `DOTLOC` is auto-detected, so you only need to set it if you want to override the default behavior. You can also set `DOTFILES_ENV_FILE` if you prefer a different location for the env file.

## Configuration Files

This repository includes configuration for the shell, terminal emulator, editor, and prompt:

- `zsh/.zshenv`: Minimal environment (PATH, telemetry opt-outs) loaded for every `zsh` process.
- `zsh/.zshrc`: Interactive shell setup powered by Znap, Powerlevel10k, and a curated alias/toolchain list.
- `zsh/.zsh_aliases`: Private aliases file (gitignored); copy `zsh/.zsh_aliases.example` to `zsh/.zsh_aliases` and add your personal aliases.
- `p10k/.p10k.zsh`: Prompt customisations used by Powerlevel10k.
- `ghostty/config`: Theme, font, and keybinding preferences for Ghostty on macOS.
- `nvim/`: LazyVim-based Neovim configuration (options, plugins, formatter settings, etc.).

## Scripts

Several useful scripts are included in this repository to automate and simplify tasks:

- `scripts/update.sh`: Copies shell, prompt, terminal, and Neovim configs into the appropriate `$HOME` locations.
- `scripts/fonts.sh`: Installs Nerd Font casks or patches local fonts (like SF Mono) via FontPatcher.
- `scripts/whisper_transcription.sh`: Converts media into PCM WAV (if necessary) and transcribes it with `whisper.cpp` (requires `WHISPER_CPP_DIR`).

## Fonts

Try out [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts?tab=readme-ov-file#option-2-homebrew-fonts) as it patches in some of the better fonts with glyphs that are useful.
Thanks to [davidteren's gist](https://gist.github.com/davidteren/898f2dcccd42d9f8680ec69a3a5d350e) we can install them all via homebrew as Casks.

```bash
# Install curated Nerd Fonts (requires homebrew/cask-fonts tap)
./scripts/fonts.sh --install

# Patch default SF Mono variants with Nerd Font glyphs via FontPatcher
./scripts/fonts.sh --patch

# Patch any additional font (repeat --font for more paths)
./scripts/fonts.sh --patch --font "/Library/Fonts/JetBrainsMonoNL-Regular.ttf"
```

## Support

If you encounter any issues or have questions, please [open an issue](https://github.com/mkirch/dotfiles/issues/new).

## Contributing

Contributions are welcome! Please use [GitHub Flow](https://guides.github.com/introduction/flow/) for contributing. Create a branch, add commits, and [open a pull request](https://github.com/mkirch/dotfiles/compare/).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

---

### Additional Notes

Feel free to explore and modify the configurations to suit your personal preferences. These dotfiles are intended to provide a solid foundation for a productive and efficient development environment.

**Private Files**: Both `zsh/.zsh_aliases` and Personal/Work Cursor user-data directories contain personal information and are intentionally ignored via `.gitignore`. 

- Create `zsh/.zsh_aliases` (copy from `zsh/.zsh_aliases.example`) to add personal aliases that won't be committed.
- Keep Cursor profiles outside the repository (set `CURSOR_USER_DATA_DIR` / `CURSOR_EXTENSIONS_DIR` in `~/.dotfiles.env`) to avoid accidentally committing them.

<div align="center">
  <h3>Happy Coding!</h3>
</div>
