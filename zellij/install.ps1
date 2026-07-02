# zellij — Isolated Zellij installer for Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.ps1 | iex
#
# This script:
#   - Downloads the latest Zellij binary from GitHub releases
#   - Installs it to $HOME\.rast\.zellij\bin\zellij.exe
#   - Adds that directory to PATH persistently via $PROFILE
#   - Does NOT require administrator rights
#   - Is safe to run multiple times (always updates to latest)

[CmdletBinding()]
param()

# ==========================================
# CONSTANTS
# ==========================================
$ZellijDir    = Join-Path $HOME ".rast\.zellij"
$ZellijBinDir = Join-Path $ZellijDir "bin"
$ZellijBin    = Join-Path $ZellijBinDir "zellij.exe"
$ReleaseBase  = "https://github.com/zellij-org/zellij/releases/latest/download"

# ==========================================
# COLOR HELPERS
# ==========================================
function Write-ZellijInfo {
    param([string]$Message)
    Write-Host "[zellij] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-ZellijSuccess {
    param([string]$Message)
    Write-Host "[zellij] " -ForegroundColor Green -NoNewline
    Write-Host "✓ $Message"
}

function Write-ZellijWarn {
    param([string]$Message)
    Write-Host "[zellij] " -ForegroundColor Yellow -NoNewline
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-ZellijError {
    param([string]$Message)
    Write-Host "[zellij] " -ForegroundColor Red -NoNewline
    Write-Host "✗ $Message" -ForegroundColor Red
}

# ==========================================
# ARCH DETECTION
# ==========================================
function Get-ZellijArch {
    switch ($env:PROCESSOR_ARCHITECTURE) {
        "AMD64" { return "x86_64" }
        "ARM64" {
            Write-ZellijError "ARM64 Windows is not supported yet."
            Write-ZellijError "See: https://github.com/zellij-org/zellij/releases for manual install."
            exit 2
        }
        default {
            Write-ZellijError "Unsupported CPU architecture: $env:PROCESSOR_ARCHITECTURE"
            exit 2
        }
    }
}

# ==========================================
# DOWNLOAD BINARY
# ==========================================
function Get-ZellijBinary {
    $arch = Get-ZellijArch
    $url  = "$ReleaseBase/zellij-$arch-pc-windows-msvc.zip"
    $zip  = Join-Path $env:TEMP "zellij-install.zip"

    Write-ZellijInfo "Downloading Zellij for $arch-windows..."
    Write-ZellijInfo "Source: $url"

    New-Item -ItemType Directory -Path $ZellijBinDir -Force | Out-Null

    try {
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    } catch {
        Write-Host ""
        Write-ZellijError "Download failed: $_"
        Write-ZellijError "A new release may currently be building — try again in a few minutes."
        exit 1
    }

    try {
        Expand-Archive -Path $zip -DestinationPath $ZellijBinDir -Force
        Remove-Item $zip -Force
    } catch {
        Write-Host ""
        Write-ZellijError "Extraction failed: $_"
        exit 1
    }

    Write-ZellijSuccess "Binary installed: $ZellijBin"
}

# ==========================================
# PATH SETUP
# ==========================================
function Add-ZellijToPath {
    # Ensure $PROFILE exists
    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

    if ($profileContent -and $profileContent -match [regex]::Escape($ZellijBinDir)) {
        Write-ZellijSuccess "PATH already configured in $PROFILE — skipping."
        return
    }

    $pathEntry = "`n# zellij — add binary to PATH`n`$env:PATH += `";$ZellijBinDir`"`n"
    Add-Content -Path $PROFILE -Value $pathEntry
    Write-ZellijSuccess "PATH updated in $PROFILE"
    Write-ZellijInfo  "Reload your profile to activate: . `$PROFILE"
}

# ==========================================
# SUCCESS MESSAGE
# ==========================================
function Write-ZellijFinalSuccess {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Zellij installed successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-ZellijInfo "Binary: $ZellijBin"
    Write-Host ""
    Write-ZellijInfo "Reload your profile, then verify:"
    Write-Host ""
    Write-Host "    . `$PROFILE" -ForegroundColor Cyan
    Write-Host "    zellij --version" -ForegroundColor Cyan
    Write-Host ""
    Write-ZellijInfo "Re-run this script anytime to update to the latest version."
    Write-Host ""
}

# ==========================================
# MAIN
# ==========================================
function Invoke-ZellijInstall {
    Write-Host ""
    Write-ZellijInfo "Starting Zellij installation..."
    Write-Host ""

    Get-ZellijBinary
    Add-ZellijToPath
    Write-ZellijFinalSuccess
}

Invoke-ZellijInstall
