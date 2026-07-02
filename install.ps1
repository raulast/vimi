# vimi — Isolated Vim IDE installer for Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
# Usage with flags: $env:VIMI_LANGS="go,python,ts"; irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
#
# Options (set as environment variables before piping):
#   $env:VIMI_LANGS = "go,python,ts"   # Comma-separated CoC extension keys
#                                        # Valid: php go ts python sh lua html css cpp
#                                        # Default: all extensions
#
# This script:
#   - Installs vim-plug to $HOME/.rast/.vim/autoload/
#   - Writes vimrc to $HOME/.rast/.vim/vimrc
#   - Adds 'vimi' function to $PROFILE
#   - Does NOT install Node.js, Go, Python, or clangd
#   - Does NOT require administrator rights
#   - Is safe to run multiple times (idempotent)

[CmdletBinding()]
param(
    [string]$Langs = ""
)

# ==========================================
# CONSTANTS
# ==========================================
$VimiDir    = Join-Path $HOME ".rast\.vim"
$VimrcPath  = Join-Path $VimiDir "vimrc"
$PlugDest   = Join-Path $VimiDir "autoload\plug.vim"
$PlugUrl    = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

# ==========================================
# COLOR HELPERS (T-21)
# ==========================================
function Write-VimInfo {
    param([string]$Message)
    Write-Host "[vimi] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-VimSuccess {
    param([string]$Message)
    Write-Host "[vimi] " -ForegroundColor Green -NoNewline
    Write-Host "✓ $Message"
}

function Write-VimWarn {
    param([string]$Message)
    Write-Host "[vimi] " -ForegroundColor Yellow -NoNewline
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-VimError {
    param([string]$Message)
    Write-Host "[vimi] " -ForegroundColor Red -NoNewline
    Write-Host "✗ $Message" -ForegroundColor Red
}

# ==========================================
# ARGUMENT PARSING (T-22)
# ==========================================
# Support both -Langs param and $env:VIMI_LANGS env var
$DefaultLangs = @("php", "go", "ts", "python", "sh", "lua", "html", "css", "cpp")

function Get-ResolvedLangs {
    param([string]$LangsParam)

    # Env var takes precedence if param not set
    $raw = $LangsParam
    if ([string]::IsNullOrWhiteSpace($raw) -and -not [string]::IsNullOrWhiteSpace($env:VIMI_LANGS)) {
        $raw = $env:VIMI_LANGS
    }

    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $DefaultLangs
    }

    return $raw.Split(",") | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ -ne "" }
}

# ==========================================
# LANG → CoC EXTENSION MAP (T-23)
# ==========================================
$LangToCoc = @{
    "php"    = "coc-phpls"
    "go"     = "coc-go"
    "ts"     = "coc-tsserver"
    "python" = "coc-pyright"
    "sh"     = "coc-sh"
    "lua"    = "coc-lua"
    "html"   = "coc-html"
    "css"    = "coc-css"
    "cpp"    = "coc-clangd"
}

function Build-CocExtensionsVimscript {
    param([string[]]$SelectedLangs)

    $extensions = @()
    foreach ($lang in $SelectedLangs) {
        if ($LangToCoc.ContainsKey($lang)) {
            $extensions += "  \\ '$($LangToCoc[$lang])',"
        } else {
            Write-VimWarn "Unknown lang key: '$lang' — skipped"
        }
    }

    if ($extensions.Count -eq 0) {
        Write-VimWarn "No valid lang keys provided. Using all extensions."
        foreach ($lang in $DefaultLangs) {
            $extensions += "  \\ '$($LangToCoc[$lang])',"
        }
    }

    # Remove trailing comma from last entry
    $lastIndex = $extensions.Count - 1
    $extensions[$lastIndex] = $extensions[$lastIndex].TrimEnd(",")

    $lines = @("let g:coc_global_extensions = [") + $extensions + @("  \\ ]")
    return $lines -join "`n"
}

# ==========================================
# VIM INSTALLATION CHECK + GATE (T-24)
# ==========================================
function Test-VimInstalled {
    $vimCmd = Get-Command vim -ErrorAction SilentlyContinue
    if (-not $vimCmd) {
        $vimCmd = Get-Command gvim -ErrorAction SilentlyContinue
    }

    if ($vimCmd) {
        Write-VimSuccess "Vim found: $($vimCmd.Source)"
        return $true
    }

    Write-VimWarn "Vim is not installed on this system."
    $answer = Read-Host "[vimi] Install Vim now? [y/N]"

    if ($answer -match "^[yY]") {
        Install-Vim
        return $true
    } else {
        Write-VimError "Vim installation declined. vimi requires Vim to work."
        Write-VimError "Install Vim manually and re-run this script."
        Write-VimInfo "  With winget:  winget install vim.vim"
        Write-VimInfo "  With choco:   choco install vim"
        Write-VimInfo "  With scoop:   scoop install vim"
        Write-VimInfo "  Download:     https://www.vim.org/download.php"
        exit 1
    }
}

