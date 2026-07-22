#!/bin/sh
# vimi — Isolated Vim IDE installer
# Usage: curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh
# Usage: curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh -s -- --langs go,python,ts
#
# Options:
#   --langs <list>   Comma-separated CoC extension keys (CoC stack only — Vim 9+).
#                    Valid keys: php go ts python sh lua html css cpp
#                    Default: all extensions
#                    Ignored when Vim < 9.0.0438 (LSP stack selected automatically)
#
# Stack selection (automatic — no action required):
#   Vim >= 9.0.0438  →  CoC stack  (coc.nvim — full IntelliSense + Node.js)
#   Vim <  9.0.0438  →  LSP stack  (vim-lsp + asyncomplete + ale)
#
# This script:
#   - Detects Vim version and selects the appropriate plugin stack
#   - Downloads the matching vimrc from GitHub
#   - Installs vim-plug to ~/.rast/.vim/autoload/
#   - Adds `vimi` alias to your shell profile
#   - Does NOT install Node.js, Go, Python, or clangd
#   - Does NOT require sudo
#   - Is safe to run multiple times (idempotent — re-run after upgrading Vim)

set -e

# ==========================================
# CONSTANTS
# ==========================================
VIMI_DIR="$HOME/.rast/.vim"
VIMRC="$VIMI_DIR/vimrc"
RAW_BASE="https://raw.githubusercontent.com/raulast/vimi/master"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
PLUG_DEST="$VIMI_DIR/autoload/plug.vim"
ALIAS_CMD='alias vimi="vim -u ~/.rast/.vim/vimrc"'
FISH_ALIAS_CMD="alias vimi 'vim -u ~/.rast/.vim/vimrc'"
STACK=""

# ==========================================
# COLOR HELPERS
# ==========================================
_has_color() {
    [ -t 1 ] && command -v tput >/dev/null 2>&1
}

print_info() {
    if _has_color; then
        printf "\033[34m[vimi]\033[0m %s\n" "$1"
    else
        printf "[vimi] %s\n" "$1"
    fi
}

print_success() {
    if _has_color; then
        printf "\033[32m[vimi] ✓\033[0m %s\n" "$1"
    else
        printf "[vimi] ✓ %s\n" "$1"
    fi
}

print_warn() {
    if _has_color; then
        printf "\033[33m[vimi] ⚠\033[0m %s\n" "$1" >&2
    else
        printf "[vimi] ⚠ %s\n" "$1" >&2
    fi
}

print_error() {
    if _has_color; then
        printf "\033[31m[vimi] ✗\033[0m %s\n" "$1" >&2
    else
        printf "[vimi] ✗ %s\n" "$1" >&2
    fi
}

# ==========================================
# ARGUMENT PARSING
# ==========================================
DEFAULT_LANGS="php go ts python sh lua html css cpp"
LANGS=""

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --langs)
                if [ -z "$2" ] || [ "${2#-}" != "$2" ]; then
                    print_error "--langs requires a value (e.g. --langs go,python,ts)"
                    exit 1
                fi
                LANGS=$(printf '%s' "$2" | tr ',' ' ')
                shift 2
                ;;
            --langs=*)
                LANGS=$(printf '%s' "${1#--langs=}" | tr ',' ' ')
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                print_warn "Unknown option: $1 — ignored"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ -z "$LANGS" ]; then
        LANGS="$DEFAULT_LANGS"
    fi
}

# ==========================================
# LANG → CoC EXTENSION MAP
# ==========================================
lang_to_coc() {
    case "$1" in
        php)    printf 'coc-phpls' ;;
        go)     printf 'coc-go' ;;
        ts)     printf 'coc-tsserver' ;;
        python) printf 'coc-pyright' ;;
        sh)     printf 'coc-sh' ;;
        lua)    printf 'coc-lua' ;;
        html)   printf 'coc-html' ;;
        css)    printf 'coc-css' ;;
        cpp)    printf 'coc-clangd' ;;
        *)
            print_warn "Unknown lang key: '$1' — skipped"
            printf ''
            ;;
    esac
}

# ==========================================
# OS DETECTION
# ==========================================
detect_os() {
    _uname=$(uname -s)
    case "$_uname" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="macos" ;;
        *)
            print_error "Unsupported OS: $_uname"
            print_error "For Windows use: irm https://raw.githubusercontent.com/raulast/vimi/master/install.ps1 | iex"
            exit 1
            ;;
    esac
    print_info "Detected OS: $OS"
}

# ==========================================
# VIM VERSION DETECTION
# ==========================================

