#!/usr/bin/env fish
# zellij — Isolated Zellij installer (fish wrapper)
# Usage: fish zellij/install.fish
#        or: bash (curl -fsSL https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh | psub)
#
# fish cannot source bash scripts directly.
# This wrapper delegates to install.sh via bash.

set script_url "https://raw.githubusercontent.com/raulast/vimi/master/zellij/install.sh"

if not command -q bash
    echo "[zellij] ✗ bash not found — required to run the installer"
    echo "[zellij]   Install bash and retry."
    exit 1
end

bash (curl -fsSL $script_url | psub)
