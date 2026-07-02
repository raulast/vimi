" ==========================================
" vimi — Isolated Vim IDE configuration
" Path: ~/.rast/.vim/vimrc
" Alias: vimi = vim -u ~/.rast/.vim/vimrc
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

" Extensions auto-installed on first launch with Node.js available
let g:coc_global_extensions = [
  \ 'coc-phpls',
  \ 'coc-go',
  \ 'coc-tsserver',
  \ 'coc-pyright',
  \ 'coc-sh',
  \ 'coc-lua',
  \ 'coc-html',
  \ 'coc-css',
  \ 'coc-clangd'
  \ ]

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

" IntelliSense engine (requires Node.js — works without it, activates automatically when Node is added)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()

" ==========================================
" 8. PLUGIN SETTINGS
" ==========================================

" --- NERDTree ---
let g:NERDTreeShowHidden = 1
let g:NERDTreeMinimalUI = 1
let g:NERDTreeIgnore = ['\.git$', 'node_modules', '__pycache__']
" Close NERDTree when opening a file
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
" Go to definition
nmap <silent> gd <Plug>(coc-definition)
" Go to type definition
nmap <silent> gy <Plug>(coc-type-definition)
" Go to references
nmap <silent> gr <Plug>(coc-references)
" Show documentation in preview window
nnoremap <silent> K :call CocActionAsync('doHover')<CR>
" Rename symbol
nmap <leader>rn <Plug>(coc-rename)
" Code action on cursor
nmap <leader>ca <Plug>(coc-codeaction-cursor)
" Format selected
xmap <leader>f <Plug>(coc-format-selected)
nmap <leader>f <Plug>(coc-format-selected)
" Navigate diagnostics
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)
" Show diagnostics list
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
