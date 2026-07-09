# vimi Manual

> Complete reference for Vim fundamentals and all vimi IDE keybindings.
> Works for both stacks: **CoC** (Vim 9.0.0438+) and **LSP** (Vim 8).

---

## Quick Reference

All keybindings at a glance. Leader key is `Space`.

### Modes

| Key | Action |
|-----|--------|
| `i` | Enter Insert mode (before cursor) |
| `a` | Enter Insert mode (after cursor) |
| `v` | Enter Visual mode (character) |
| `V` | Enter Visual mode (line) |
| `Ctrl+v` | Enter Visual Block mode |
| `:` | Enter Command mode |
| `Esc` | Return to Normal mode |

### Navigation

| Key | Action |
|-----|--------|
| `h / j / k / l` | Left / Down / Up / Right |
| `w / b` | Next / previous word |
| `e` | End of word |
| `0 / ^` | Start of line / first non-blank |
| `$` | End of line |
| `gg / G` | First / last line |
| `Ctrl+d / Ctrl+u` | Scroll half-page down / up |
| `Ctrl+h/j/k/l` | Move to window split (vimi) |

### Editing

| Key | Action |
|-----|--------|
| `o / O` | New line below / above (enters Insert) |
| `I / A` | Insert at line start / end |
| `x` | Delete character under cursor |
| `dd` | Delete (cut) line |
| `dw` | Delete word |
| `yy` | Yank (copy) line |
| `p / P` | Paste after / before cursor |
| `cw` | Change word (delete + enter Insert) |
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last change |

### Search & Replace

| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n / N` | Next / previous match |
| `* / #` | Search word under cursor (fwd / bwd) |
| `Space+h` | Clear search highlight (vimi) |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all — confirm each |

### Buffers

| Key | Action |
|-----|--------|
| `Space+bb` | List open buffers (vimi) |
| `Space+bn` | Next buffer (vimi) |
| `Space+bp` | Previous buffer (vimi) |
| `Space+bd` | Close buffer (vimi) |

### File & Window

| Key | Action |
|-----|--------|
| `Space+p` | Fuzzy file search (vimi) |
| `Space+/` | Search inside files — ripgrep (vimi) |
| `Space+n` | Toggle file tree (vimi) |
| `Space+N` | Reveal current file in tree (vimi) |
| `Space+w` | Save file (vimi) |
| `Space+q` | Quit (vimi) |
| `Space+t` | Open integrated terminal (vimi) |

### Splits

| Key | Action |
|-----|--------|
| `Space+sv` | Vertical split (vimi) |
| `Space+sh` | Horizontal split (vimi) |
| `Space+sx` | Close current split (vimi) |
| `Space+se` | Equalize all split sizes (vimi) |
| `Space+.` | Alternate to last buffer (vimi) |

### Quickfix

| Key | Action |
|-----|--------|
| `Space+co` | Open quickfix list (vimi) |
| `Space+cc` | Close quickfix list (vimi) |
| `Space+cn` | Next quickfix item (vimi) |
| `Space+cp` | Previous quickfix item (vimi) |

### IntelliSense

| Key | Action | Notes |
|-----|--------|-------|
| `gd` | Go to definition | Both stacks |
| `gy` | Go to type definition | Both stacks |
| `gr` | Go to references | Both stacks |
| `K` | Show documentation | Both stacks |
| `Space+rn` | Rename symbol | Both stacks |
| `Space+ca` | Code action | Both stacks |
| `Space+f` | Format document | Both stacks |
| `[g` | Previous diagnostic | Both stacks |
| `]g` | Next diagnostic | Both stacks |
| `Space+d` | Diagnostics list | Both stacks |
| `Tab` | Cycle completion suggestions | Both stacks |

### Zellij

| Key | Action |
|-----|--------|
| `Ctrl+g` | Toggle locked / normal mode |
| `Alt+n` | New pane |
| `Alt+Arrow` | Move focus to pane |
| `Ctrl+w` | Close pane |
| `Alt+f` | Toggle pane fullscreen |
| `Alt+t` | New tab |
| `Alt+1..9` | Switch to tab N |
| `Ctrl+q` | Quit Zellij |

---

## 1. Vim Modes

Vim is a **modal editor** — keys do different things depending on the active mode. This is the core concept that makes Vim fast once you internalize it.

