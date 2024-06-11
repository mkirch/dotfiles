#!/bin/bash

echo "Running dotfiles update script"
echo "Dotfiles directory: ${DOTLOC}"
echo "Home directory: ${HOME}"
echo "Current directory: $(pwd || true)"
echo "Copying dotfiles..."
echo "Updating .zshrc..."
cp "${DOTLOC}/.zshrc" "${HOME}/.zshrc"
echo "Updating wezterm configuration..."
mkdir -p "${HOME}/.config/wezterm"
cp "${DOTLOC}/wezterm.lua" "${HOME}/.config/wezterm/wezterm.lua"
echo "Dotfiles updated successfully!"
