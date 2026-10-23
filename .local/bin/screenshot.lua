#!/usr/bin/env lua

local home = os.getenv("HOME")
local dir = home .. "/Pictures/Screenshots"
local mode = arg[1] or "area"

local timestamp = os.date("%Y-%m-%d_%H-%M-%S")
local file = dir .. "/" .. timestamp .. ".png"

local function run(cmd)
	local ok = os.execute(cmd)
	if ok ~= true and ok ~= 0 then
		os.exit(1)
	end
end

local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function output(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return nil
	end

	local result = handle:read("*a")
	handle:close()

	return trim(result)
end

run("mkdir -p " .. string.format("%q", dir))

if mode == "area" then
	local geometry = output("slurp")
	if not geometry or geometry == "" then
		os.exit(1)
	end

	run("grim -g " .. string.format("%q", geometry) .. " " .. string.format("%q", file))
	run("wl-copy < " .. string.format("%q", file))
	run("notify-send " .. string.format("%q", "Screenshot saved") .. " " .. string.format("%q", file))
elseif mode == "full" then
	run("grim " .. string.format("%q", file))
	run("wl-copy < " .. string.format("%q", file))
	run("notify-send " .. string.format("%q", "Screenshot saved") .. " " .. string.format("%q", file))
else
	print("Usage: screenshot.lua {area|full}")
	os.exit(1)
end
