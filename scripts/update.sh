#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTLOC:-$(cd "${SCRIPT_DIR}/.." && pwd)}"
export DOTLOC="${DOTFILES_DIR}"

log() {
  printf '[dotfiles] %s\n' "$1"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf '[dotfiles] Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

copy_file() {
  local source_path="$1"
  local target_path="$2"

  if [[ ! -f "${source_path}" ]]; then
    log "Skipping missing file: ${source_path}"
    return
  fi

  mkdir -p "$(dirname "${target_path}")"
  cp "${source_path}" "${target_path}"
  log "Updated ${target_path}"
}

sync_tree() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "${source_dir}" ]]; then
    log "Skipping missing directory: ${source_dir}"
    return
  fi

  mkdir -p "${target_dir}"
  rsync -a --delete "${source_dir}/" "${target_dir}/"
  log "Synced ${target_dir}"
}

log "Running dotfiles update script"
log "Dotfiles directory: ${DOTFILES_DIR}"
log "Home directory: ${HOME}"

require_cmd rsync

# Copy .env from repo to ~/.dotfiles.env if it exists
if [[ -f "${DOTFILES_DIR}/.env" ]]; then
  copy_file "${DOTFILES_DIR}/.env" "${HOME}/.dotfiles.env"
else
  log "No .env file found in ${DOTFILES_DIR} (skipping)"
fi

copy_file "${DOTFILES_DIR}/zsh/.zshenv" "${HOME}/.zshenv"
copy_file "${DOTFILES_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
copy_file "${DOTFILES_DIR}/p10k/.p10k.zsh" "${HOME}/.p10k.zsh"

sync_tree "${DOTFILES_DIR}/nvim" "${HOME}/.config/nvim"
copy_file "${DOTFILES_DIR}/ghostty/config" "${HOME}/Library/Application Support/com.mitchellh.ghostty/config"

log "Dotfiles updated successfully!"
