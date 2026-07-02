# vimi

> Isolated Vim IDE on any server — one command, no sudo

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20Windows-lightgrey)](#quick-start)
[![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh%20%7C%20fish%20%7C%20PowerShell-informational)](#quick-start)

**vimi** deploys a full Vim IDE — NERDTree, fuzzy search, airline, and CoC IntelliSense — completely isolated in your `$HOME`. It does not touch system Vim, does not require `sudo`, and leaves every other user's configuration intact.

After installation, type `vimi` to open your personal IDE. Type `vim` to open the original, unmodified editor.

---

## Vim Version Compatibility

vimi automatically detects your Vim version and installs the appropriate plugin stack — no flags or configuration required.

| Vim version | Stack | IntelliSense engine | Notes |
|---|---|---|---|
| >= 9.0.0438 | **CoC** | coc.nvim | Full IntelliSense, requires Node.js |
| < 9.0.0438 | **LSP** | vim-lsp + asyncomplete + ale | Vim 8 compatible, language servers auto-installed per filetype |

Both stacks share identical keymaps — same muscle memory regardless of which stack is active.

Re-run the installer at any time to update your vimrc or switch stacks after a Vim upgrade.

---

## Quick Start

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh
```

### Windows (PowerShell native)

```powershell
irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
```

> **ExecutionPolicy note**: if the command above is blocked, run this first in an admin PowerShell, then retry:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

After installation, **reload your shell** to activate the alias:

```sh
# bash / zsh
source ~/.bashrc   # or ~/.zshrc

# fish
source ~/.config/fish/config.fish

# PowerShell
. $PROFILE
```

Then launch your IDE:

```sh
vimi
vimi file.py
vimi .
```

---

## Zellij Terminal Multiplexer (optional)

Install [Zellij](https://zellij.dev) alongside vimi — isolated in `~/.rast/.zellij/`, no sudo required. Re-run anytime to update to the latest version.

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh | sh
```

### fish

```fish
bash (curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh | psub)
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.ps1 | iex
```

After installation, reload your shell and run `zellij` to start.

---

## What Gets Installed

All files are placed exclusively under `~/.rast/.vim/`. Nothing is written outside your home directory.

```
~/.rast/.vim/
├── vimrc               ← your Vim configuration
├── autoload/
│   └── plug.vim        ← vim-plug plugin manager
├── plugged/            ← plugins (NERDTree, airline, fzf, coc.nvim)
├── coc/                ← CoC IntelliSense data
├── backup/             ← Vim backup files
├── swap/               ← Vim swap files
└── undo/               ← persistent undo history
```

**Plugins installed:**

| Plugin | Purpose |
|--------|---------|
| [NERDTree](https://github.com/preservim/nerdtree) | File tree explorer |
| [vim-airline](https://github.com/vim-airline/vim-airline) | Status bar |
| [fzf.vim](https://github.com/junegunn/fzf.vim) | Fuzzy file & content search |
| [coc.nvim](https://github.com/neoclide/coc.nvim) | IntelliSense engine (requires Node.js) |

**Shell alias / function added:**

```sh
# bash / zsh / fish
alias vimi="vim -u ~/.rast/.vim/vimrc"

# PowerShell
function vimi { vim -u "$HOME/.rast/.vim/vimrc" $args }
```

---

## Key Bindings

| Key | Action |
|-----|--------|
| `Space` | Leader key |
| `Ctrl+h/j/k/l` | Navigate window splits |
| `Space+n` | Toggle NERDTree |
| `Space+N` | Reveal current file in NERDTree |
| `Space+p` | Fuzzy file search |
| `Space+/` | Search inside files (ripgrep) |
| `Space+bb` | List open buffers |
| `Space+h` | Clear search highlight |
| `Space+w` / `Space+q` | Save / quit |
| `gd` | Go to definition (CoC) |
| `K` | Show documentation (CoC) |
| `Space+rn` | Rename symbol (CoC) |
| `Space+ca` | Code action (CoC) |
| `[g` / `]g` | Navigate diagnostics (CoC) |
| `Space+d` | Diagnostics list (CoC) |

---

## Options — `--langs` Flag

By default, the installer sets up CoC extensions for all 9 supported languages. Use `--langs` to install only what you need.

### Linux / macOS

```sh
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh -s -- --langs go,python,ts
```

### Windows (PowerShell)

```powershell
$env:VIMI_LANGS = "go,python,ts"
irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
```

**Available language keys:**

| Key | CoC Extension | Language |
|-----|--------------|----------|
| `php` | coc-phpls | PHP |
| `go` | coc-go | Go |
| `ts` | coc-tsserver | JavaScript / TypeScript |
| `python` | coc-pyright | Python |
| `sh` | coc-sh | Bash / Shell |
| `lua` | coc-lua | Lua |
| `html` | coc-html | HTML |
| `css` | coc-css | CSS / SCSS |
| `cpp` | coc-clangd | C / C++ |

Unknown keys are skipped with a warning — the installation continues.

---

## What Does NOT Get Installed

The installer **never installs** language runtimes or LSP servers. These are system-level dependencies that must already exist (or be installed separately by you):

| Tool | Required by | Install |
|------|-------------|---------|
| Node.js | coc.nvim + most CoC extensions | [nodejs.org](https://nodejs.org) |
| Python 3 | coc-pyright | [python.org](https://python.org) |
| Go | coc-go (`gopls`) | [go.dev](https://go.dev/dl/) |
| clangd | coc-clangd | `apt install clangd` / [LLVM](https://releases.llvm.org) |

If any of these are missing, the installer **warns** you but completes successfully. vimi is fully functional without them — you just won't have IntelliSense for those languages.

---

## Upgrading from Vim 8 to Vim 9

If you installed vimi with Vim 8 (LSP stack) and later upgraded to Vim 9, re-run the installer — it detects the new version automatically and switches to the CoC stack:

```sh
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh
```

```powershell
# Windows PowerShell
irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
```

The installer is idempotent — re-running it is the upgrade mechanism. Your alias and directory structure are preserved.

---

## Adding Node.js Later

**You do not need to re-run the installer if you add Node.js after the initial setup.**

CoC detects Node.js automatically the next time you open `vimi`. Once Node.js is in your `PATH`:

1. Open `vimi` normally
2. CoC starts automatically and downloads the configured extensions in the background
3. Check extension status with `:CocList extensions`

**Exception:** if you used `--langs` to install a subset of extensions and later want to add more, either re-run the installer with the updated `--langs` list, or install them manually inside vimi:

```vim
:CocInstall coc-go coc-pyright
```

---

## Installed File Locations

```
~/.rast/.vim/vimrc          ← main configuration (edit this to customize)
~/.rast/.vim/autoload/      ← vim-plug
~/.rast/.vim/plugged/       ← all plugins
~/.rast/.vim/coc/           ← CoC data and language servers
~/.rast/.vim/backup/        ← Vim backup files (~file.txt~)
~/.rast/.vim/swap/          ← Vim swap files (.file.txt.swp)
~/.rast/.vim/undo/          ← persistent undo history
```

**Shell profile changes** — one line added to:
- `~/.bashrc` (bash)
- `~/.zshrc` (zsh)
- `~/.config/fish/config.fish` (fish)
- `~/.profile` (other shells)
- `$PROFILE` (PowerShell)

---

## Uninstall

```sh
# Remove all vimi files
rm -rf ~/.rast/.vim

# Remove the alias from your shell profile
# Open your profile (~/.bashrc, ~/.zshrc, etc.) and delete these two lines:
#   # vimi — isolated Vim IDE
#   alias vimi="vim -u ~/.rast/.vim/vimrc"
```

PowerShell:

```powershell
Remove-Item -Recurse -Force "$HOME\.rast\.vim"
# Then edit $PROFILE and remove the vimi function block
```

System Vim remains completely untouched.

---

## Troubleshooting

### ExecutionPolicy error on Windows

**Symptom:** `irm ... | iex` fails with "running scripts is disabled on this system"

**Fix:** Run once in an admin PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### PlugInstall fails (no network / firewall)

**Symptom:** Plugins not installed, errors during `run_plugin_install`

**Fix:** Run inside vimi after network is available:
```vim
:PlugInstall
```

Or from the shell:
```sh
vim -u ~/.rast/.vim/vimrc +PlugInstall +qall
```

---

### `vimi` not found after installation

**Symptom:** `command not found: vimi`

**Cause:** Shell profile not reloaded yet.

**Fix:**
```sh
source ~/.bashrc    # bash
source ~/.zshrc     # zsh
source ~/.config/fish/config.fish  # fish
. $PROFILE          # PowerShell
```

Or simply open a new terminal session.

---

### CoC not working / no IntelliSense

**Symptom:** No completions, `[coc.nvim] node is not executable` error

**Cause:** Node.js is not installed or not in `PATH`.

**Fix:** Install Node.js, then open `vimi` — CoC activates automatically. No reinstall needed.

Verify inside vimi:
```vim
:CocInfo
:CocList extensions
```

---

### `coc.nvim requires at least Vim 9.0.0438` warning

**Symptom:** coc.nvim shows a startup warning and IntelliSense does not work.

**Cause:** Your Vim version is older than 9.0.0438. The installer installed the LSP stack — but if you had a previous coc.nvim install, it may conflict.

**Fix option 1** — Clean reinstall with the correct stack:
```sh
rm -rf ~/.rast/.vim
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh
```

**Fix option 2** — Upgrade Vim to 9.0.0438+ and re-run the installer:
```sh
# Ubuntu/Debian (via PPA)
sudo add-apt-repository ppa:jonathonf/vim
sudo apt update && sudo apt install vim

# Then re-run vimi installer
curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh
```

---

### Duplicate alias after re-running installer

The installer checks for an existing `vimi` alias before writing. If you see a duplicate, open your profile and remove the extra line manually.

---

## Contributing

1. Fork the repo
2. Create a branch: `git checkout -b fix/your-fix`
3. Make your changes
4. Open a pull request

Please test on at least one Linux distro and macOS (or Windows for PS changes) before submitting.

---

## License

MIT — see [LICENSE](LICENSE)
