#!/bin/sh
# zellij — Isolated Zellij installer
# Usage: curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh | sh
#
# This script:
#   - Downloads the latest Zellij binary from GitHub releases
#   - Installs it to ~/.rast/.zellij/bin/zellij
#   - Creates a symlink at ~/.local/bin/zellij
#   - Adds ~/.local/bin to your shell PATH if not already present
#   - Does NOT require sudo
#   - Is safe to run multiple times (always updates to latest)

set -e

# ==========================================
# CONSTANTS
# ==========================================
ZELLIJ_DIR="$HOME/.rast/.zellij"
ZELLIJ_BIN="$ZELLIJ_DIR/bin/zellij"
ZELLIJ_LINK="$HOME/.local/bin/zellij"
RAW_BASE="https://github.com/zellij-org/zellij/releases/latest/download"

# ==========================================
# COLOR HELPERS
# ==========================================
_has_color() {
    [ -t 1 ] && command -v tput >/dev/null 2>&1
}

print_info() {
    if _has_color; then
        printf "\033[34m[zellij]\033[0m %s\n" "$1"
    else
        printf "[zellij] %s\n" "$1"
    fi
}

print_success() {
    if _has_color; then
        printf "\033[32m[zellij] ✓\033[0m %s\n" "$1"
    else
        printf "[zellij] ✓ %s\n" "$1"
    fi
}

print_warn() {
    if _has_color; then
        printf "\033[33m[zellij] ⚠\033[0m %s\n" "$1" >&2
    else
        printf "[zellij] ⚠ %s\n" "$1" >&2
    fi
}

print_error() {
    if _has_color; then
        printf "\033[31m[zellij] ✗\033[0m %s\n" "$1" >&2
    else
        printf "[zellij] ✗ %s\n" "$1" >&2
    fi
}

# ==========================================
# DEPENDENCY CHECK
# ==========================================
check_deps() {
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl not found — required to download Zellij"
        exit 1
    fi
    if ! command -v tar >/dev/null 2>&1; then
        print_error "tar not found — required to extract Zellij"
        exit 1
    fi
}

# ==========================================
# ARCH / OS DETECTION
# ==========================================
detect_arch() {
    case $(uname -m) in
        x86_64)          printf 'x86_64'  ;;
        aarch64)         printf 'aarch64' ;;
        arm64)           printf 'aarch64' ;;
        *)
            print_error "Unsupported CPU architecture: $(uname -m)"
            exit 2
            ;;
    esac
}

detect_sys() {
    case $(uname -s) in
        Linux)  printf 'unknown-linux-musl' ;;
        Darwin) printf 'apple-darwin'       ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 2
            ;;
    esac
}

# ==========================================
# DOWNLOAD BINARY
# ==========================================
download_binary() {
    _arch=$(detect_arch)
    _sys=$(detect_sys)
    _url="$RAW_BASE/zellij-$_arch-$_sys.tar.gz"

    print_info "Downloading Zellij for $_arch-$_sys..."
    print_info "Source: $_url"

    mkdir -p "$ZELLIJ_DIR/bin"

    if ! curl --location --fail --silent --show-error "$_url" | tar -C "$ZELLIJ_DIR/bin" -xz; then
        printf '\n' >&2
        print_error "Download or extraction failed."
        print_error "A new release may currently be building — try again in a few minutes."
        exit 1
    fi

    chmod +x "$ZELLIJ_BIN"
    print_success "Binary installed: $ZELLIJ_BIN"
}

# ==========================================
# SYMLINK
# ==========================================
setup_symlink() {
    mkdir -p "$HOME/.local/bin"
    ln -sf "$ZELLIJ_BIN" "$ZELLIJ_LINK"
    print_success "Symlink created: $ZELLIJ_LINK"
}

# ==========================================
# SHELL DETECTION (for PATH setup)
# ==========================================
_detect_shell() {
    case "$SHELL" in
        */zsh)  printf 'zsh';  return ;;
        */bash) printf 'bash'; return ;;
        */fish) printf 'fish'; return ;;
    esac
    if [ -n "$ZSH_VERSION" ];  then printf 'zsh'
    elif [ -n "$FISH_VERSION" ]; then printf 'fish'
    elif [ -n "$BASH_VERSION" ]; then printf 'bash'
    else printf 'other'
    fi
}

_profile_for_shell() {
    case "$1" in
        zsh)  printf '%s' "$HOME/.zshrc" ;;
        bash) printf '%s' "$HOME/.bashrc" ;;
        fish) printf '%s' "$HOME/.config/fish/config.fish" ;;
        *)    printf '%s' "$HOME/.profile" ;;
    esac
}

# ==========================================
# PATH SETUP
# ==========================================
setup_path() {
    _shell=$(_detect_shell)
    _profile=$(_profile_for_shell "$_shell")

    if [ ! -f "$_profile" ]; then
        touch "$_profile"
    fi

    if grep -q '\.local/bin' "$_profile" 2>/dev/null; then
        print_success "PATH already configured in $_profile — skipping."
        return 0
    fi

    printf '\n# zellij — add ~/.local/bin to PATH\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$_profile"
    print_success "PATH updated in $_profile"
    print_info  "Reload your shell to activate: source $_profile"
}

# ==========================================
# SUCCESS MESSAGE
# ==========================================
print_final_success() {
    printf '\n'
    if _has_color; then
        printf "\033[32m============================================\033[0m\n"
        printf "\033[32m  Zellij installed successfully!\033[0m\n"
        printf "\033[32m============================================\033[0m\n"
    else
        printf "============================================\n"
        printf "  Zellij installed successfully!\n"
        printf "============================================\n"
    fi
    printf '\n'
    print_info "Binary:  $ZELLIJ_BIN"
    print_info "Symlink: $ZELLIJ_LINK"
    printf '\n'
    print_info "Reload your shell, then verify:"
    printf '\n'
    printf '    zellij --version\n'
    printf '\n'
    print_info "Re-run this script anytime to update to the latest version."
    printf '\n'
}

# ==========================================
# MAIN
# ==========================================
main() {
    printf '\n'
    print_info "Starting Zellij installation..."
    printf '\n'

    check_deps
    download_binary
    setup_symlink
    setup_path
    print_final_success
}

main "$@"
