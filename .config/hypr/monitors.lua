-- Use the preferred mode on available displays.
-- Keep machine-specific overrides in an untracked local file.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
local config_home = os.getenv("XDG_CONFIG_HOME")
if not config_home or config_home == "" then config_home = os.getenv("HOME") .. "/.config" end
local local_config = config_home .. "/hypr/monitors.local.lua"
local file = io.open(local_config, "r")
if file then file:close(); dofile(local_config) end
