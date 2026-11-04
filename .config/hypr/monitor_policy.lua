-- Optional staged policy, enabled only by monitors.local.lua (see example).
-- API checked against installed Hyprland 0.57.0 /usr/share/hypr/stubs.
local M = {}

function M.setup(opts)
	assert(type(opts) == "table", "monitor policy expects a settings table")
	local function text(value)
		return type(value) == "string" and value ~= "" and not value:find("[%c,]")
	end
	assert(text(opts.laptop) and text(opts.external) and opts.laptop ~= opts.external,
		"set distinct laptop and external connector names")
	local laptop, external = opts.laptop, opts.external
	local laptop_scale = opts.laptop_scale == nil and 1 or opts.laptop_scale
	local external_scale = opts.external_scale == nil and 1 or opts.external_scale
	for _, scale in ipairs({ laptop_scale, external_scale }) do
		assert(type(scale) == "number" and scale > 0 and scale < math.huge, "scales must be finite and positive")
	end
	assert(type(opts.status_paths) == "table" and #opts.status_paths > 0,
		"set status_paths to the external connector's sysfs status files")
	local paths = {}
	for _, path in ipairs(opts.status_paths) do
		assert(text(path) and path:sub(1, 1) == "/", "status paths must be absolute")
		paths[#paths + 1] = path
	end
	assert(opts.mode_path == nil or (text(opts.mode_path) and opts.mode_path:sub(1, 1) == "/"),
		"mode_path must be absolute")
	local config_home = os.getenv("XDG_CONFIG_HOME")
	if not config_home or config_home == "" then config_home = os.getenv("HOME") .. "/.config" end
	local mode_path = opts.mode_path or (config_home .. "/hypr/monitor-mode")
	local valid = { auto = true, laptop = true, external = true, right = true, left = true, mirror = true }
	local state = { phase = "idle" }

	local function connected()
		for _, path in ipairs(paths) do
			local file = io.open(path, "r")
			if file then
				local status = file:read("*l")
				file:close()
				if status == "connected" then return true end
			end
		end
		return false
	end
	local function selection()
		local file = io.open(mode_path, "r")
		local mode = file and file:read("*l") or "auto"
		if file then file:close() end
		return valid[mode] and mode or "auto"
	end
	local function active()
		local result = {}
		for _, mon in ipairs(hl.get_monitors()) do
			if mon.enabled ~= false and mon.width > 0 and mon.height > 0 then result[mon.name] = mon end
			-- Mirrored outputs may be nested instead of returned at the top level.
			for _, mirror in ipairs(mon.mirrors or {}) do
				if mirror.enabled ~= false and mirror.width > 0 and mirror.height > 0 then result[mirror.name] = mirror end
			end
		end
		return result
	end
	local function rule(output, scale, position, disabled, mirror)
		hl.monitor({ output = output, mode = "preferred", scale = scale, position = position,
			disabled = disabled, mirror = mirror or "", transform = 0 })
	end
	local function independent()
		rule(laptop, laptop_scale, "0x0", false)
		rule(external, external_scale, "auto", false)
	end
	local function begin(force)
		local mode, plugged = selection(), connected()
		local key = mode .. ":" .. tostring(plugged)
		if not force and state.key == key then return false end
		state = { key = key, mode = mode, connected = plugged, phase = "preparing", attempts = 0 }
		-- hl.monitor schedules a modeset: never disable or mirror in this phase.
		independent()
		return true
	end
	local function width(mon) return math.floor(mon.width / mon.scale + 0.5) end
	local function finalize(monitors)
		local a, b = monitors[laptop], monitors[external]
		local mode = state.mode
		if not state.connected or mode == "laptop" then
			rule(laptop, laptop_scale, "0x0", false)
			rule(external, external_scale, width(a) .. "x0", true)
		elseif mode == "external" then
			rule(external, external_scale, "0x0", false)
			rule(laptop, laptop_scale, "0x0", true)
		elseif mode == "mirror" then
			rule(laptop, laptop_scale, "0x0", false)
			rule(external, external_scale, "0x0", false, laptop)
		elseif mode == "left" then
			rule(laptop, laptop_scale, width(b) .. "x0", false)
			rule(external, external_scale, "0x0", false)
		else -- auto deliberately keeps both displays, unlike the private dock default.
			rule(laptop, laptop_scale, "0x0", false)
			rule(external, external_scale, width(a) .. "x0", false)
		end
		state.phase, state.attempts = "settling", 0
	end
	local function matches(monitors)
		local a, b = monitors[laptop], monitors[external]
		local mode = state.mode
		if not state.connected or mode == "laptop" then return a and not a.is_mirror and not b end
		if mode == "external" then return b and not b.is_mirror and not a end
		if not a or not b or a.is_mirror then return false end
		if mode == "mirror" then return b.is_mirror end
		if b.is_mirror or a.y ~= b.y then return false end
		if mode == "left" then return b.x + width(b) == a.x end
		return a.x + width(a) == b.x
	end
	local function tick()
		-- Give scheduled preparation at least one timer interval to render.
		if begin(false) then return end
		if state.phase == "ready" then
			if not matches(active()) then begin(true) end
			return
		end
		if state.phase ~= "preparing" and state.phase ~= "settling" then return end
		local monitors = active()
		if state.phase == "preparing" then
			local a, b = monitors[laptop], monitors[external]
			if a and not a.is_mirror and (not state.connected or (b and not b.is_mirror)) then
				finalize(monitors)
				return
			end
		elseif matches(monitors) then
			state.phase = "ready"
			return
		end
		state.attempts = state.attempts + 1
		if state.attempts >= 24 then
			state.phase, state.error = "failed", "layout did not settle; independent screens requested"
			-- Do not disable a potentially working external if panel recovery fails.
			independent()
		end
	end
	begin(true)
	for _, event in ipairs({ "hyprland.start", "monitor.added", "monitor.removed" }) do
		hl.on(event, function() begin(false) end)
	end
	-- Poll explicit small sysfs files: reconnects of disabled outputs need not emit events.
	local timer = hl.timer(tick, { timeout = 250, type = "repeat" })
	return {
		apply = function(force) begin(force == true) end,
		status = function() return state.phase .. ":" .. state.mode .. (state.error and ":" .. state.error or "") end,
		timer = timer,
	}
end

return M
