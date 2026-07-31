#!/bin/sh
#
# install.sh — bootstrap a fresh Ubuntu/Debian (apt) system with the standard
# toolchain and deploy this dotfiles repo via stow.
#
# Self-bootstrapping: run from anywhere; the script clones itself into
# ~/.dotfiles if needed and re-executes from there, then pulls the latest.
#
# Run as a normal user; sudo is used for apt operations.
# Safe to re-run (idempotent). Ordering constraints:
#   * oh-my-zsh must install before dotfiles are stowed (stowed .zshrc replaces
#     the oh-my-zsh template).
#   * platformio must install before dotfiles are stowed (stowed pio symlinks
#     point into ~/.platformio/penv/bin).
#   * dotfiles' zsh/.zshrc owns pyenv init, so pyenv installs into ~/.pyenv and
#     no rc file is edited for it.

set -e

DOTFILES_REPO="https://github.com/urdaibayc/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
OMZ_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
NC='\033[0m'

step() { printf "${BLUE}==> %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}    %s${NC}\n" "$*"; }

require_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi
    if ! sudo -v; then
        printf '%s\n' "sudo is required for apt operations." >&2
        exit 1
    fi
}

# Self-bootstrap: make sure we run from a checkout in ~/.dotfiles, up to date.
if [ ! -d "$DOTFILES_DIR/.git" ]; then
    step "Cloning dotfiles into $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    exec "$DOTFILES_DIR/install.sh"
fi
cd "$DOTFILES_DIR"
git pull --ff-only || ok "dotfiles already up to date"

step "Updating apt and installing system packages"
require_sudo
sudo apt-get update -y
sudo NEEDRESTART_MODE=a apt-get upgrade -y
sudo apt-get install -y \
    git zsh ripgrep stow kitty ddgr asciinema nvim podman docker.io \
    build-essential python3 python3-venv python3-pip curl ca-certificates direnv \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    libffi-dev liblzma-dev
ok "System packages installed"

step "Installing GitHub CLI"
KEYRING=/etc/apt/keyrings/githubcli-archive-keyring.gpg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee "$KEYRING" >/dev/null
sudo chmod go+r "$KEYRING"
printf 'deb [arch=%s signed-by=%s] https://cli.github.com/packages stable main\n' \
    "$(dpkg --print-architecture)" "$KEYRING" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt-get update -y
sudo apt-get install -y gh
ok "GitHub CLI installed"

step "Installing oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "oh-my-zsh already installed"
else
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

step "Installing zsh-syntax-highlighting plugin"
if [ -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    ok "zsh-syntax-highlighting already installed"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting installed"
fi

step "Installing pyenv + pyenv-virtualenv"
if [ -d "$HOME/.pyenv" ]; then
    ok "pyenv already installed"
else
    curl -fsSL https://pyenv.run | bash
fi

step "Installing PlatformIO Core"
if [ -x "$HOME/.platformio/penv/bin/pio" ]; then
    ok "PlatformIO already installed"
else
    curl -fsSL https://raw.githubusercontent.com/platformio/platformio/master/scripts/get-platformio.py \
        -o /tmp/get-platformio.py
    python3 /tmp/get-platformio.py
    rm -f /tmp/get-platformio.py
fi

step "Stowing dotfiles packages"
# Remove configs that the stowed packages manage so stow can create symlinks:
# the stowed zsh/.zshrc replaces the oh-my-zsh template, and bash/.bashrc and
# bash/.profile replace the system defaults.
rm -f "$HOME/.bashrc" "$HOME/.profile" "$HOME/.zshrc" "$HOME/.zprofile" "$HOME/.aliases"
stow --restow bash kitty nvim opencode pio zsh
ok "Dotfiles deployed"

step "Adding user to docker group"
if groups | grep -qw docker; then
    ok "already a docker group member"
else
    sudo usermod -aG docker "$USER"
    ok "added to docker group (takes effect after logout)"
fi

ZSH_PATH="$(command -v zsh)"
step "All done"
printf '\n'
cat <<EOF
Setup complete. Next steps:
  1. Log out and back in (zsh + new group memberships take effect).
  2. Make zsh your default shell:  chsh -s $ZSH_PATH
  3. Authenticate with GitHub:     gh auth login
  4. Install a Python version:     pyenv install 3.12 && pyenv global 3.12
EOF
