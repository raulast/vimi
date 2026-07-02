" ==========================================
" vimi — Isolated Vim IDE (LSP stack — Vim 8 compatible)
" Path: ~/.rast/.vim/vimrc
" Alias: vimi = vim -u ~/.rast/.vim/vimrc
" Re-run installer after upgrading Vim to 9.0.0438+ to switch to CoC stack
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
" 6. PLUGINS (vim-plug) — LSP stack (Vim 8 compatible)
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

" LSP client (Vim 8 compatible)
Plug 'prabirshrestha/vim-lsp'
" Auto-installs language servers on first file open (gopls, pyright, clangd, etc.)
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" Linting + diagnostics (replaces CoC diagnostics on Vim 8)
Plug 'dense-analysis/ale'

call plug#end()

" ==========================================
" 7. PLUGIN SETTINGS — LSP stack
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
" Usage: vim scp://user@host//path/to/file
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4

" --- vim-lsp ---
" ale handles diagnostics — disable vim-lsp built-in to avoid duplication
let g:lsp_diagnostics_enabled = 0
let g:lsp_document_highlight_enabled = 1
let g:lsp_signature_auto_enabled = 1

" --- asyncomplete ---
set completeopt+=menuone,noinsert,noselect
let g:asyncomplete_auto_popup = 1
let g:asyncomplete_auto_completeopt = 0

" Tab cycles through completion suggestions (same feel as CoC)
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" --- ale ---
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_insert_leave = 1
let g:ale_set_highlights = 0

" ==========================================
" 8. KEYMAPS — LSP stack (mirrors CoC stack keymaps)
" ==========================================

" Go to definition
nmap <silent> gd :LspDefinition<CR>
" Go to type definition
nmap <silent> gy :LspTypeDefinition<CR>
" Go to references
nmap <silent> gr :LspReferences<CR>
" Hover documentation
nnoremap <silent> K :LspHover<CR>
" Rename symbol
nmap <leader>rn :LspRename<CR>
" Code action
nmap <leader>ca :LspCodeAction<CR>
" Navigate diagnostics (ale)
nmap <silent> [g <Plug>(ale_previous_wrap)
nmap <silent> ]g <Plug>(ale_next_wrap)
" Diagnostics detail
nnoremap <silent> <leader>d :ALEDetail<CR>

" ==========================================
" 9. PLUGIN KEYMAPS (identical to CoC stack)
" ==========================================
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>N :NERDTreeFind<CR>
nnoremap <leader>p :Files<CR>
nnoremap <leader>/ :Rg<CR>
nnoremap <leader>bb :Buffers<CR>
