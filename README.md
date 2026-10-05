# dotfiles

Idempotent Ubuntu bootstrap.

```bash
git clone <this-repo-url> ~/dotfiles && ~/dotfiles/install.sh        # base setup
~/dotfiles/install.sh --gpu                                          # also NVIDIA packages
```

Files in `home/` are symlinked into `$HOME` (existing files are backed up to `~/.dotfiles_backup`).
Package lists live in `packages/`.
