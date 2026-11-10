# Dotfiles

Configs from my Arch / Hyprland setup.

Hyprland, Neovim, Ghostty, Alacritty, tmux, Zsh, Waybar, mako and rofi. Mostly here so I can keep track of them and reuse bits on another machine.

## Using them

```sh
git clone https://github.com/meanybeany420/dotfiles.git
cd dotfiles
```

Take the bits you want, read them first and back up whatever you're replacing. There isn't an installer, and copying the whole lot over your home directory is a bad idea.

The paths mirror `$HOME`. Keep executable permissions on scripts, and check keybindings, startup apps, fonts and monitor settings before starting a session. See [dependencies](docs/dependencies.md) for packages and setup.

## Things you'll probably want to change

- The desktop uses Hyprland 0.57's Lua config, not the older `hyprland.conf` format.
- Put monitor overrides in `~/.config/hypr/monitors.local.lua`. There's more on the optional monitor policy in [monitor setup](docs/monitors.md). The separate `hypr-monitor-auto` helper uses `~/.config/hypr/displays.local.sh`; pick one approach rather than running both.
- Add your own wallpaper at `~/.local/share/backgrounds/wallpaper.png`, or change the path.
- Install the fonts and cursor theme, or swap the names for ones you have.
- The focus timer and clipboard commands come from [system-tools](https://github.com/meanybeany420/system-tools), not this repo. Install those before enabling their bindings or startup commands.

## Neovim bits

`:Cbuild` builds the `.cpp` files beside the current file with g++ and C++20. `:Crun` opens the last successful build in Ghostty, and `:Cgo` does both.

These are for small, flat projects. Building saves modified buffers with `:wall`; a failed build keeps the previous executable. Builds last for the Neovim session, and the runner doesn't handle paths containing newlines.

Arrow keys are disabled in normal, insert and visual modes. Change that if it's not your thing.

## Checks

Needs Python 3.11+, Git, Bash, Zsh and Lua (`luac`). Editor tests also need Neovim and g++; the regression setup uses Neovim 0.12.6.

```sh
python3 scripts/check_configs.py
python3 -m unittest discover -s tests -v
git diff --check
```

These check syntax and isolated behaviour, not your actual desktop or hardware. Review changes before copying them back, and keep private keys, history, clipboard data and other personal state out of Git. Don't merge an older unsanitised checkout into the public history.

Before committing, check what's changed and what's staged:

```sh
git status --short
git diff
git diff --cached
```

The bundled Neovim starter licence is kept in place. Other third-party projects keep their own licences; there's no repo-wide licence.
