#!/bin/sh
# vimi — Isolated Vim IDE installer
# Usage: curl -fsSL https://raw.githubusercontent.com/raulast/vimi/main/install.sh | sh
# Usage: curl -fsSL https://raw.githubusercontent.com/raulast/vimi/main/install.sh | sh -s -- --langs go,python,ts
#
# Options:
#   --langs <list>   Comma-separated CoC extension keys to install.
#                    Valid keys: php go ts python sh lua html css cpp
#                    Default: all extensions
#
# This script:
#   - Installs vim-plug to ~/.rast/.vim/autoload/
#   - Writes vimrc to ~/.rast/.vim/vimrc
#   - Adds `vimi` alias to your shell profile
#   - Does NOT install Node.js, Go, Python, or clangd
#   - Does NOT require sudo
#   - Is safe to run multiple times (idempotent)

set -e

# ==========================================
# CONSTANTS
# ==========================================
VIMI_DIR="$HOME/.rast/.vim"
VIMRC="$VIMI_DIR/vimrc"
PLUG_URL="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
PLUG_DEST="$VIMI_DIR/autoload/plug.vim"
ALIAS_CMD='alias vimi="vim -u ~/.rast/.vim/vimrc"'
FISH_ALIAS_CMD="alias vimi 'vim -u ~/.rast/.vim/vimrc'"

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
# ARGUMENT PARSING (T-08)
# ==========================================
# Default: all 9 CoC extensions
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
                # Normalize: replace commas with spaces
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
# LANG → CoC EXTENSION MAP (T-09)
# ==========================================
lang_to_coc() {
    _lang="$1"
    case "$_lang" in
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
            print_warn "Unknown lang key: '$_lang' — skipped"
            printf ''
            ;;
    esac
}

build_coc_extensions_vimscript() {
    _first=1
    _result="let g:coc_global_extensions = ["
    for _lang in $LANGS; do
        _ext=$(lang_to_coc "$_lang")
        if [ -n "$_ext" ]; then
            if [ "$_first" -eq 1 ]; then
                _result="${_result}
  \\ '$_ext',"
                _first=0
            else
                _result="${_result}
  \\ '$_ext',"
            fi
        fi
    done
    # Remove trailing comma from last entry
    _result=$(printf '%s' "$_result" | sed '$ s/,$//')
    _result="${_result}
  \\ ]"
    printf '%s' "$_result"
}

# ==========================================
# OS DETECTION (T-10)
# ==========================================
detect_os() {
    _uname=$(uname -s)
    case "$_uname" in
        Linux*)  OS="linux" ;;
        Darwin*) OS="macos" ;;
        *)
            print_error "Unsupported OS: $_uname"
            print_error "This installer supports Linux and macOS only."
            print_error "For Windows, use: irm https://raw.githubusercontent.com/raulast/vimi/main/install.ps1 | iex"
            exit 1
            ;;
    esac
    print_info "Detected OS: $OS"
}

# ==========================================
# VIM CHECK + INSTALL GATE (T-11)
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
            install_vim
            ;;
        *)
            print_error "Vim installation declined. vimi requires Vim to work."
            print_error "Install Vim manually and re-run this script."
            print_info "  Linux (apt):  sudo apt-get install -y vim"
            print_info "  Linux (yum):  sudo yum install -y vim"
            print_info "  macOS:        brew install vim"
            exit 1
            ;;
    esac
}

install_vim() {
    # vimi never runs sudo. Installing Vim requires system-level access.
    # We provide the exact command and let the user run it.
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
    print_info "  curl -fsSL https://raw.githubusercontent.com/raulast/vimi/main/install.sh | sh"
    exit 1
}

# ==========================================
# DIRECTORY STRUCTURE (T-12)
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
# VIM-PLUG INSTALLATION (T-13)
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
# VIMRC GENERATION (T-14)
# ==========================================
write_vimrc() {
    print_info "Writing vimrc to $VIMRC ..."

    _coc_extensions=$(build_coc_extensions_vimscript)

    cat > "$VIMRC" << VIMRC_EOF
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
${_coc_extensions}

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
let g:NERDTreeIgnore = ['\.git\$', 'node_modules', '__pycache__']
let g:NERDTreeQuitOnOpen = 1

" --- vim-airline ---
let g:airline_powerline_fonts = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" --- Netrw (remote SSH editing) ---
" Usage: vim scp://user@host//path/to/file
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
" NERDTree toggle (Space + n)
nnoremap <leader>n :NERDTreeToggle<CR>
" NERDTree find current file (Space + N)
nnoremap <leader>N :NERDTreeFind<CR>

" FZF — fuzzy file search (Space + p)
nnoremap <leader>p :Files<CR>
" FZF — search in file content (Space + /)
nnoremap <leader>/ :Rg<CR>
" FZF — open buffers (Space + b)
nnoremap <leader>bb :Buffers<CR>
VIMRC_EOF

    print_success "vimrc written."
}