| Mode | How to enter | What keys do |
|------|-------------|--------------|
| **Normal** | `Esc` from any mode | Navigate, run commands, trigger keybindings |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O` from Normal | Type text like a regular editor |
| **Visual** | `v` (char), `V` (line), `Ctrl+v` (block) | Select text to operate on |
| **Command** | `:` from Normal | Run Ex commands (`:w`, `:q`, `:s/...`) |

**The most important habit**: press `Esc` to get back to Normal mode before doing anything else. Normal mode is your home base.

```
Normal ──(i/a/o)──► Insert
Normal ──(v/V)───► Visual
Normal ──(:)─────► Command
Insert/Visual/Command ──(Esc)──► Normal
```

---

## 2. Navigation

### Basic Motion (Normal mode)

```
        k
        ↑
    h ← → l
        ↓
        j
```

| Key | Moves to |
|-----|---------|
| `h` | One character left |
| `l` | One character right |
| `j` | One line down |
| `k` | One line up |
| `w` | Start of next word |
| `b` | Start of previous word |
| `e` | End of current word |
| `0` | Start of line (column 0) |
| `^` | First non-blank character of line |
| `$` | End of line |
| `gg` | First line of file |
| `G` | Last line of file |
| `{number}G` | Jump to line number (e.g. `42G`) |
| `Ctrl+d` | Scroll half-page down |
| `Ctrl+u` | Scroll half-page up |
| `Ctrl+f` | Scroll full page down |
| `Ctrl+b` | Scroll full page up |
| `%` | Jump to matching bracket/paren |

### Prefixing with a Count

Most motions accept a number prefix. Examples:
- `3j` → move 3 lines down
- `5w` → jump 5 words forward
- `10dd` → delete 10 lines

### Window Splits

Open splits with Command mode, navigate with vimi keybindings:

| Command | Action |
|---------|--------|
| `:sp` | Horizontal split |
| `:vsp` | Vertical split |
| `:sp filename` | Open file in horizontal split |
| `Ctrl+h` | Move focus left (vimi) |
| `Ctrl+j` | Move focus down (vimi) |
| `Ctrl+k` | Move focus up (vimi) |
| `Ctrl+l` | Move focus right (vimi) |
| `Space+sv` | Vertical split (vimi) |
| `Space+sh` | Horizontal split (vimi) |
| `Space+sx` | Close current split (vimi) |
| `Space+se` | Equalize all split sizes (vimi) |
| `:q` / `Space+q` | Close current split |

### Resizing Splits

| Key | Action |
|-----|--------|
| `Ctrl+w >` | Increase width |
| `Ctrl+w <` | Decrease width |
| `Ctrl+w +` | Increase height |
| `Ctrl+w -` | Decrease height |
| `Space+se` | Equalize all splits (vimi) |
| `{n}Ctrl+w >` | Increase width by n columns (e.g. `5Ctrl+w >`) |

---

## 3. Editing Essentials

### Entering Insert Mode

| Key | Starts insert at |
|-----|-----------------|
| `i` | Before cursor |
| `a` | After cursor |
| `I` | Beginning of line |
| `A` | End of line |
| `o` | New line below |
| `O` | New line above |
| `s` | Delete char + insert |
| `cc` or `S` | Delete line + insert |

### Deleting and Cutting

`d` is the delete operator — it also cuts (puts text in the unnamed register).

| Key | Deletes |
|-----|---------|
| `x` | Character under cursor |
| `X` | Character before cursor |
| `dw` | From cursor to end of word |
| `db` | From cursor to start of word |
| `dd` | Entire line |
| `d$` or `D` | From cursor to end of line |
| `d0` | From cursor to start of line |
| `dgg` | From cursor to first line |
| `dG` | From cursor to last line |

### Changing

`c` is like `d` but puts you in Insert mode after deleting.

| Key | Changes |
|-----|---------|
| `cw` | Word (from cursor) |
| `cc` / `S` | Entire line |
| `c$` / `C` | To end of line |
| `ci"` | Inside quotes |
| `ci(` | Inside parentheses |
| `ci{` | Inside braces |

### Yanking (Copying) and Pasting

| Key | Action |
|-----|--------|
| `yy` or `Y` | Yank line |
| `yw` | Yank word |
| `y$` | Yank to end of line |
| `p` | Paste after cursor / below line |
| `P` | Paste before cursor / above line |

### Undo and Redo

| Key | Action |
|-----|--------|
| `u` | Undo last change |
| `Ctrl+r` | Redo |
| `.` | Repeat last change |
| `U` | Undo all changes on current line |

vimi is configured with **persistent undo** — undo history survives closing and reopening the file.

---

## 4. Search & Replace

### Searching

| Key | Action |
|-----|--------|
| `/pattern` | Search forward for pattern |
| `?pattern` | Search backward for pattern |
| `n` | Jump to next match |
| `N` | Jump to previous match |
| `*` | Search forward for word under cursor |
| `#` | Search backward for word under cursor |
| `Space+h` | Clear search highlight (vimi) |