# Outputs "major minor patch" as space-separated integers
# Handles: "8.2", "9.0", "9.0.0438", "9.1.123"
get_vim_version() {
    _raw=$(vim --version 2>/dev/null | head -1)
    _ver=$(printf '%s' "$_raw" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _major=$(printf '%s' "$_ver" | cut -d. -f1)
    _minor=$(printf '%s' "$_ver" | cut -d. -f2)
    _patch=$(printf '%s' "$_ver" | cut -d. -f3)
    case "$_patch" in
        ''|*[!0-9]*) _patch=0 ;;
    esac
    printf '%s %s %s' "${_major:-0}" "${_minor:-0}" "$_patch"
}

# Returns 0 (true) if vim >= 9.0.0438
vim_is_v9() {
    set -- $(get_vim_version)
    _maj=$1; _min=$2; _pat=$3
    if [ "$_maj" -gt 9 ]; then return 0; fi
    if [ "$_maj" -eq 9 ] && [ "$_min" -gt 0 ]; then return 0; fi
    if [ "$_maj" -eq 9 ] && [ "$_min" -eq 0 ] && [ "$_pat" -ge 438 ]; then return 0; fi
    return 1
}

# ==========================================
# VIM CHECK + INSTALL GATE
# ==========================================
check_vim() {
    if command -v vim >/dev/null 2>&1; then
        _vim_version=$(vim --version | head -1)
        print_success "Vim found: $_vim_version"
        return 0
    fi

    print_warn "Vim is not installed on this system."
    printf '[vimi] Install Vim now? [y/N] ' >/dev/tty
    read -r _answer </dev/tty

    case "$_answer" in
        [yY]|[yY][eE][sS])
            print_warn "Vim must be installed at the system level (requires sudo or admin access)."
            print_warn "vimi does not run sudo. Please install Vim manually with one of:"
            printf '\n'
            if command -v apt-get >/dev/null 2>&1; then
                print_info "  sudo apt-get install -y vim"
            elif command -v yum >/dev/null 2>&1; then
                print_info "  sudo yum install -y vim"
            elif command -v dnf >/dev/null 2>&1; then
                print_info "  sudo dnf install -y vim"
            elif command -v brew >/dev/null 2>&1; then
                print_info "  brew install vim"
            else
                print_info "  sudo apt-get install -y vim    # Debian/Ubuntu"
                print_info "  sudo yum install -y vim        # RHEL/CentOS"
                print_info "  brew install vim               # macOS"
            fi
            printf '\n'
            print_info "After installing Vim, re-run this installer:"
            print_info "  curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh"
            exit 1
            ;;
        *)
            print_error "Vim installation declined. vimi requires Vim to work."
            exit 1
            ;;
    esac
}

# ==========================================
# STACK DETECTION
# ==========================================
detect_stack() {
    _ver_str=$(get_vim_version | tr ' ' '.')
    if vim_is_v9; then
        STACK="coc"
        print_success "Vim $_ver_str — CoC stack selected (full IntelliSense)"
    else
        STACK="lsp"
        print_info "Vim $_ver_str — LSP stack selected (vim-lsp + asyncomplete + ale)"
        print_info "CoC stack requires Vim 9.0.0438+. Re-run this installer after upgrading Vim."
    fi

    if [ "$STACK" = "lsp" ] && [ "$LANGS" != "$DEFAULT_LANGS" ]; then
        print_info "--langs flag ignored on LSP stack. Language servers are auto-detected by filetype via vim-lsp-settings."
    fi
}

# ==========================================
# DIRECTORY STRUCTURE
# ==========================================
create_dirs() {
    print_info "Creating directory structure under $VIMI_DIR ..."
    mkdir -p \
        "$VIMI_DIR/autoload" \
        "$VIMI_DIR/backup" \
        "$VIMI_DIR/swap" \
        "$VIMI_DIR/undo" \
        "$VIMI_DIR/coc" \
        "$VIMI_DIR/plugged"
    print_success "Directories ready."
}

# ==========================================
# VIM-PLUG INSTALLATION
# ==========================================
install_vimplug() {
    if [ -f "$PLUG_DEST" ]; then
        print_success "vim-plug already installed — skipping download."
        return 0
    fi

    print_info "Installing vim-plug..."
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is required to download vim-plug but was not found."
        exit 1
    fi

    curl -fLo "$PLUG_DEST" --create-dirs "$PLUG_URL"
    print_success "vim-plug installed."
}

