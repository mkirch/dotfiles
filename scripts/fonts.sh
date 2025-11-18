#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

NERD_FONT_CASKS=(
  font-0xproto-nerd-font
  font-3270-nerd-font
  font-agave-nerd-font
  font-anonymice-nerd-font
  font-arimo-nerd-font
  font-aurulent-sans-mono-nerd-font
  font-bigblue-terminal-nerd-font
  font-bitstream-vera-sans-mono-nerd-font
  font-blex-mono-nerd-font
  font-caskaydia-cove-nerd-font
  font-code-new-roman-nerd-font
  font-comic-shanns-mono-nerd-font
  font-commit-mono-nerd-font
  font-cousine-nerd-font
  font-d2coding-nerd-font
  font-daddy-time-mono-nerd-font
  font-dejavu-sans-mono-nerd-font
  font-droid-sans-mono-nerd-font
  font-fantasque-sans-mono-nerd-font
  font-fira-code-nerd-font
  font-fira-mono-nerd-font
  font-geist-mono-nerd-font
  font-go-mono-nerd-font
  font-gohufont-nerd-font
  font-hack-nerd-font
  font-hasklug-nerd-font
  font-heavy-data-nerd-font
  font-hurmit-nerd-font
  font-im-writing-nerd-font
  font-inconsolata-go-nerd-font
  font-inconsolata-lgc-nerd-font
  font-inconsolata-nerd-font
  font-iosevka-nerd-font
  font-iosevka-term-nerd-font
  font-iosevka-term-slab-nerd-font
  font-jetbrains-mono-nerd-font
  font-lekton-nerd-font
  font-liberation-nerd-font
  font-lilex-nerd-font
  font-meslo-lg-nerd-font
  font-monaspace-nerd-font
  font-monofur-nerd-font
  font-monoid-nerd-font
  font-mononoki-nerd-font
  font-mplus-nerd-font
  font-noto-nerd-font
  font-open-dyslexic-nerd-font
  font-overpass-nerd-font
  font-profont-nerd-font
  font-proggy-clean-tt-nerd-font
  font-roboto-mono-nerd-font
  font-sauce-code-pro-nerd-font
  font-shure-tech-mono-nerd-font
  font-space-mono-nerd-font
  font-terminess-ttf-nerd-font
  font-tinos-nerd-font
  font-ubuntu-mono-nerd-font
  font-ubuntu-nerd-font
  font-victor-mono-nerd-font
  font-zed-mono-nerd-font
)

PATCH_DEFAULTS=(
  "/Library/Fonts/SF-Mono-Regular.otf"
  "/Library/Fonts/SF-Mono-Bold.otf"
  "/Library/Fonts/SF-Mono-BoldItalic.otf"
  "/Library/Fonts/SF-Mono-Heavy.otf"
  "/Library/Fonts/SF-Mono-HeavyItalic.otf"
  "/Library/Fonts/SF-Mono-Light.otf"
  "/Library/Fonts/SF-Mono-LightItalic.otf"
  "/Library/Fonts/SF-Mono-Medium.otf"
  "/Library/Fonts/SF-Mono-MediumItalic.otf"
  "/Library/Fonts/SF-Mono-RegularItalic.otf"
  "/Library/Fonts/SF-Mono-Semibold.otf"
  "/Library/Fonts/SF-Mono-SemiboldItalic.otf"
)

usage() {
  cat <<'EOF'
Usage: ./scripts/fonts.sh [OPTIONS]

Options:
  --install           Install curated Nerd Fonts via Homebrew casks.
  --patch             Patch the default SF Mono variants with Nerd Font glyphs.
  --font <path>       Patch an additional font (may be used multiple times).
  -h, --help          Show this message.

Examples:
  ./scripts/fonts.sh --install
  ./scripts/fonts.sh --patch
  ./scripts/fonts.sh --patch --font "/Library/Fonts/JetBrainsMono.ttf"
EOF
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

download_fontpatcher() {
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -sSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FontPatcher.zip -o "${tmp_dir}/FontPatcher.zip"
  unzip -q "${tmp_dir}/FontPatcher.zip" -d "${tmp_dir}/FontPatcher"
  echo "${tmp_dir}/FontPatcher/font-patcher"
}

INSTALL_FONTS=false
PATCH_FONTS=false
EXTRA_PATCH_TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install)
      INSTALL_FONTS=true
      shift
      ;;
    --patch)
      PATCH_FONTS=true
      shift
      ;;
    --font)
      PATCH_FONTS=true
      shift
      if [[ $# -eq 0 ]]; then
        echo "--font requires a path argument" >&2
        exit 1
      fi
      EXTRA_PATCH_TARGETS+=("$1")
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "${INSTALL_FONTS}" == "false" && "${PATCH_FONTS}" == "false" ]]; then
  usage
  exit 0
fi

if [[ "${INSTALL_FONTS}" == "true" ]]; then
  require_cmd brew
  brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
  for font in "${NERD_FONT_CASKS[@]}"; do
    echo "Installing ${font}..."
    brew install --cask "${font}"
  done
fi

if [[ "${PATCH_FONTS}" == "true" ]]; then
  require_cmd curl
  require_cmd unzip
  require_cmd fontforge

  font_patcher="$(download_fontpatcher)"
  font_patcher_root="$(dirname "$(dirname "${font_patcher}")")"
  trap "rm -rf \"${font_patcher_root}\"" EXIT INT TERM

  patch_targets=("${PATCH_DEFAULTS[@]}" "${EXTRA_PATCH_TARGETS[@]}")
  for font in "${patch_targets[@]}"; do
    if [[ ! -f "${font}" ]]; then
      echo "Skipping missing font: ${font}"
      continue
    fi
    echo "Patching ${font}..."
    fontforge --complete --script "${font_patcher}" "${font}"
  done
fi