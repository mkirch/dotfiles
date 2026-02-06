# Terminal Image Viewing for Ghostty

## Overview

Add image viewing capability to zsh/Ghostty setup using yazi, a well-maintained Rust file manager that leverages Ghostty's native Kitty graphics protocol support.

## Tools

| Tool | Purpose | Source |
|------|---------|--------|
| [yazi](https://github.com/sxyazi/yazi) | File manager with image previews | `aqua:sxyazi/yazi` via mise |
| ffmpegthumbnailer | Video thumbnails for yazi | Homebrew |

## Changes

### mise/config.toml

```toml
"aqua:sxyazi/yazi" = "latest"
```

### Brewfile

```ruby
brew "ffmpegthumbnailer"  # Video thumbnails for yazi
```

### zsh/.zshrc

```zsh
# yazi file manager with cd-on-exit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
```

## Usage

```bash
y                      # Open file browser, quit to cd there
y ~/Downloads          # Open in specific directory
```

## No Configuration Required

- Ghostty supports Kitty graphics protocol natively
- Yazi auto-detects the protocol via $TERM
- Yazi creates default config at ~/.config/yazi/yazi.toml on first run
