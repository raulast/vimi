# vimi — Isolated Vim IDE installer for Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
# Usage with langs: $env:VIMI_LANGS="go,python,ts"; irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex
#
# Options (set as environment variables before piping):
#   $env:VIMI_LANGS = "go,python,ts"   # CoC stack only — ignored on LSP stack
#                                        # Valid: php go ts python sh lua html css cpp
#
# Stack selection (automatic):
#   Vim >= 9.0.0438  →  CoC stack  (coc.nvim — full IntelliSense)
#   Vim <  9.0.0438  →  LSP stack  (vim-lsp + asyncomplete + ale)
#
# This script:
#   - Detects Vim version and selects the appropriate plugin stack
#   - Downloads the matching vimrc from GitHub
#   - Installs vim-plug to $HOME/.rast/.vim/autoload/
#   - Adds 'vimi' function to $PROFILE
#   - Does NOT install Node.js, Go, Python, or clangd
#   - Does NOT require administrator rights
#   - Is safe to run multiple times (idempotent — re-run after upgrading Vim)

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
$RawBase    = "https://raw.githubusercontent.com/raulast/vimi/master"
$Stack      = ""

# ==========================================
# COLOR HELPERS
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
# ARGUMENT PARSING
# ==========================================
$DefaultLangs = @("php", "go", "ts", "python", "sh", "lua", "html", "css", "cpp")

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

function Get-ResolvedLangs {
    param([string]$LangsParam)
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
# VIM INSTALLATION CHECK + GATE
# ==========================================
function Test-VimInstalled {
    $vimCmd = Get-Command vim -ErrorAction SilentlyContinue
    if (-not $vimCmd) {
        $vimCmd = Get-Command gvim -ErrorAction SilentlyContinue
    }

    if ($vimCmd) {
        Write-VimSuccess "Vim found: $($vimCmd.Source)"
        return
    }

    Write-VimWarn "Vim is not installed on this system."
    $answer = Read-Host "[vimi] Install Vim now? [y/N]"

    if ($answer -match "^[yY]") {
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
    } else {
        Write-VimError "Vim installation declined. vimi requires Vim to work."
        exit 1
    }
}

# ==========================================
# VIM VERSION DETECTION
# ==========================================
function Get-VimVersion {
    $raw = vim --version 2>$null | Select-Object -First 1
    if ($raw -match '(\d+)\.(\d+)(?:\.(\d+))?') {
        return @{
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = if ($Matches[3]) { [int]$Matches[3] } else { 0 }
        }
    }
    return $null
}

function Test-VimIsV9 {
    $v = Get-VimVersion
    if (-not $v) { return $false }
    if ($v.Major -gt 9) { return $true }
    if ($v.Major -eq 9 -and $v.Minor -gt 0) { return $true }
    if ($v.Major -eq 9 -and $v.Minor -eq 0 -and $v.Patch -ge 438) { return $true }
    return $false
}

# ==========================================
# STACK DETECTION
# ==========================================
function Detect-Stack {
    param([string[]]$SelectedLangs)

    $v = Get-VimVersion
    $verStr = if ($v) { "$($v.Major).$($v.Minor).$($v.Patch)" } else { "unknown" }

    if (Test-VimIsV9) {
        $script:Stack = "coc"
        Write-VimSuccess "Vim $verStr — CoC stack selected (full IntelliSense)"
    } else {
        $script:Stack = "lsp"
        Write-VimInfo "Vim $verStr — LSP stack selected (vim-lsp + asyncomplete + ale)"
        Write-VimInfo "CoC stack requires Vim 9.0.0438+. Re-run this installer after upgrading Vim."
    }

    # --langs warning for lsp stack
    $isCustomLangs = ($SelectedLangs.Count -lt $DefaultLangs.Count) -or
                     (Compare-Object $SelectedLangs $DefaultLangs)
    if ($script:Stack -eq "lsp" -and $isCustomLangs) {
        Write-VimInfo "VIMI_LANGS ignored on LSP stack. Language servers are auto-detected by filetype via vim-lsp-settings."
    }
}

# ==========================================
# DIRECTORY STRUCTURE
# ==========================================
function New-VimDirectories {
    Write-VimInfo "Creating directory structure under $VimiDir ..."
    @("autoload", "backup", "swap", "undo", "coc", "plugged") | ForEach-Object {
        $path = Join-Path $VimiDir $_
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
    Write-VimSuccess "Directories ready."
}

# ==========================================
# VIM-PLUG INSTALLATION
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
        exit 1
    }
}

