# Optional monitor policy

The default `monitors.lua` enables the preferred mode on available outputs. It does not assume a particular laptop panel, dock or scaling factor.

`monitor_policy.lua` is an optional two-output policy adapted from the workstation's staged display switching. It prepares independent displays before attempting mirroring or disabling a panel, then checks that the requested layout settled. This is an alternative to `hypr-monitor-auto`, not an additional manager to run alongside it.

## Enable locally

1. Read `.config/hypr/monitors.local.lua.example` and make an edited copy.
2. Replace both connector placeholders with names reported by `hyprctl monitors all`.
3. Set positive finite scale values suitable for your displays.
4. Replace `status_paths` with the actual external connector status files under `/sys/class/drm/`. Supply explicit absolute filenames, not a wildcard. More than one path is allowed if that connector appears under multiple cards.
5. Place the edited file at `${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitors.local.lua` only after reviewing it. The file remains untracked.

The primary connector setting is called `laptop`; it is the recovery output. This policy targets one primary display and one external display, not arbitrary multi-monitor or rotated-output layouts. It sets transform zero.

## Choose a layout

The mode file defaults to `${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitor-mode`. An absolute `mode_path` in the local settings can override it. Missing or invalid mode text selects `auto`.

| Mode | Requested behavior |
| --- | --- |
| `auto` | Primary plus connected external, external to the right |
| `laptop` | Primary only |
| `external` | External only, after verifying independent external activation |
| `right` | Both, external to the right |
| `left` | Both, external to the left |
| `mirror` | Mirror the primary onto the external |

After configuring and enabling the local policy, for example:

```sh
printf '%s\n' right > "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/monitor-mode"
```

`auto` intentionally keeps both displays; it does not copy the workstation's private dock preference of automatically disabling the panel. Only explicit `external` mode requests that the primary be disabled.

## Recovery and limits

- Unplug detection requests the primary display and clears the external layout.
- Failed preparation or settling requests both displays independently rather than disabling a potentially working screen.
- Failure stops destructive retries until the connection/mode changes or the returned policy's `apply(true)` is called.
- Layout checks account for logical widths and mirrored outputs returned inside another monitor's `mirrors` list.
- Polling reads only the supplied small status files; it does not spawn a shell on every timer tick.

The module is checked against Hyprland 0.57's Lua API and tested with a stub compositor. No automatic test changes real display hardware, so keep a recovery route when first enabling it on your own machine.
