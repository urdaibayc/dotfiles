# AGENTS.md

Dotfiles repo (`urdaibayc/dotfiles`) containing GNU stow packages (`bash`, `kitty`, `nvim`, `opencode`, `pio`, `zsh`) and a self-bootstrapping system installer (`install.sh`) for fresh Ubuntu/Debian (apt) systems.

## Usage

- Fresh system: `git clone https://github.com/urdaibayc/dotfiles ~/.dotfiles && ~/.dotfiles/install.sh`
- The script self-bootstraps: if `~/.dotfiles` isn't a checkout it clones the repo there and re-executes, then `git pull --ff-only` to self-update before installing.
- Run as a normal user; `sudo` is used for apt operations. Idempotent — safe to re-run.
- Strict POSIX `sh` (`set -e`). Must stay dash-compatible — no bashisms (in particular: **no `trap ... ERR`** — dash rejects it). Verify edits with `sh -n install.sh` and `dash -n install.sh`.

## Ordering constraints (install.sh enforces these — don't break them)

- The apt toolchain installs **before** the full system upgrade; the upgrade is a **best-effort** step (`|| warn`), so a failed upgrade can never block the install.
- oh-my-zsh installs **before** dotfiles are stowed; the stowed `zsh/.zshrc` replaces the oh-my-zsh template (the script `rm -f`s `~/.zshrc` first).
- PlatformIO installs **before** stow: the stowed `pio` package symlinks `~/.local/bin/{pio,piodebuggdb,platformio}` → `~/.platformio/penv/bin/...`, so `~/.platformio/penv` must exist first.
- dotfiles `zsh/.zshrc` owns pyenv init (`~/.pyenv`, pyenv + virtualenv plugin installed via `pyenv.run`). The script never edits rc files for pyenv.
- Stow uses an **explicit package list** (`bash kitty nvim opencode pio zsh`), never `stow .` or `stow *` — a top-level `install.sh` must not be picked up as a package.

## Gotchas

- `zsh-syntax-highlighting` is NOT bundled with oh-my-zsh; install.sh clones it into `$ZSH_CUSTOM/plugins/` (`$HOME/.oh-my-zsh/custom/plugins`).
- dotfiles `.zshrc` hard-requires `direnv` (`eval "$(direnv hook zsh)"`) and sets `PYTHONBREAKPOINT=ipdb.set_trace`; `direnv` is in the apt install list.
- Docker comes from the `docker.io` apt package; the user is added to the `docker` group (needs logout).
- `gh` CLI is installed from the official `cli/cli` apt repo (keyring at `/etc/apt/keyrings/githubcli-archive-keyring.gpg`).
- Stow will fail loudly if a real config dir (e.g. `~/.config/kitty`) exists where a package expects a symlink — by design, don't clobber.
