# Linux development environment

Personal Arch Linux configurations for Hyprland, Neovim, Ghostty, tmux, Zsh, Waybar and Rofi.

This is a curated configuration snapshot, not a complete home-directory backup or an automatic installer. Machine-specific settings, credentials, histories and generated state stay local.

## What's included

| Component | Configuration |
| --- | --- |
| Desktop | Hyprland Lua configuration, Hypridle, Hyprlock and Hyprpaper |
| Editor | LazyVim setup, custom colours, Oil navigation and C++ build/run commands |
| Shell | Zsh, Powerlevel10k, fzf, zoxide and command aliases |
| Terminals | Ghostty, Alacritty and tmux session persistence |
| Panels | Waybar focus-timer integration and Mako notification rules |
| Launcher | Rofi launcher and a compact audio-input theme |
| Utilities | Lua screenshots and a Bash display-switching helper |

## Use selected configs

```sh
git clone https://github.com/meanybeany420/dotfiles.git
cd dotfiles
```

1. Read the configuration and [dependencies](docs/dependencies.md) for the components you want.
2. Back up the corresponding files in your home directory. Close editors that may save an older copy over your changes.
3. Copy only the selected files into their matching paths under `$HOME`. Keep executable permissions on `.local/bin/` and shell scripts.
4. Review startup applications, keyboard layout, keybindings, fonts and monitor settings before starting a new session.

The desktop targets Hyprland 0.57's Lua configuration API; it is not a configuration for older releases that only accept `hyprland.conf`. Neovim regression checks use version 0.12.6. Other distributions and older versions are not tested.

## Local settings

- The default monitor configuration keeps automatic output selection. Put your own monitor rules in `~/.config/hypr/monitors.local.lua`; that file is ignored by Git. An optional [staged monitor policy](docs/monitors.md) provides verified transitions, mirroring and unplug recovery after you configure it for your hardware.
- The standalone `hypr-monitor-auto` helper reads `LAPTOP_OUTPUT` and `EXTERNAL_OUTPUT` from `~/.config/hypr/displays.local.sh`. Choose one display-management approach rather than running conflicting rules.
- Supply your own wallpaper at `~/.local/share/backgrounds/wallpaper.png`, or edit the wallpaper configuration. Personal wallpaper images are not bundled.
- The focus timer and clipboard commands come from [system-tools](https://github.com/meanybeany420/system-tools). Install that separately before enabling the related startup commands and keybindings. This repository does not duplicate those scripts.
- Fonts and cursor themes are external dependencies. Install them or change the font/theme names in the configs.
- Hermes shell aliases are optional shortcuts; no Hermes profiles, credentials or conversation data are included.

## Neovim C++ commands

- `:Cbuild` compiles the `.cpp` files beside the current file with `g++` and C++20.
- `:Crun` runs the last successful build in a Ghostty runner window.
- `:Cgo` builds and runs.

These commands are for small, flat C++ projects, not a replacement for CMake. Building saves modified buffers through `:wall`. A failed build preserves the last successful executable. Builds are temporary and scoped to the current Neovim session; the FIFO runner does not support newline-containing paths. Arrow keys are deliberately disabled in normal, insert and visual modes; navigation uses Vim keys.

## Check changes

Requires Python 3.11+, Git, Bash, Zsh and Lua (`luac`). The isolated Neovim regression tests also require Neovim and `g++`.

```sh
python3 scripts/check_configs.py
python3 -m unittest discover -s tests -v
git diff --check
```

The checker parses Lua, shell, JSON/JSONC and TOML files and flags common credential patterns and literal user-home paths. It does not start Hyprland, apply monitor changes or load your normal Neovim plugins. Pattern scanning is a guardrail, not a guarantee that a file is safe to publish.

Tests use isolated homes, a stub compositor interface and a fake Ghostty where needed. They do not prove that every desktop feature works on other hardware. GitHub Actions runs the checks before changes are merged or after a push.

## Updating this snapshot

Compare the tracked files with your live configuration, review each difference, then copy only the intended changes. Preserve portable paths and local overrides instead of copying an entire `.config` directory. Never include editor recovery files, browser profiles, clipboard history or private keys.

The public history intentionally starts with a portable snapshot. Do not merge an older, unsanitised checkout back into the public branch.

The bundled Neovim starter license is retained. Third-party projects keep their respective licenses; no repository-wide license has been added.