# ==========================================
# VIMRC DOWNLOAD + PATCH (CoC extensions)
# ==========================================
function Write-Vimrc {
    param([string[]]$SelectedLangs)

    Write-VimInfo "Downloading vimrc ($($script:Stack) stack)..."

    if ($script:Stack -eq "lsp") {
        # LSP stack: download as-is
        Invoke-WebRequest -Uri "$RawBase/vimrc.lsp" -OutFile $VimrcPath -UseBasicParsing
        Write-VimSuccess "vimrc written (LSP stack)."
        return
    }

    # CoC stack: download base then patch g:coc_global_extensions
    $tmpPath = [System.IO.Path]::GetTempFileName()
    Invoke-WebRequest -Uri "$RawBase/vimrc.coc" -OutFile $tmpPath -UseBasicParsing

    # Build extensions list from selected langs
    $extLines = @()
    foreach ($lang in $SelectedLangs) {
        if ($LangToCoc.ContainsKey($lang)) {
            $extLines += "  \\ '$($LangToCoc[$lang])',"
        } else {
            Write-VimWarn "Unknown lang key: '$lang' — skipped"
        }
    }
    if ($extLines.Count -eq 0) {
        Write-VimWarn "No valid lang keys. Using all extensions."
        foreach ($lang in $DefaultLangs) {
            $extLines += "  \\ '$($LangToCoc[$lang])',"
        }
    }
    # Remove trailing comma from last entry
    $extLines[$extLines.Count - 1] = $extLines[$extLines.Count - 1].TrimEnd(",")

    # Replace the static coc_global_extensions block in the downloaded file
    $content = Get-Content $tmpPath -Raw
    $newBlock = "let g:coc_global_extensions = [`n" + ($extLines -join "`n") + "`n  \\ ]"
    $content = $content -replace '(?s)let g:coc_global_extensions = \[.*?\\ \]', $newBlock
    Set-Content -Path $VimrcPath -Value $content -Encoding UTF8

    Remove-Item $tmpPath -Force
    Write-VimSuccess "vimrc written (CoC stack, langs: $($SelectedLangs -join ', '))."
}

# ==========================================
# PLUGIN INSTALLATION
# ==========================================
function Invoke-PluginInstall {
    Write-VimInfo "Installing Vim plugins (this may take a minute)..."
    try {
        Start-Process -FilePath "vim" `
            -ArgumentList "-u `"$VimrcPath`" +PlugInstall +qall" `
            -Wait -PassThru -WindowStyle Hidden | Out-Null
        Write-VimSuccess "Plugins installed."
        if ($script:Stack -eq "coc") {
            Write-VimInfo "CoC extensions will auto-install on first 'vimi' launch when Node.js is available."
        } else {
            Write-VimInfo "Language servers will auto-install on first file open via vim-lsp-settings."
        }
    } catch {
        Write-VimWarn "Plugin installation encountered an issue: $_"
        Write-VimWarn "Run 'vimi' and type :PlugInstall to install manually."
    }
}