# ==========================================
# VIMRC DOWNLOAD + PATCH (CoC extensions)
# ==========================================
write_vimrc() {
    print_info "Downloading vimrc ($STACK stack)..."

    if [ "$STACK" = "lsp" ]; then
        # LSP stack: download as-is — vim-lsp-settings handles language servers
        curl -fsSL "$RAW_BASE/vimrc.lsp" -o "$VIMRC"
        print_success "vimrc written (LSP stack)."
        return 0
    fi

    # CoC stack: download base then patch g:coc_global_extensions with selected langs
    _tmp=$(mktemp)
    _out=$(mktemp)
    curl -fsSL "$RAW_BASE/vimrc.coc" -o "$_tmp"

    # Build the coc_global_extensions block as a temp file
    _exts_file=$(mktemp)
    printf 'let g:coc_global_extensions = [\n' > "$_exts_file"
    _last_ext=""
    for _lang in $LANGS; do
        _ext=$(lang_to_coc "$_lang")
        if [ -n "$_ext" ]; then
            # Flush previous line (so we can omit trailing comma on last)
            if [ -n "$_last_ext" ]; then
                printf "  \\ '%s',\n" "$_last_ext" >> "$_exts_file"
            fi
            _last_ext="$_ext"
        fi
    done
    # Write last entry without trailing comma
    if [ -n "$_last_ext" ]; then
        printf "  \\ '%s'\n" "$_last_ext" >> "$_exts_file"
    fi
    printf "  \\ ]\n" >> "$_exts_file"

    # Replace the static block in the downloaded vimrc using line-by-line processing
    _in_block=0
    while IFS= read -r _line; do
        case "$_line" in
            'let g:coc_global_extensions = ['*)
                cat "$_exts_file"
                _in_block=1
                ;;
            '  \ ]')
                if [ "$_in_block" -eq 1 ]; then
                    _in_block=0
                else
                    printf '%s\n' "$_line"
                fi
                ;;
            *)
                if [ "$_in_block" -eq 0 ]; then
                    printf '%s\n' "$_line"
                fi
                ;;
        esac
    done < "$_tmp" > "$_out"

    mv "$_out" "$VIMRC"
    rm -f "$_tmp" "$_exts_file"
    print_success "vimrc written (CoC stack, langs: $LANGS)."
}

# ==========================================
# PLUGIN INSTALLATION
# ==========================================
run_plugin_install() {
    print_info "Installing Vim plugins (this may take a minute)..."
    vim -u "$VIMRC" +PlugInstall +qall 2>/dev/null || true

    if [ "$STACK" = "coc" ]; then
        print_success "Plugins installed."
        print_info "CoC extensions will auto-install on first 'vimi' launch when Node.js is available."
    else
        print_success "Plugins installed."
        print_info "Language servers (gopls, pyright, clangd…) will auto-install on first file open via vim-lsp-settings."
    fi
}

# ==========================================
# SHELL DETECTION
# ==========================================
detect_shell() {
    # $SHELL is the most reliable indicator of the user's actual shell,
    # even when the script runs inside a sh subshell (curl | sh).
    case "$SHELL" in
        */zsh)  printf 'zsh';  return ;;
        */bash) printf 'bash'; return ;;
        */fish) printf 'fish'; return ;;
    esac

    # Fallback: version variables (useful when $SHELL is unset or /bin/sh)
    if [ -n "$ZSH_VERSION" ]; then
        printf 'zsh'
    elif [ -n "$FISH_VERSION" ]; then
        printf 'fish'
    elif [ -n "$BASH_VERSION" ]; then
        printf 'bash'
    else
        printf 'other'
    fi
}

profile_for_shell() {
    case "$1" in
        zsh)   printf '%s' "$HOME/.zshrc" ;;
        bash)  printf '%s' "$HOME/.bashrc" ;;
        fish)  printf '%s' "$HOME/.config/fish/config.fish" ;;
        *)     printf '%s' "$HOME/.profile" ;;
    esac
}

# ==========================================
# ALIAS INSTALLATION
# ==========================================
add_alias() {
    _shell=$(detect_shell)
    _profile=$(profile_for_shell "$_shell")

    print_info "Detected shell: $_shell"
    print_info "Shell profile: $_profile"

    if [ "$_shell" = "fish" ]; then
        mkdir -p "$HOME/.config/fish"
    fi

    if [ ! -f "$_profile" ]; then
        touch "$_profile"
    fi

    if grep -q 'alias vimi' "$_profile" 2>/dev/null; then
        print_success "Alias 'vimi' already present in $_profile — skipping."
        return 0
    fi

    if [ "$_shell" = "fish" ]; then
        printf '\n# vimi — isolated Vim IDE\n%s\n' "$FISH_ALIAS_CMD" >> "$_profile"
    else
        printf '\n# vimi — isolated Vim IDE\n%s\n' "$ALIAS_CMD" >> "$_profile"
    fi

    print_success "Alias 'vimi' added to $_profile"
}

