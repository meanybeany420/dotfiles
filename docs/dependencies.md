# Dependencies and local setup

Install only the components you plan to use. These are Arch package names; this repository does not run a package manager or enable services for you.

| Component | Packages / requirements |
| --- | --- |
| Hyprland session | `hyprland`, `hypridle`, `hyprlock`, `hyprpaper` |
| Bar and notifications | `waybar`, `mako`, `libnotify` |
| Launcher | `rofi`; the supplied compact theme references Montserrat |
| Applications | `ghostty`, `firefox`, `chromium`, `dolphin`; the startup configuration opens Ghostty and Chromium |
| Optional terminal | `alacritty` |
| Audio and media controls | `wireplumber` (`wpctl`), a working PipeWire audio session, `pavucontrol`, `playerctl` |
| Laptop brightness | `brightnessctl` and supported backlight hardware |
| Screenshots | `lua`, `grim`, `slurp`, `wl-clipboard`, `libnotify` |
| Legacy display helper | `bash`, `jq`, `hyprctl` from Hyprland |
| Zsh tools | `zsh`, `bat`, `eza`, `fd`, `fzf`, `zoxide`, `zsh-syntax-highlighting` |
| Editor | `neovim`, `git`; language servers and formatters are configured separately through LazyVim/Mason |
| C++ commands | `gcc` (`g++`) and Ghostty |
| Multiplexer | `tmux` plus TPM and the configured plugins |
| Validation | Python 3.11+, Git, Bash, Zsh and Lua (`luac`); Neovim and `g++` for editor tests |

## Fonts and cursor

Nerd Font glyphs are used by the bar and prompt. Install suitable fonts or change the font settings to ones you have. The Rofi audio theme references Montserrat; the Hyprland configuration references the GoogleDot-Black cursor theme. Neither fonts nor cursor assets are bundled.

## Powerlevel10k

The Zsh configuration loads Powerlevel10k from `~/.powerlevel10k/powerlevel10k.zsh-theme` when it exists. Install the upstream theme there if you want that prompt. Missing optional shell tools no longer prevent loading the rest of the configuration.

## tmux plugins

The configuration expects TPM at `~/.tmux/plugins/tpm/tpm` and declares `tmux-resurrect` and `tmux-continuum`. Install TPM from the upstream `tmux-plugins/tpm` project, then use its plugin installation command. The configured prefix is `Ctrl+h`; TPM's install binding is prefix followed by uppercase `I`.

Session restoration is enabled through tmux-continuum. This repository does not contain tmux session snapshots or shell history.

## Desktop utilities

Install [system-tools](https://github.com/meanybeany420/system-tools) separately for `focus-mode`, `clipboard-watch` and `clipboard-stack`. Those programs are not bundled here. Its installer, dependencies and hardware limitations are documented in that repository.

The bar invokes the focus timer using `$HOME`, so another username or a home path containing spaces does not require editing the commands. Mako's `focus-timer` mode hides notifications while the timer is active.

## Compatibility

The reference workstation has Hyprland 0.57.0, Neovim 0.12.6, Ghostty 1.4.0, Zsh 5.9.2, tmux 3.8, Rofi 2.0.0 and Waybar 0.15.0 installed. This records package versions, not a claim that every component received a full runtime test or that earlier versions and other distributions are compatible.

CI uses a checksum-verified Neovim 0.12.6 release and checks configuration syntax and isolated behavior. It does not start a desktop session, change physical displays, or test laptop-specific hardware.
