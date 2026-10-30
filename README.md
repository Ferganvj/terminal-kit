# Terminal OS Kit

Turn any developer terminal into a pro workspace in under 60 seconds.
No bloat, no plugins, no frameworks — just a shell that feels good.

---

## Install

```bash
curl -sSL https://raw.githubusercontent.com/Ferganvj/terminal-kit/master/install.sh | bash
```

That's it. Open a new terminal and you're done.

**Requirements:** bash as your login shell (Linux or macOS) — tmux optional but recommended.
macOS defaults to zsh; switch with `chsh -s /bin/bash` first, or the installer will stop.

---

## What You Get

**Before:**
```
user@hostname:~/projects/myapp$
```

**After:**
```
user@hostname ~/projects/myapp [main] $
```
Green user · Blue path · Yellow branch — disappears cleanly outside git repos.

- Git-aware prompt — branch name always visible, gone outside git repos
- Color-coded prompt — readable at a glance without squinting
- Useful aliases pre-loaded (`ll`, `gs`, `ga`, `gc`, `git-tree`)
- tmux improvements — mouse support, intuitive pane splits, status bar with clock
- Safe install — backs up your existing `.bashrc` and `.tmux.conf` before touching anything

---

## Aliases Added

| Alias      | Expands to                                           |
|------------|------------------------------------------------------|
| `ll`       | `ls -lah`                                            |
| `gs`       | `git status`                                         |
| `ga`       | `git add`                                            |
| `gc`       | `git commit -m`                                      |
| `git-tree` | `git log --oneline --graph --decorate --all`         |

`gs` and `gc` shadow Ghostscript and Graphviz's `gc` in interactive shells. Type `\gs` or `command gs` to reach the original; scripts are unaffected.

---

## tmux Quick Reference

| Action                | Keys                      |
|-----------------------|---------------------------|
| New pane (vertical)   | `Ctrl-b` then `\|`        |
| New pane (horizontal) | `Ctrl-b` then `-`         |
| Switch window 1/2/3   | `Alt-1`, `Alt-2`, `Alt-3` |
| Enter scroll/copy mode| `Ctrl-b` then `[`         |
| Close pane            | `exit` or `Ctrl-d`        |

---

## Uninstall

```bash
curl -sSL https://raw.githubusercontent.com/Ferganvj/terminal-kit/master/install.sh | bash -s -- --uninstall
```

Removes only the Terminal OS Kit block from your `.bashrc` (a timestamped backup is saved first). If the kit installed `~/.tmux.conf`, it is removed and the config you had before install is restored; a `~/.tmux.conf` the kit didn't write is left alone.

---

## License

MIT. Fork it, use it, sell it. Stars appreciated.