# ==========================================
# ALIAS / FUNCTION INSTALLATION
# ==========================================
function Add-VimAlias {
    if (-not (Test-Path $PROFILE)) {
        Write-VimInfo "Creating PowerShell profile at $PROFILE ..."
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -and $profileContent -match "function vimi") {
        Write-VimSuccess "Function 'vimi' already present in `$PROFILE — skipping."
        return
    }

    $vimiFunction = @"

# vimi — isolated Vim IDE
function vimi { vim -u "`$HOME/.rast/.vim/vimrc" `$args }
"@
    Add-Content -Path $PROFILE -Value $vimiFunction -Encoding UTF8
    Write-VimSuccess "Function 'vimi' added to `$PROFILE"
}

# ==========================================
# LSP DEPENDENCY CHECK
# ==========================================
function Test-LspDeps {
    Write-VimInfo "Checking LSP dependencies..."
    $allFound = $true

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        if ($script:Stack -eq "coc") {
            Write-VimWarn "Node.js not found — CoC extensions will not activate until Node.js is installed."
            Write-VimWarn "  Once installed, CoC activates automatically on next 'vimi' launch."
        } else {
            Write-VimWarn "Node.js not found — some vim-lsp-settings language servers require Node.js."
        }
        Write-VimWarn "  Install: https://nodejs.org  or  winget install OpenJS.NodeJS.LTS"
        $allFound = $false
    } else {
        Write-VimSuccess "Node.js found: $(node --version)"
    }

    $pyCmd = if (Get-Command python3 -ErrorAction SilentlyContinue) { "python3" }
             elseif (Get-Command python -ErrorAction SilentlyContinue) { "python" }
             else { $null }
    if (-not $pyCmd) {
        if ($script:Stack -eq "coc") {
            Write-VimWarn "Python 3 not found — coc-pyright (Python IntelliSense) will not work."
        } else {
            Write-VimWarn "Python 3 not found — vim-lsp Python support will not work."
        }
        $allFound = $false
    } else {
        Write-VimSuccess "Python found: $(& $pyCmd --version)"
    }

    if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
        if ($script:Stack -eq "coc") {
            Write-VimWarn "Go not found — coc-go (Go IntelliSense) will not work."
        } else {
            Write-VimWarn "Go not found — vim-lsp Go support (gopls) will not work."
        }
        $allFound = $false
    } else {
        Write-VimSuccess "Go found: $(go version)"
    }

    if (-not (Get-Command clangd -ErrorAction SilentlyContinue)) {
        if ($script:Stack -eq "coc") {
            Write-VimWarn "clangd not found — coc-clangd (C/C++ IntelliSense) will not work."
        } else {
            Write-VimWarn "clangd not found — vim-lsp C/C++ support will not work."
        }
        Write-VimWarn "  Install LLVM: https://releases.llvm.org  or  winget install LLVM.LLVM"
        $allFound = $false
    } else {
        Write-VimSuccess "clangd found."
    }

    if ($allFound) {
        Write-VimSuccess "All LSP dependencies found."
    }
}

# ==========================================
# SUCCESS MESSAGE
# ==========================================
function Write-FinalSuccess {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  vimi installed successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""

    if ($script:Stack -eq "coc") {
        Write-VimInfo "Stack: CoC (Vim 9+ — full IntelliSense via coc.nvim)"
    } else {
        Write-VimInfo "Stack: LSP (Vim 8 — vim-lsp + asyncomplete + ale)"
        Write-VimInfo "Upgrade to CoC stack: upgrade Vim to 9.0.0438+ then re-run:"
        Write-Host "    irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex" -ForegroundColor Cyan
        Write-Host ""
    }

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

    # ExecutionPolicy advisory
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    if ($policy -eq "Restricted" -or $policy -eq "Undefined") {
        Write-Host ""
        Write-VimWarn "Your PowerShell ExecutionPolicy is '$policy'."
        Write-VimWarn "The vimi function may not load in future sessions. Fix with:"
        Write-Host ""
        Write-Host "    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ==========================================
# ZELLIJ PROMPT
# ==========================================
function Invoke-ZellijPrompt {
    # Skip when stdin is not interactive (piped execution)
    if (-not [Environment]::UserInteractive) { return }

    Write-Host ""
    Write-VimInfo "─────────────────────────────────────────"
    $ans = Read-Host "[zellij] Install Zellij terminal multiplexer? (y/N)"
    if ($ans -match '^[yY]$') {
        Invoke-Expression (Invoke-RestMethod "https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.ps1")
    } else {
        Write-VimInfo "Skipping Zellij. Install anytime:"
        Write-Host "    irm https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.ps1 | iex" -ForegroundColor Cyan
    }
}

# ==========================================
# MAIN
# ==========================================
function Main {
    Write-Host ""
    Write-VimInfo "Starting vimi installation..."
    Write-Host ""

    $resolvedLangs = Get-ResolvedLangs -LangsParam $Langs

    Test-VimInstalled
    Detect-Stack -SelectedLangs $resolvedLangs
    New-VimDirectories
    Install-VimPlug
    Write-Vimrc -SelectedLangs $resolvedLangs
    Invoke-PluginInstall
    Add-VimAlias
    Test-LspDeps
    Write-FinalSuccess
    Invoke-ZellijPrompt
}

Main