function Install-Vim {
    # vimi never elevates privileges. Installing Vim may require admin rights.
    # We provide the exact command and let the user run it.
    Write-VimWarn "Vim must be installed at the system level (may require admin rights)."
    Write-VimWarn "vimi does not elevate privileges. Please install Vim manually with one of:"
    Write-Host ""
    Write-VimInfo "  winget install vim.vim"
    Write-VimInfo "  choco install vim"
    Write-VimInfo "  scoop install vim"
    Write-VimInfo "  Download: https://www.vim.org/download.php"
    Write-Host ""
    Write-VimInfo "After installing Vim, re-run this installer:"
    Write-VimInfo "  irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex"
    exit 1
}

# ==========================================
# DIRECTORY STRUCTURE (T-25)
# ==========================================
function New-VimDirectories {
    Write-VimInfo "Creating directory structure under $VimiDir ..."
    $subdirs = @("autoload", "backup", "swap", "undo", "coc", "plugged")
    foreach ($sub in $subdirs) {
        $path = Join-Path $VimiDir $sub
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    Write-VimSuccess "Directories ready."
}

# ==========================================
# VIM-PLUG INSTALLATION (T-26)
# ==========================================
function Install-VimPlug {
    if (Test-Path $PlugDest) {
        Write-VimSuccess "vim-plug already installed — skipping download."
        return
    }

    Write-VimInfo "Installing vim-plug..."
    try {
        Invoke-WebRequest -Uri $PlugUrl -OutFile $PlugDest -UseBasicParsing
        Write-VimSuccess "vim-plug installed."
    } catch {
        Write-VimError "Failed to download vim-plug: $_"
        Write-VimError "Check your internet connection and try again."
        exit 1
    }
}

# ==========================================
# VIMRC GENERATION (T-27)
# ==========================================
function Write-Vimrc {
    param([string[]]$SelectedLangs)

    Write-VimInfo "Writing vimrc to $VimrcPath ..."
    $cocExtensions = Build-CocExtensionsVimscript -SelectedLangs $SelectedLangs

    # Use Windows path separator but write Unix-style paths for Vim
    $vimrcContent = @"
" ==========================================
" vimi — Isolated Vim IDE configuration
" Path: ~/.rast/.vim/vimrc
" Alias: vimi = vim -u ~/.rast/.vim/vimrc
" Generated by vimi installer — safe to edit
" ==========================================

" ==========================================
" 1. RUNTIME PATHS — keep everything isolated
" ==========================================
set runtimepath^=~/.rast/.vim
set runtimepath+=~/.rast/.vim/after

" ==========================================
" 2. TEMP FILES — never pollute cwd
" ==========================================
set backupdir=~/.rast/.vim/backup//
set directory=~/.rast/.vim/swap//
set undodir=~/.rast/.vim/undo//
set undofile

" ==========================================
" 3. GENERAL SETTINGS & UI
" ==========================================
set nocompatible
syntax on
set number
set relativenumber
set mouse=a
set clipboard=unnamedplus
set cursorline
set signcolumn=yes
set encoding=utf-8
set fileencoding=utf-8
set hidden
set updatetime=300
set shortmess+=c
set scrolloff=8
set colorcolumn=80

" ==========================================
" 4. TABS & SEARCH
" ==========================================
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase

" ==========================================
" 5. KEY MAPPINGS (leader: space)
" ==========================================
let mapleader = " "

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Clear search highlight
nnoremap <leader>h :nohlsearch<CR>

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Save / quit shortcuts
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" ==========================================
" 6. CoC — IntelliSense (requires Node.js)
" ==========================================
" CoC data stored inside isolated path
let g:coc_data_home = '~/.rast/.vim/coc'

" Extensions auto-installed on first launch when Node.js is available
$cocExtensions

" ==========================================
" 7. PLUGINS (vim-plug)
" ==========================================
call plug#begin('~/.rast/.vim/plugged')

" File explorer
Plug 'preservim/nerdtree'

" Status bar
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" IntelliSense engine (requires Node.js)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ==========================================
" 8. PLUGIN SETTINGS
" ==========================================

" --- NERDTree ---
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore = ['\.git$', 'node_modules', '__pycache__']
let g:NERDTreeQuitOnOpen = 1

" --- vim-airline ---
let g:airline_powerline_fonts = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" --- Netrw (remote SSH editing) ---
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

" --- CoC keymaps ---
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gr <Plug>(coc-references)
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction-cursor)
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
nnoremap <silent> <leader>d :<C-u>CocList diagnostics<CR>

" ==========================================
" 9. PLUGIN KEYMAPS
" ==========================================
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>N :NERDTreeFind<CR>
nnoremap <leader>p :Files<CR>
nnoremap <leader>/ :Rg<CR>
nnoremap <leader>bb :Buffers<CR>
"@

    Set-Content -Path $VimrcPath -Value $vimrcContent -Encoding UTF8
    Write-VimSuccess "vimrc written."
}

