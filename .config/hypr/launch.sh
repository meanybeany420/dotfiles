#!/usr/bin/env bash

pkill hyprpaper 2>/dev/null
pkill waybar 2>/dev/null
pkill mako 2>/dev/null

sleep 0.2

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
hyprpaper -c "$config_home/hypr/hyprpaper.conf" &
waybar -c "$config_home/waybar/config.jsonc" -s "$config_home/waybar/style.css" &
mako -c "$config_home/mako/config" &
hypridle -c "$config_home/hypr/hypridle.conf" &
