# Linux development environment

Personal configurations for Hyprland, Neovim (LazyVim), tmux, Waybar, Ghostty, Rofi and related Linux tools.

Includes Lua screenshot automation and Bash display switching. Review files before installing; this is a configuration collection, not an automatic installer. Back up existing settings and copy only the files you need.

## Local configuration

- Screenshots require Lua, grim, slurp, wl-copy and notify-send.
- Display switching requires Bash, hyprctl and jq. Define `LAPTOP_OUTPUT` and `EXTERNAL_OUTPUT` in `~/.config/hypr/displays.local.sh` using your own connector names. Run `hypr-monitor-auto` when switching setups.
- Optional monitor rules belong in `~/.config/hypr/monitors.local.lua`.
- Supply your own wallpaper at `~/.local/share/backgrounds/wallpaper.png`, or change the wallpaper configuration.
- Startup commands assume the configurations have been copied into your home directory.
- Local display overrides, credentials and generated files must remain untracked.

This public snapshot omits previous machine-specific configuration history. Plugin authors retain ownership of their respective projects; the bundled Neovim starter license is retained.
