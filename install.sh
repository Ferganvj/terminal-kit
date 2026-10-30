#!/bin/bash
set -euo pipefail

MARKER_START="# >>> terminal-os-kit >>>"
MARKER_END="# <<< terminal-os-kit <<<"
TMUX_MARKER="# Managed by Terminal OS Kit"
TMUX_BACKUP_PREFIX="# Original config backed up to: "
REPO_URL="https://raw.githubusercontent.com/Ferganvj/terminal-kit/master/install.sh"

# ── OS detection ──────────────────────────────────────────────────────────────
OS="$(uname -s)"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Timestamped backup path that never overwrites an earlier backup
backup_path() {
  local path="$1.bak.$TIMESTAMP" n=1
  while [ -e "$path" ]; do
    path="$1.bak.$TIMESTAMP.$n"
    n=$((n + 1))
  done
  echo "$path"
}

# Delete the kit block from a file. Writes back through the path instead of
# using sed -i, so a symlinked ~/.bashrc (dotfile managers) stays a symlink.
remove_block() {
  local file="$1" tmp
  tmp="$(mktemp)"
  sed "/$MARKER_START/,/$MARKER_END/d" "$file" > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--uninstall" ]]; then
  echo "Uninstalling Terminal OS Kit..."
  if grep -qF "$MARKER_START" "$HOME/.bashrc" 2>/dev/null; then
    BASHRC_BAK="$(backup_path "$HOME/.bashrc")"
    cp "$HOME/.bashrc" "$BASHRC_BAK"
    remove_block "$HOME/.bashrc"
    echo "  Removed kit block from ~/.bashrc (backup saved to $BASHRC_BAK)"
  fi
  # Only touch ~/.tmux.conf if the kit wrote it, and put back what was there before
  if grep -qF "$TMUX_MARKER" "$HOME/.tmux.conf" 2>/dev/null; then
    TMUX_ORIG="$(sed -n "s|^$TMUX_BACKUP_PREFIX||p" "$HOME/.tmux.conf")"
    if [ -n "$TMUX_ORIG" ] && [ -f "$TMUX_ORIG" ]; then
      cp "$TMUX_ORIG" "$HOME/.tmux.conf"
      echo "  Restored ~/.tmux.conf from $TMUX_ORIG"
    else
      rm "$HOME/.tmux.conf"
      echo "  Removed ~/.tmux.conf"
    fi
  elif [ -f "$HOME/.tmux.conf" ]; then
    echo "  Left ~/.tmux.conf alone (not created by Terminal OS Kit)"
  fi
  echo ""
  echo "Done. Open a new terminal to apply changes."
  exit 0
fi

# ── Login shell guard ─────────────────────────────────────────────────────────
# This script always runs under bash, so check the login shell, not the current one
LOGIN_SHELL="${SHELL:-}"
if [ -n "$LOGIN_SHELL" ] && [ "${LOGIN_SHELL##*/}" != "bash" ]; then
  echo "Terminal OS Kit targets bash, but your login shell is ${LOGIN_SHELL##*/}."
  echo "It would never read ~/.bashrc, so nothing would change."
  echo "To switch: chsh -s /bin/bash"
  exit 1
fi

# ── Idempotency check ─────────────────────────────────────────────────────────
if grep -qF "$MARKER_START" "$HOME/.bashrc" 2>/dev/null; then
  if [[ "${1:-}" != "--force" ]]; then
    echo "Terminal OS Kit is already installed."
    echo "Run with --force to reinstall: bash <(curl -sSL $REPO_URL) --force"
    exit 0
  fi
  # Remove existing block before re-installing
  remove_block "$HOME/.bashrc"
fi

echo "Installing Terminal OS Kit..."
echo ""

# ── Backup ────────────────────────────────────────────────────────────────────
BASHRC_STATUS="installed (new ~/.bashrc)"

if [ -f "$HOME/.bashrc" ]; then
  BASHRC_BAK="$(backup_path "$HOME/.bashrc")"
  cp "$HOME/.bashrc" "$BASHRC_BAK"
  BASHRC_STATUS="installed (backup saved to $BASHRC_BAK)"
fi

# ── Append bashrc block ───────────────────────────────────────────────────────
# Start the block on its own line if the file doesn't end with a newline
if [ -s "$HOME/.bashrc" ] && [ -n "$(tail -c1 "$HOME/.bashrc")" ]; then
  echo "" >> "$HOME/.bashrc"
fi

cat >> "$HOME/.bashrc" << 'BASHRC_BLOCK'
# >>> terminal-os-kit >>>
# Managed by Terminal OS Kit — https://github.com/Ferganvj/terminal-kit
# To uninstall: bash <(curl -sSL https://raw.githubusercontent.com/Ferganvj/terminal-kit/master/install.sh) --uninstall

parse_git_branch() {
  local branch
  # Branch name, falling back to the short commit hash on a detached HEAD
  branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && echo " [$branch]"
}

PS1='\[\033[32m\]\u@\h \[\033[34m\]\w\[\033[33m\]$(parse_git_branch)\[\033[0m\] $ '

alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias git-tree="git log --oneline --graph --decorate --all"
# <<< terminal-os-kit <<<
BASHRC_BLOCK

echo "  Bash config:  $BASHRC_STATUS"

# ── macOS login profile fix ───────────────────────────────────────────────────
# macOS terminals start login shells, which read the first of ~/.bash_profile or
# ~/.bash_login (else ~/.profile) and never ~/.bashrc on their own.
if [ "$OS" = "Darwin" ]; then
  PROFILE_CHECK=()
  if [ -f "$HOME/.bash_profile" ]; then
    PROFILE="$HOME/.bash_profile"
  elif [ -f "$HOME/.bash_login" ]; then
    PROFILE="$HOME/.bash_login"
  else
    PROFILE="$HOME/.bash_profile"
    : > "$PROFILE"
    # A new ~/.bash_profile hides ~/.profile from bash, so keep loading it
    if [ -f "$HOME/.profile" ]; then
      echo '[ -f ~/.profile ] && . ~/.profile' >> "$PROFILE"
      PROFILE_CHECK+=("$HOME/.profile")
    fi
  fi
  PROFILE_CHECK+=("$PROFILE")
  if ! grep -qE '(source|\.)[[:space:]]+"?(~|\$HOME)/\.bashrc' "${PROFILE_CHECK[@]}" 2>/dev/null; then
    echo "" >> "$PROFILE"
    echo "# Source ~/.bashrc (added by Terminal OS Kit)" >> "$PROFILE"
    echo '[ -f ~/.bashrc ] && source ~/.bashrc' >> "$PROFILE"
    echo "  ${PROFILE##*/}: updated to source ~/.bashrc"
  fi
fi

# ── tmux config ───────────────────────────────────────────────────────────────
TMUX_STATUS="skipped (tmux not found — install tmux to use this feature)"

if command -v tmux >/dev/null 2>&1; then
  TMUX_ORIG=""
  if grep -qF "$TMUX_MARKER" "$HOME/.tmux.conf" 2>/dev/null; then
    # Our own file from an earlier install: keep pointing at the user's original
    TMUX_ORIG="$(sed -n "s|^$TMUX_BACKUP_PREFIX||p" "$HOME/.tmux.conf")"
  elif [ -f "$HOME/.tmux.conf" ]; then
    TMUX_ORIG="$(backup_path "$HOME/.tmux.conf")"
    cp "$HOME/.tmux.conf" "$TMUX_ORIG"
  fi
  {
    echo "$TMUX_MARKER — https://github.com/Ferganvj/terminal-kit"
    if [ -n "$TMUX_ORIG" ]; then
      echo "$TMUX_BACKUP_PREFIX$TMUX_ORIG"
    fi
    echo ""
    cat << 'TMUX_BLOCK'
set -g mouse on

# Number windows and panes from 1 so Alt-1/2/3 match the first three windows
set -g base-index 1
setw -g pane-base-index 1

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
  } > "$HOME/.tmux.conf"
  TMUX_STATUS="installed"
  if [ -n "$TMUX_ORIG" ]; then
    TMUX_STATUS="installed (backup saved to $TMUX_ORIG)"
  fi
fi

echo "  tmux config:  $TMUX_STATUS"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  Aliases added: ll, gs, ga, gc, git-tree"
echo ""
echo "Done! Open a new terminal or run:  source ~/.bashrc"