Searches are case-insensitive by default. To force case-sensitive, append `\C` to the pattern: `/MyFunc\C`.

### Replacing (Substitute)

```vim
:%s/old/new/g       " Replace all occurrences in the file
:%s/old/new/gc      " Replace all — ask for confirmation each time
:5,10s/old/new/g    " Replace only on lines 5 to 10
:s/old/new/g        " Replace on current line only
```

**Flags**:
- `g` — all occurrences per line (without it, only the first per line)
- `c` — confirm each replacement
- `i` — case-insensitive

---

## 5. Buffers & Tabs

In Vim, a **buffer** is an open file in memory. You can have many buffers open at once.

### Command Mode

| Command | Action |
|---------|--------|
| `:e filename` | Open file in a new buffer |
| `:ls` or `:buffers` | List all open buffers |
| `:bn` | Next buffer |
| `:bp` | Previous buffer |
| `:bd` | Close current buffer |
| `:b <name>` | Switch to buffer by name (Tab to autocomplete) |

### vimi Keybindings (Normal mode)

| Key | Action |
|-----|--------|
| `Space+bb` | Interactive buffer list (fzf) |
| `Space+bn` | Next buffer |
| `Space+bp` | Previous buffer |
| `Space+bd` | Close buffer |

### Vim Tabs

Tabs in Vim are viewports — each tab can contain multiple splits.

| Command | Action |
|---------|--------|
| `:tabnew` | Open new tab |
| `:tabn` / `gt` | Next tab |
| `:tabp` / `gT` | Previous tab |
| `:tabc` | Close current tab |

---

## 6. Macros

Macros record and replay sequences of keystrokes — great for repetitive edits.

### Recording

1. In Normal mode, press `q` followed by a letter (`qa` records into register `a`)
2. Perform the actions you want to record
3. Press `q` again to stop recording

### Playing Back

| Key | Action |
|-----|--------|
| `@a` | Play macro stored in register `a` |
| `@@` | Repeat last played macro |
| `10@a` | Play macro `a` 10 times |

### Tip

To apply a macro to many lines: visually select them with `V`, then type `:normal @a` — Vim will run the macro on each selected line.

---

## 7. vimi IDE Keybindings

These keybindings are added by the vimi vimrc. `Space` is the leader key.

### File Tree (NERDTree)

| Key | Action |
|-----|--------|
| `Space+n` | Toggle file tree open/close |
| `Space+N` | Reveal current file in tree |

Inside NERDTree:
- `Enter` — open file
- `o` — open / close directory
- `s` — open in vertical split
- `i` — open in horizontal split
- `?` — toggle help

### Fuzzy Search (fzf)

| Key | Action |
|-----|--------|
| `Space+p` | Fuzzy file search (all files in project) |
| `Space+/` | Search inside files using ripgrep |
| `Space+bb` | Interactive buffer list |

Inside the fzf popup:
- Type to filter
- `Ctrl+j / Ctrl+k` to move up/down
- `Enter` to open
- `Ctrl+t` — open in new tab
- `Ctrl+x` — open in horizontal split
- `Ctrl+v` — open in vertical split

### Save & Quit

| Key | Action |
|-----|--------|
| `Space+w` | Save current file (`:w`) |
| `Space+q` | Quit (`:q`) |

Command mode alternatives:
- `:wq` or `ZZ` — save and quit
- `:q!` or `ZQ` — quit without saving
- `:wqa` — save all buffers and quit

### Splits

| Key | Action |
|-----|--------|
| `Space+sv` | Open vertical split |
| `Space+sh` | Open horizontal split |
| `Space+sx` | Close current split |
| `Space+se` | Equalize all split sizes |

### Alternate Buffer

| Key | Action |
|-----|--------|
| `Space+.` | Jump to last open buffer (toggle between two files) |

This is different from `Space+bn` / `Space+bp` — it goes to the specific buffer you had open before, not the next one in the list. Ideal for toggling between implementation and test file.

### Terminal

| Key | Action |
|-----|--------|
| `Space+t` | Open integrated terminal (horizontal split) |

