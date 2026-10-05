#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEBIAN_FRONTEND=noninteractive

WITH_GPU=0
for arg in "$@"; do
  case "$arg" in
    --gpu) WITH_GPU=1 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }

. /etc/os-release
[[ "$ID" == "ubuntu" ]] || { echo "Ubuntu only (found $ID)"; exit 1; }

install_packages() {
  local list="$1"
  mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")
  sudo apt-get install -y --no-install-recommends "${pkgs[@]}"
}

link_dotfiles() {
  local src dest
  shopt -s nullglob
  for src in "$DOTFILES"/home/.[!.]*; do
    dest="$HOME/$(basename "$src")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      mkdir -p "$HOME/.dotfiles_backup"
      mv "$dest" "$HOME/.dotfiles_backup/"
    fi
    ln -sfn "$src" "$dest"
    echo "linked $dest"
  done
}

log "Updating apt"
sudo apt-get update -y

log "Installing base packages"
install_packages "$DOTFILES/packages/base.txt"

if [[ $WITH_GPU -eq 1 ]]; then
  log "Installing NVIDIA packages"
  install_packages "$DOTFILES/packages/gpu.txt"
fi

log "Setting up Python tooling"
# Ubuntu 23.04+ blocks system-wide pip (PEP 668), so use pipx or venvs
sudo apt-get install -y pipx
pipx ensurepath

log "Keybase"
if ! command -v keybase >/dev/null; then
  curl -fsSL -o /tmp/keybase.deb https://prerelease.keybase.io/keybase_amd64.deb
  sudo apt-get install -y /tmp/keybase.deb
  rm -f /tmp/keybase.deb
fi

log "Firewall"
sudo ufw allow OpenSSH
sudo ufw --force enable

log "Linking dotfiles"
link_dotfiles

log "Versions"
go version
python3 --version
