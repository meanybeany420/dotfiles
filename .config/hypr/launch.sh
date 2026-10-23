#!/usr/bin/env bash

pkill hyprpaper 2>/dev/null
pkill waybar 2>/dev/null
pkill mako 2>/dev/null

sleep 0.2

hyprpaper -c "$HOME/.config/hypr/hyprpaper.conf" &
waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &
mako -c "$HOME/.config/mako/config" &
hypridle -c "$HOME/.config/hypr/hypridle.conf" &
