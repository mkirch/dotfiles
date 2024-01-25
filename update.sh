#!/bin/bash


# Path to the .zshrc file in macOS
ZSHRC_PATH="$HOME/.zshrc"

# Path to the wezterm.lua file in macOS
WEZTERM_PATH="$HOME/.config/wezterm/wezterm.lua"

# Update .zshrc
cp "./.zshrc" "$ZSHRC_PATH"

# Update wezterm.lua
mkdir -p "$HOME/.config/wezterm"
cp "./wezterm.lua" "$WEZTERM_PATH"

echo "Dotfiles updated successfully!"