# ==========================================
# PLUGIN INSTALLATION (T-15)
# ==========================================
run_plugin_install() {
    print_info "Installing Vim plugins (this may take a minute)..."
    vim -u "$VIMRC" +PlugInstall +qall 2>/dev/null || true
    print_success "Plugins installed."
    print_info "Note: CoC extensions will auto-install on first 'vimi' launch when Node.js is available."
}

# ==========================================
# SHELL DETECTION (T-16)
# ==========================================
detect_shell() {
    # Try to detect from running shell first
    if [ -n "$ZSH_VERSION" ]; then
        printf 'zsh'
    elif [ -n "$BASH_VERSION" ]; then
        printf 'bash'
    elif [ -n "$FISH_VERSION" ]; then
        printf 'fish'
    else
        # Fallback: inspect $SHELL variable
        case "$SHELL" in
            */zsh)  printf 'zsh' ;;
            */bash) printf 'bash' ;;
            */fish) printf 'fish' ;;
            *)      printf 'other' ;;
        esac
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
# ALIAS INSTALLATION (T-17)
# ==========================================
add_alias() {
    _shell=$(detect_shell)
    _profile=$(profile_for_shell "$_shell")

    print_info "Detected shell: $_shell"
    print_info "Shell profile: $_profile"

    # Create fish config dir if needed
    if [ "$_shell" = "fish" ]; then
        mkdir -p "$HOME/.config/fish"
    fi

    # Create profile file if it doesn't exist
    if [ ! -f "$_profile" ]; then
        touch "$_profile"
    fi

    # Check for existing alias (avoid duplicates)
    if grep -q 'alias vimi' "$_profile" 2>/dev/null; then
        print_success "Alias 'vimi' already present in $_profile — skipping."
        return 0
    fi

    # Write alias with fish-specific syntax
    if [ "$_shell" = "fish" ]; then
        printf '\n# vimi — isolated Vim IDE\n%s\n' "$FISH_ALIAS_CMD" >> "$_profile"
    else
        printf '\n# vimi — isolated Vim IDE\n%s\n' "$ALIAS_CMD" >> "$_profile"
    fi

    print_success "Alias 'vimi' added to $_profile"
}

# ==========================================
# LSP DEPENDENCY CHECK (T-18)
# ==========================================
check_lsp_deps() {
    print_info "Checking LSP dependencies..."
    _all_found=1

    if ! command -v node >/dev/null 2>&1; then
        print_warn "Node.js not found — CoC extensions for JS/TS/PHP/HTML/CSS/Bash/Lua will not activate until Node.js is installed."
        print_warn "  Once installed, CoC will activate automatically on next 'vimi' launch."
        _all_found=0
    else
        _node_version=$(node --version)
        print_success "Node.js found: $_node_version"
    fi

    if ! command -v python3 >/dev/null 2>&1; then
        print_warn "Python 3 not found — coc-pyright (Python IntelliSense) will not work."
        _all_found=0
    else
        _py_version=$(python3 --version)
        print_success "Python 3 found: $_py_version"
    fi

    if ! command -v go >/dev/null 2>&1; then
        print_warn "Go not found — coc-go (Go IntelliSense) will not work."
        _all_found=0
    else
        _go_version=$(go version)
        print_success "Go found: $_go_version"
    fi

    if ! command -v clangd >/dev/null 2>&1; then
        print_warn "clangd not found — coc-clangd (C/C++ IntelliSense) will not work."
        print_warn "  Install with: sudo apt install clangd  (or equivalent for your distro)"
        _all_found=0
    else
        print_success "clangd found."
    fi

    if [ "$_all_found" -eq 1 ]; then
        print_success "All LSP dependencies found — CoC will be fully functional."
    fi
}

# ==========================================
# SUCCESS MESSAGE (T-19)
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
    print_info "To start using vimi, reload your shell:"
    printf '\n'
    printf '    source %s\n' "$(profile_for_shell "$(detect_shell)")"
    printf '\n'
    print_info "Then launch your isolated Vim IDE with:"
    printf '\n'
    printf '    vimi\n'
    printf '\n'
    print_info "Installed files:"
    printf '    %s/vimrc\n' "$VIMI_DIR"
    printf '    %s/autoload/plug.vim\n' "$VIMI_DIR"
    printf '\n'
    print_info "System vim is unchanged. Run 'vim' for the original editor."
    printf '\n'
}

# ==========================================
# MAIN (T-20)
# ==========================================
main() {
    printf '\n'
    print_info "Starting vimi installation..."
    printf '\n'

    parse_args "$@"
    detect_os
    check_vim
    create_dirs
    install_vimplug
    write_vimrc
    run_plugin_install
    add_alias
    check_lsp_deps
    print_final_success
}

main "$@"