Inside the terminal, press `Ctrl+\` then `Ctrl+n` to return to Normal mode and navigate away.

### Quickfix List

The quickfix list collects positions across the project — populated automatically by `Space+/` (ripgrep), `Space+d` (diagnostics), `:grep`, and `:make`.

| Key | Action |
|-----|--------|
| `Space+co` | Open quickfix list |
| `Space+cc` | Close quickfix list |
| `Space+cn` | Jump to next item |
| `Space+cp` | Jump to previous item |

### Search Highlight

| Key | Action |
|-----|--------|
| `Space+h` | Clear search highlight |

---

## 8. IntelliSense

IntelliSense provides code completion, go-to-definition, inline documentation, and diagnostics. vimi ships two backends — the keybindings are identical between them.

### Shared Keybindings (both CoC and LSP stacks)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gy` | Go to type definition |
| `gr` | Show all references |
| `K` | Show documentation for symbol under cursor |
| `Space+rn` | Rename symbol across project |
| `Space+ca` | Code action (fix, refactor, import) |
| `[g` | Jump to previous diagnostic |
| `]g` | Jump to next diagnostic |
| `Space+d` | Open diagnostics list |
| `Tab` | Cycle completion popup (down) |
| `Shift+Tab` | Cycle completion popup (up) |
| `Enter` | Confirm selected completion |

### CoC-Only Commands (Vim 9.0.0438+)

These are Ex commands available only in the CoC stack:

| Command | Action |
|---------|--------|
| `:CocInfo` | Show CoC status and Node.js info |
| `:CocList extensions` | List installed extensions |
| `:CocInstall coc-go` | Install an extension manually |
| `:CocList diagnostics` | Open diagnostics panel (also `Space+d`) |
| `:CocUpdate` | Update all installed extensions |
| `:CocRestart` | Restart CoC server |

### LSP-Only Commands (Vim 8)

| Command | Action |
|---------|--------|
| `:LspStatus` | Show LSP server status |
| `:LspInstallServer` | Install language server for current filetype |
| `:ALEInfo` | Show ALE linter info for current file |
| `:ALEFix` | Run auto-fixers (e.g. prettier, gofmt) |

### Which stack am I on?

Run `:version` inside vimi. If Vim is 9.0.0438 or newer, you're on CoC. If older, you're on LSP.

Or check `:CocInfo` — if it works, you're on CoC. If it returns an error, you're on LSP.

---

## 9. Remote Editing (netrw)

vimi includes netrw — Vim's built-in remote file editor. Edit files on remote servers over SSH without a separate tool.

```sh
# Open a single remote file
vim scp://user@host//absolute/path/to/file.py

# Open a remote directory (browse with NERDTree-like UI)
vim scp://user@host//var/www/
```

Inside the netrw browser:
- `Enter` — open file
- `-` — go up one directory
- `%` — create new file
- `d` — create new directory
- `D` — delete file

**Note**: SSH key-based auth is recommended. Password auth will prompt on every file operation.

---

## 10. Zellij

[Zellij](https://zellij.dev) is a terminal multiplexer installed via vimi's optional installer. It runs isolated in `~/.rast/.zellij/` — no sudo required.

```sh
zellij          # Start a new session
zellij attach   # Attach to last session
```

### Mode System

Zellij uses a mode system similar to Vim. The default mode is **Locked** (your programs receive all keystrokes). Press `Ctrl+g` to toggle into **Normal** mode and access Zellij's own keybindings.

### Panes

| Key | Action |
|-----|--------|
| `Alt+n` | New pane |
| `Alt+Arrow` | Move focus to adjacent pane |
| `Alt+f` | Toggle pane fullscreen |
| `Alt+i` | Toggle pane frames (hide/show borders) |
| `Ctrl+w` | Close current pane |
| `Alt+[` / `Alt+]` | Resize pane |

### Tabs

| Key | Action |
|-----|--------|
| `Alt+t` | New tab |
| `Alt+1` to `Alt+9` | Switch to tab by number |
| `Alt+,` | Rename current tab |

### Sessions

| Command | Action |
|---------|--------|
| `Ctrl+q` | Quit Zellij |
| `zellij list-sessions` | List all sessions (from shell) |
| `zellij attach <name>` | Attach to a named session |
| `zellij delete-session <name>` | Delete a named session |

### Scrollback

Enter scroll mode with `Ctrl+s`, then:
- Arrow keys / `Page Up` / `Page Down` to navigate
- `Esc` or `q` to exit scroll mode

---

## Tips for Vim Beginners

**Start with hjkl**: resist the arrow keys for the first week. Force yourself to use `h/j/k/l` — after a few days it becomes muscle memory.

**Think in text objects**: Vim lets you operate on structured text:
- `ciw` — change inner word
- `ci"` — change inside quotes
- `da(` — delete around parentheses (including the parens)
- `yi{` — yank inside braces

**Use `.` constantly**: the dot command repeats your last change. Make a change once, then `.` to repeat it anywhere.

**`:help` is excellent**: type `:help <topic>` inside Vim for authoritative documentation. Example: `:help motion`, `:help registers`.
