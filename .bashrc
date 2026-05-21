# Terminal OS Kit — reference config
# This file is embedded in install.sh. Edit install.sh to change what gets installed.

parse_git_branch() {
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ -n "$branch" ] && echo "[$branch]"
}

PS1='\[\033[32m\]\u@\h \[\033[34m\]\w \[\033[33m\]$(parse_git_branch)\[\033[0m\] $ '

# Aliases
alias ll='ls -lah'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias git-tree="git log --oneline --graph --decorate --all"