# ==========================================
# PLUGIN INSTALLATION (T-28)
# ==========================================
function Invoke-PluginInstall {
    Write-VimInfo "Installing Vim plugins (this may take a minute)..."
    try {
        $proc = Start-Process -FilePath "vim" `
            -ArgumentList "-u `"$VimrcPath`" +PlugInstall +qall" `
            -Wait -PassThru -WindowStyle Hidden
        Write-VimSuccess "Plugins installed."
        Write-VimInfo "Note: CoC extensions will auto-install on first 'vimi' launch when Node.js is available."
    } catch {
        Write-VimWarn "Plugin installation encountered an issue: $_"
        Write-VimWarn "You can install plugins manually by running 'vimi' and typing :PlugInstall"
    }
}

# ==========================================
# ALIAS / FUNCTION INSTALLATION (T-29)
# ==========================================
function Add-VimAlias {
    # Ensure $PROFILE exists
    if (-not (Test-Path $PROFILE)) {
        Write-VimInfo "Creating PowerShell profile at $PROFILE ..."
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    # Check for existing vimi function (avoid duplicates)
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -and $profileContent -match "function vimi") {
        Write-VimSuccess "Function 'vimi' already present in `$PROFILE — skipping."
        return
    }

    # Append vimi function
    $vimiFunction = @"

# vimi — isolated Vim IDE
function vimi { vim -u "`$HOME/.rast/.vim/vimrc" `$args }
"@
    Add-Content -Path $PROFILE -Value $vimiFunction -Encoding UTF8
    Write-VimSuccess "Function 'vimi' added to `$PROFILE ($PROFILE)"
}

# ==========================================
# LSP DEPENDENCY CHECK (T-30)
# ==========================================
function Test-LspDeps {
    Write-VimInfo "Checking LSP dependencies..."
    $allFound = $true

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-VimWarn "Node.js not found — CoC extensions for JS/TS/PHP/HTML/CSS/Bash/Lua will not activate until Node.js is installed."
        Write-VimWarn "  Once installed, CoC will activate automatically on next 'vimi' launch."
        Write-VimWarn "  Install: https://nodejs.org  or  winget install OpenJS.NodeJS.LTS"
        $allFound = $false
    } else {
        $nodeVersion = node --version
        Write-VimSuccess "Node.js found: $nodeVersion"
    }

    if (-not (Get-Command python3 -ErrorAction SilentlyContinue) -and
        -not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-VimWarn "Python 3 not found — coc-pyright (Python IntelliSense) will not work."
        Write-VimWarn "  Install: https://python.org  or  winget install Python.Python.3"
        $allFound = $false
    } else {
        $pyCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" } else { "python" }
        $pyVersion = & $pyCmd --version
        Write-VimSuccess "Python found: $pyVersion"
    }

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        Write-VimWarn "Go not found — coc-go (Go IntelliSense) will not work."
        Write-VimWarn "  Install: https://go.dev/dl/  or  winget install GoLang.Go"
        $allFound = $false
    } else {
        $goVersion = go version
        Write-VimSuccess "Go found: $goVersion"
    }

    if (-not (Get-Command clangd -ErrorAction SilentlyContinue)) {
        Write-VimWarn "clangd not found — coc-clangd (C/C++ IntelliSense) will not work."
        Write-VimWarn "  Install LLVM: https://releases.llvm.org  or  winget install LLVM.LLVM"
        $allFound = $false
    } else {
        Write-VimSuccess "clangd found."
    }

    if ($allFound) {
        Write-VimSuccess "All LSP dependencies found — CoC will be fully functional."
    }
}

# ==========================================
# SUCCESS MESSAGE + EXECUTIONPOLICY NOTE (T-31)
# ==========================================
function Write-FinalSuccess {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  vimi installed successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-VimInfo "Reload your profile to use vimi immediately:"
    Write-Host ""
    Write-Host "    . `$PROFILE" -ForegroundColor Cyan
    Write-Host ""
    Write-VimInfo "Or open a new PowerShell window and run:"
    Write-Host ""
    Write-Host "    vimi" -ForegroundColor Cyan
    Write-Host ""
    Write-VimInfo "System vim is unchanged. Run 'vim' for the original editor."
    Write-Host ""

    # ExecutionPolicy check (T-31)
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
        Write-Host ""
        Write-VimWarn "Your PowerShell ExecutionPolicy is '$policy'."
        Write-VimWarn "The vimi function may not load in future sessions."
        Write-VimWarn "To fix this, run once in an admin PowerShell:"
        Write-Host ""
        Write-Host "    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ==========================================
# MAIN ENTRY POINT (T-32)
# ==========================================
function Main {
    Write-Host ""
    Write-VimInfo "Starting vimi installation..."
    Write-Host ""

    # Resolve langs (from param or env var)
    $resolvedLangs = Get-ResolvedLangs -LangsParam $Langs

    Test-VimInstalled
    New-VimDirectories
    Install-VimPlug
    Write-Vimrc -SelectedLangs $resolvedLangs
    Invoke-PluginInstall
    Add-VimAlias
    Test-LspDeps
    Write-FinalSuccess
}

Main
