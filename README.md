# dotfiles

Personal dotfiles managed with GNU stow, plus a self-bootstrapping installer (`install.sh`) that provisions a fresh Ubuntu/Debian (apt) system.

## Quick start

On a fresh Ubuntu/Debian machine, as a normal user:

```sh
git clone https://github.com/urdaibayc/dotfiles ~/.dotfiles && ~/.dotfiles/install.sh
```

The script clones itself into `~/.dotfiles` if needed (it self-bootstraps, pulls latest, and re-executes), then:

1. Installs the apt toolchain: git, zsh, ripgrep, stow, kitty, ddgr, asciinema, podman, docker.io, build tools, python3, pyenv build deps, direnv
2. Runs a best-effort system upgrade (never blocks the install)
3. Generates the `en_US.UTF-8` locale (dotfiles force it)
4. Installs Neovim `v0.12.4` (official tarball to `~/.local`) — apt's 0.9.x is too old for the nvim config
5. Installs the GitHub CLI (`gh`) from the official repo
6. Installs oh-my-zsh + the `zsh-syntax-highlighting` plugin
7. Installs pyenv + pyenv-virtualenv
8. Installs PlatformIO Core
9. Stows the dotfiles packages
10. Adds you to the `docker` group and enables container services at boot (docker + rootless podman)

Idempotent — safe to re-run.

## After setup

```sh
# Log out and back in first
chsh -s /usr/bin/zsh        # make zsh the default shell
gh auth login               # authenticate with GitHub
pyenv install 3.12 && pyenv global 3.12
```

## Stow packages

`bash`, `kitty`, `nvim`, `opencode`, `pio`, `zsh` (installed explicitly, never `stow .`).
