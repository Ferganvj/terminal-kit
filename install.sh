#!/bin/bash
set -euo pipefail

MARKER_START="# >>> terminal-os-kit >>>"
MARKER_END="# <<< terminal-os-kit <<<"
REPO_URL="https://raw.githubusercontent.com/Ferganvj/terminal-kit/main/install.sh"

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"

# ── Zsh guard ─────────────────────────────────────────────────────────────────
if [ -n "${ZSH_VERSION:-}" ]; then
  echo "Terminal OS Kit targets bash, but you appear to be running zsh."
  echo "To switch: chsh -s /bin/bash"
  exit 1
fi

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  echo "Uninstalling Terminal OS Kit..."
  if [ -f "$HOME/.bashrc" ]; then
    if [ "$OS" = "Darwin" ]; then
      sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$HOME/.bashrc"
    else
      sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOME/.bashrc"
    fi
    echo "  Removed kit block from ~/.bashrc"
  fi
  if [ -f "$HOME/.tmux.conf" ]; then
    rm "$HOME/.tmux.conf"
    echo "  Removed ~/.tmux.conf"
  fi
  echo ""
  echo "Done. Open a new terminal to apply changes."
  exit 0
fi

# ── Idempotency check ─────────────────────────────────────────────────────────
if grep -q "$MARKER_START" "$HOME/.bashrc" 2>/dev/null; then
  if [[ "${1:-}" != "--force" ]]; then
    echo "Terminal OS Kit is already installed."
    echo "Run with --force to reinstall: bash <(curl -sSL $REPO_URL) --force"
    exit 0
  fi
  # Remove existing block before re-installing
  if [ "$OS" = "Darwin" ]; then
    sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$HOME/.bashrc"
  else
    sed -i "/$MARKER_START/,/$MARKER_END/d" "$HOME/.bashrc"
  fi
fi

echo "Installing Terminal OS Kit..."
echo ""

# ── Backup ────────────────────────────────────────────────────────────────────
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BASHRC_BAK="$HOME/.bashrc.bak.$TIMESTAMP"

if [ -f "$HOME/.bashrc" ]; then
  cp "$HOME/.bashrc" "$BASHRC_BAK"
fi

# ── Append bashrc block ───────────────────────────────────────────────────────
cat >> "$HOME/.bashrc" << 'BASHRC_BLOCK'

# >>> terminal-os-kit >>>
# Managed by Terminal OS Kit — https://github.com/Ferganvj/terminal-kit
# To uninstall: bash <(curl -sSL https://raw.githubusercontent.com/Ferganvj/terminal-kit/main/install.sh) --uninstall

parse_git_branch() {
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$branch" ] && echo "[$branch]"
}

PS1='\[\033[32m\]\u@\h \[\033[34m\]\w \[\033[33m\]$(parse_git_branch)\[\033[0m\] $ '

alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias git-tree="git log --oneline --graph --decorate --all"
# <<< terminal-os-kit <<<
BASHRC_BLOCK

echo "  Bash config:  installed (backup saved to $BASHRC_BAK)"

# ── macOS bash_profile fix ────────────────────────────────────────────────────
if [ "$OS" = "Darwin" ] && [ -f "$HOME/.bash_profile" ]; then
  if ! grep -q "source ~/.bashrc" "$HOME/.bash_profile" 2>/dev/null && \
     ! grep -q ". ~/.bashrc" "$HOME/.bash_profile" 2>/dev/null; then
    echo "" >> "$HOME/.bash_profile"
    echo "# Source ~/.bashrc (added by Terminal OS Kit)" >> "$HOME/.bash_profile"
    echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> "$HOME/.bash_profile"
    echo "  bash_profile: updated to source ~/.bashrc"
  fi
fi

# ── tmux config ───────────────────────────────────────────────────────────────
TMUX_STATUS="skipped (tmux not found — install tmux to use this feature)"

if command -v tmux >/dev/null 2>&1; then
  if [ -f "$HOME/.tmux.conf" ]; then
    cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak.$TIMESTAMP"
  fi
  cat > "$HOME/.tmux.conf" << 'TMUX_BLOCK'
set -g mouse on

# Window navigation
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3

# Intuitive pane splitting (opens in current directory)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Status bar
set -g status-bg black
set -g status-fg green
set -g status-left '[#S] '
set -g status-right ' %H:%M %d-%b '
set -g status-interval 60

# Vi copy mode and reduced escape delay (helps vim inside tmux)
setw -g mode-keys vi
set -sg escape-time 10
TMUX_BLOCK
  TMUX_STATUS="installed"
fi

echo "  tmux config:  $TMUX_STATUS"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  Aliases added: ll, gs, ga, gc, git-tree"
echo ""
echo "Done! Open a new terminal or run:  source ~/.bashrc"