# ==========================================
# LSP DEPENDENCY CHECK
# ==========================================
check_lsp_deps() {
    print_info "Checking LSP dependencies..."
    _all_found=1

    if ! command -v node >/dev/null 2>&1; then
        if [ "$STACK" = "coc" ]; then
            print_warn "Node.js not found — CoC extensions will not activate until Node.js is installed."
            print_warn "  Once installed, CoC activates automatically on next 'vimi' launch."
        else
            print_warn "Node.js not found — some vim-lsp-settings language servers require Node.js."
        fi
        _all_found=0
    else
        print_success "Node.js found: $(node --version)"
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        if [ "$STACK" = "coc" ]; then
            print_warn "Python 3 not found — coc-pyright (Python IntelliSense) will not work."
        else
            print_warn "Python 3 not found — vim-lsp Python support will not work."
        fi
        _all_found=0
    else
        print_success "Python 3 found: $(python3 --version)"
    fi

    if ! command -v go >/dev/null 2>&1; then
        if [ "$STACK" = "coc" ]; then
            print_warn "Go not found — coc-go (Go IntelliSense) will not work."
        else
            print_warn "Go not found — vim-lsp Go support (gopls) will not work."
        fi
        _all_found=0
    else
        print_success "Go found: $(go version)"
    fi

    if ! command -v clangd >/dev/null 2>&1; then
        if [ "$STACK" = "coc" ]; then
            print_warn "clangd not found — coc-clangd (C/C++ IntelliSense) will not work."
        else
            print_warn "clangd not found — vim-lsp C/C++ support will not work."
        fi
        print_warn "  Install: sudo apt install clangd  (or equivalent)"
        _all_found=0
    else
        print_success "clangd found."
    fi

    if [ "$_all_found" -eq 1 ]; then
        print_success "All LSP dependencies found."
    fi
}

# ==========================================
# SUCCESS MESSAGE
# ==========================================
print_final_success() {
    printf '\n'
    if _has_color; then
        printf "\033[32m============================================\033[0m\n"
        printf "\033[32m  vimi installed successfully!\033[0m\n"
        printf "\033[32m============================================\033[0m\n"
    else
        printf "============================================\n"
        printf "  vimi installed successfully!\n"
        printf "============================================\n"
    fi
    printf '\n'

    if [ "$STACK" = "coc" ]; then
        print_info "Stack: CoC (Vim 9+ — full IntelliSense via coc.nvim)"
    else
        print_info "Stack: LSP (Vim 8 — vim-lsp + asyncomplete + ale)"
        print_info "Upgrade to CoC stack anytime: upgrade Vim to 9.0.0438+ then re-run:"
        printf '    curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/install.sh | sh\n'
        printf '\n'
    fi

    print_info "Reload your shell to activate the alias:"
    printf '\n'
    printf '    source %s\n' "$(profile_for_shell "$(detect_shell)")"
    printf '\n'
    print_info "Then launch your isolated Vim IDE:"
    printf '\n'
    printf '    vimi\n'
    printf '\n'
    print_info "System vim is unchanged. Run 'vim' for the original editor."
    printf '\n'
}

# ==========================================
# ZELLIJ PROMPT
# ==========================================
prompt_zellij() {
    # Skip when running non-interactively (e.g. curl | sh)
    [ -t 0 ] || return 0

    printf '\n'
    print_info "─────────────────────────────────────────"
    printf '[zellij] Install Zellij terminal multiplexer? (y/N) '
    read -r _zellij_ans
    case "$_zellij_ans" in
        [yY])
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh)"
            ;;
        *)
            print_info "Skipping Zellij. Install anytime:"
            printf '    curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh | sh\n'
            ;;
    esac
}

# ==========================================
# MAIN
# ==========================================
main() {
    printf '\n'
    print_info "Starting vimi installation..."
    printf '\n'

    parse_args "$@"
    detect_os
    check_vim
    detect_stack
    create_dirs
    install_vimplug
    write_vimrc
    run_plugin_install
    add_alias
    check_lsp_deps
    print_final_success
    prompt_zellij
}

main "$@"
