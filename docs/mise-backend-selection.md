# Mise Backend Selection Guide

Opinionated guide for selecting the best mise backend for each tool. Prioritizes security, then reliability, then speed.

## Backend Security Tiers

### Tier 1: Verified Binaries (Preferred for CLI tools)

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **aqua** | ✅ SHA checksums, Cosign signatures, SLSA provenance, GitHub attestations | Fast | Best option when available. Native verification in mise. |
| **github** | ✅ SHA checksums (via mise.lock), SLSA, GitHub attestations | Fast | Good alternative to aqua. Requires explicit checksum config or lockfile. |

### Tier 2: Source Builds (Preferred when Tier 1 unavailable)

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **cargo** | ✅ Crate checksums, builds from source | Slow | Most auditable - you compile the code. Requires Rust toolchain. |
| **go** | ✅ Module checksums, builds from source | Slow | Similar to cargo. Requires Go toolchain. |
| **spm** | ✅ Builds from source | Slow | Swift packages. Experimental. |

### Tier 3: Package Managers (Language-specific tools only)

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **npm** | ⚠️ Registry checksums | Fast | Use only for JS/TS tools (prettier, eslint). |
| **pipx** | ⚠️ PyPI checksums | Fast | Use only for Python tools (black, ruff). Uses uv when available. |
| **gem** | ⚠️ RubyGems checksums | Fast | Use only for Ruby tools. |
| **dotnet** | ⚠️ NuGet checksums | Fast | .NET tools. Experimental. |
| **conda** | ⚠️ Conda checksums | Medium | Scientific Python. Experimental. |

### Tier 4: Unverified Binaries (Avoid when possible)

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **ubi** | ❌ No checksums | Fast | **Deprecated.** Migrate to `github` backend. |
| **http** | ❌ No verification | Fast | Raw URL downloads. Avoid for tools. |
| **s3** | ❌ No verification | Fast | Private artifacts only. Experimental. |

### Tier 5: Legacy/Plugin-based (Avoid for new tools)

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **asdf** | ⚠️ Varies by plugin | Varies | Legacy. Plugins are community-maintained, inconsistent quality. |
| **vfox** | ⚠️ Varies by plugin | Varies | Alternative plugin ecosystem. |

### Special: Core Plugins

| Backend | Verification | Speed | Notes |
|---------|--------------|-------|-------|
| **core** | ✅ Maintained by mise | Fast | node, python, go, java, etc. Use these for runtimes. |

---

## Decision Flowchart

```
Is it a runtime (node, python, go, java, ruby)?
  YES → Use core plugin (just `node = "lts"`)
  NO  ↓

Is it in aqua-registry?
  YES → Use `aqua:org/tool`
  NO  ↓

Is it a Rust CLI tool?
  YES → Use `cargo:toolname` (builds from source)
  NO  ↓

Does it have GitHub releases with checksums?
  YES → Use `github:org/tool` with mise.lock
  NO  ↓

Is it a language-specific tool?
  - JavaScript/TypeScript → `npm:package`
  - Python → `pipx:package`
  - Ruby → `gem:package`
  - Go → `go:module/path`
  NO  ↓

Last resort: `ubi:org/tool` (but prefer github)
```

---

## Quick Reference by Tool Type

### Runtimes (use core)
```toml
node = "lts"
python = "3.12"
go = "latest"
java = "21"
```

### CLI Tools (prefer aqua → cargo → github)
```toml
# Best: aqua (checksummed binaries)
"aqua:sharkdp/bat" = "latest"
"aqua:BurntSushi/ripgrep" = "latest"

# Good: cargo (source builds, slower)
"cargo:eza" = "latest"

# Acceptable: github with lockfile
"github:org/tool" = "latest"
```

### Language Tools (use native package managers)
```toml
# JavaScript
"npm:prettier" = "latest"
"npm:eslint" = "latest"

# Python (pipx uses uv automatically)
"pipx:black" = "latest"
"pipx:ruff" = "latest"

# Ruby
"gem:rubocop" = "latest"
```

---

## How to Check Availability

```bash
# Search mise registry for a tool
mise registry | rg "toolname"

# Check if tool is in aqua registry
# Look for aqua: prefix in output
mise registry | rg "^toolname"
```

---

## Security Settings

Enable lockfile for checksum verification:
```toml
[settings]
lockfile = true
```

Aqua verification is enabled by default. To check:
```bash
# These should all be true (default)
mise settings | rg -i "aqua"
```

---

## Important: Backend Changes Are NOT Upgrades

**Different backends = different tools to mise.**

```
ubi:dalance/procs ≠ github:dalance/procs
cargo:hyperfine ≠ aqua:sharkdp/hyperfine
```

If you change a backend in your global config, project configs using the old backend will still need those old versions installed. You have two options:

1. **Update all project configs** to use the new backend
2. **Keep both versions installed** (old backend for projects, new for global)

## Pruning: Be Careful

`mise prune` removes versions not referenced by **any tracked config**. Before pruning:

```bash
# See what configs mise is tracking
ls ~/.local/state/mise/tracked-configs/

# See what would be pruned
mise prune --dry-run

# See versions with no config reference
mise ls --prunable
```

**Don't prune if:**
- You have project configs using older versions/backends
- You want to keep versions for projects not recently visited

**Safe to prune:**
- Duplicate versions from backend changes (e.g., cargo:sd after switching to aqua:chmln/sd)
- Old versions after explicit upgrades in ALL configs

## Migration Checklist

When adding a new tool:

1. [ ] Check `mise registry | rg "toolname"` for available backends
2. [ ] Prefer aqua if available (checksums + signatures)
3. [ ] Fall back to cargo for Rust tools (source builds)
4. [ ] Use github backend (not ubi) for other binary tools
5. [ ] Use native package manager backends for language-specific tools
6. [ ] Enable `lockfile = true` for reproducibility
7. [ ] Run `mise install` and verify tool works
8. [ ] Commit mise.lock if using lockfile

When changing a backend for existing tool:

1. [ ] Update global config with new backend
2. [ ] Search for project configs using old backend: `rg "ubi:toolname" ~/Developer`
3. [ ] Update those project configs OR keep old version installed
4. [ ] Only prune after ALL configs are updated

---

## References

- [Mise Backends Documentation](https://mise.jdx.dev/dev-tools/backends/)
- [Aqua Registry Security](https://aquaproj.github.io/docs/reference/security/checksum/)
- [Mise Lockfile](https://mise.jdx.dev/dev-tools/mise-lock.html)
- [Aqua Registry Search](https://github.com/aquaproj/aqua-registry)
