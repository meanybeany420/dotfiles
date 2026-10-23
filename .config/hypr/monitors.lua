-- Use the preferred mode on available displays.
-- Keep machine-specific overrides in an untracked local file.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
local local_config = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr/monitors.local.lua"
local file = io.open(local_config, "r")
if file then file:close(); dofile(local_config) end
