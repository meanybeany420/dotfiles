"""Offline Lua monitor-policy tests: no compositor or hyprctl is invoked."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
HYPR = ROOT / '.config/hypr'


class MonitorTests(unittest.TestCase):
    def lua(self, body):
        prelude = f"package.path = {str(HYPR / '?.lua')!r} .. ';' .. package.path\n"
        result = subprocess.run(['lua', '-'], input=prelude + body, text=True,
                                capture_output=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_live_configuration_features_without_exec(self):
        self.lua('''
local configs,binds,commands,callbacks={},{},{},{}
local dispatch
 dispatch=setmetatable({}, {__index=function() return dispatch end,
 __call=function(_,arg) return arg or {} end})
hl={dsp=dispatch, monitor=function() end, on=function(event,fn) callbacks[#callbacks+1]=fn end,
 exec_cmd=function(command) commands[#commands+1]=command end,
 config=function(c) configs[#configs+1]=c end,
 bind=function(key,command) binds[key]=command; return {} end,
 env=function() end, curve=function() end, animation=function() end,
 gesture=function() end, device=function() end, window_rule=function() return {} end}
-- Do not read the user's optional local monitor override during this test.
package.loaded.monitors=true
dofile(''' + repr(str(HYPR / 'hyprland.lua')) + ''')
for _,fn in ipairs(callbacks) do fn() end
assert(binds['ALT + b']=='firefox')
assert(binds['SUPER + V']==[["$HOME/.local/bin/clipboard-stack"]])
assert(commands[2]==[["$HOME/.local/bin/clipboard-watch"]])
assert(commands[1]==[["${XDG_CONFIG_HOME:-$HOME/.config}/hypr/launch.sh"]])
local found=false
for _,c in ipairs(configs) do
 if c.input then assert(c.input.touchpad.natural_scroll); found=true end
 if c.general then assert(c.general.col.inactive_border=='rgb(000000)') end
end
assert(found)
''')

    def test_generic_fallback_and_local_override(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as directory:
            config = Path(directory) / 'hypr'
            config.mkdir()
            body = '''
local calls={}
hl={monitor=function(rule) calls[#calls+1]=rule end}
dofile(''' + repr(str(HYPR / 'monitors.lua')) + ''')
assert(calls[1].output=='' and calls[1].mode=='preferred' and calls[1].position=='auto')
assert(#calls==EXPECTED)
'''
            for expected in (1, 2):
                if expected == 2:
                    (config / 'monitors.local.lua').write_text("hl.monitor({output='CUSTOM', mode='preferred'})\n")
                env = dict(os.environ, XDG_CONFIG_HOME=directory)
                result = subprocess.run(['lua', '-'], input=body.replace('EXPECTED', str(expected)),
                                        text=True, capture_output=True, env=env)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_empty_xdg_uses_home_for_override_and_mode_file(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as directory:
            config = Path(directory) / '.config/hypr'
            config.mkdir(parents=True)
            (config / 'monitors.local.lua').write_text('LOCAL_OVERRIDE_LOADED=true\n')
            (config / 'monitor-mode').write_text('left\n')
            with patch.dict(os.environ, HOME=directory, XDG_CONFIG_HOME=''):
                self.lua('''
hl={monitor=function() end, get_monitors=function() return {} end,
 timer=function() end, on=function() end}
dofile(''' + repr(str(HYPR / 'monitors.lua')) + ''')
assert(LOCAL_OVERRIDE_LOADED, 'empty XDG_CONFIG_HOME must fall back to HOME')
local policy=require('monitor_policy').setup({laptop='PANEL',external='DOCK',
 status_paths={os.getenv('HOME')..'/missing-status'}})
assert(policy.status()=='preparing:left', 'mode file must use HOME fallback')
''')

    def test_missing_status_and_invalid_mode_default_safely(self):
        self.lua('''
local calls,current,tick={},{},nil
hl={monitor=function(r) calls[#calls+1]=r end, get_monitors=function() return current end,
 timer=function(fn) tick=fn end, on=function() end}
local p=require('monitor_policy').setup({laptop='PANEL', external='DOCK',
 status_paths={os.getenv('TMPDIR') .. '/nonexistent-hypr-status'},
 mode_path=os.getenv('TMPDIR') .. '/nonexistent-hypr-mode'})
assert(p.status()=='preparing:auto')
current={{name='PANEL',width=1920,height=1080,scale=1,x=0,y=0}}
tick(); assert(calls[#calls].output=='DOCK' and calls[#calls].disabled)
assert(not calls[#calls-1].disabled)
tick(); assert(p.status()=='ready:auto')
''')

    def test_lifecycle_modes_unplug_and_failure(self):
        with tempfile.TemporaryDirectory(dir=os.environ['TMPDIR']) as directory:
            self.lua('local directory = ' + repr(directory) + '\n' + '''
local calls, current, tick, events = {}, {}, nil, {}
hl = {
 monitor = function(rule) calls[#calls+1] = rule end,
 get_monitors = function() return current end,
 timer = function(fn) tick = fn end,
 on = function(event, fn) events[event] = fn end,
}
local function write(name, value)
 local f = assert(io.open(directory .. '/' .. name, 'w')); f:write(value); f:close()
end
local function screen(name, x, mirror)
 return {name=name, width=1920, height=1080, scale=1, x=x or 0, y=0,
         is_mirror=mirror or false, mirrors={}}
end
write('status', 'connected'); write('mode', 'external')
local policy = require('monitor_policy').setup({
 laptop='PANEL', external='DOCK', laptop_scale=1, external_scale=1,
 status_paths={directory .. '/status'}, mode_path=directory .. '/mode',
})
assert(policy.status() == 'preparing:external')
current={screen('PANEL'), screen('DOCK',1920)}
tick()
assert(policy.status() == 'settling:external')
assert(calls[#calls].output == 'PANEL' and calls[#calls].disabled)
current={screen('DOCK')}; tick(); assert(policy.status() == 'ready:external')
write('status','disconnected'); tick()
assert(policy.status() == 'preparing:external')
assert(calls[#calls-1].output == 'PANEL' and not calls[#calls-1].disabled)
current={screen('PANEL')}; tick(); tick(); assert(policy.status() == 'ready:external')
-- Reconnect a disabled output: polling must discover it without an added event.
write('status','connected'); tick(); current={screen('PANEL')}
for i=1,24 do tick() end
assert(policy.status():match('^failed:external'))
assert(not calls[#calls].disabled and not calls[#calls-1].disabled,
       'failure must preserve any working external while restoring the panel')
-- Explicit retry, then logical-width layouts and nested mirror enumeration.
for _,mode in ipairs({'right','left','mirror','laptop','auto'}) do
 write('mode',mode); policy.apply(true)
 current={screen('PANEL'),screen('DOCK',1920)}; tick()
 if mode=='right' or mode=='auto' then
  assert(calls[#calls].position=='1920x0'); current={screen('PANEL'),screen('DOCK',1920)}
 elseif mode=='left' then
  current={screen('PANEL',1920),screen('DOCK')}
 elseif mode=='mirror' then
  local panel=screen('PANEL'); panel.mirrors={screen('DOCK',0,true)}; current={panel}
 else current={screen('PANEL')} end
 tick(); assert(policy.status()=='ready:' .. mode, policy.status())
end
-- Drift after reaching ready causes re-preparation, not immediate disable.
current={}; tick(); assert(policy.status():match('^preparing:'))
write('mode','nonsense'); tick(); assert(policy.status()=='preparing:auto')
''')

    def test_invalid_settings_have_no_side_effects(self):
        self.lua('''
local effects=0
hl={monitor=function() effects=effects+1 end, timer=function() effects=effects+1 end}
local setup=require('monitor_policy').setup
for _,opts in ipairs({{}, {laptop='A',external='A'},
 {laptop='A',external='B',laptop_scale=0},
 {laptop='A',external='B',laptop_scale=false},
 {laptop='A',external='B',external_scale=0/0},
 {laptop='A',external='B',status_paths='wrong'},
 {laptop='A',external='B',status_paths={3}},
 {laptop='A',external='B',mode_path=false}}) do
 if opts.laptop=='A' and opts.external=='B' and opts.status_paths==nil then
  opts.status_paths={'/sys/class/drm/TEST/status'}
 end
 local ok=pcall(setup, opts); assert(not ok, 'invalid settings must fail before rules')
end
assert(effects==0)
''')

    def test_policy_stages_before_disabling_and_recovers_unplug(self):
        self.lua('''
local calls, current, tick, events = {}, {}, nil, {}
hl = {
 monitor = function(rule) calls[#calls+1] = rule end,
 get_monitors = function() return current end,
 timer = function(fn) tick = fn end,
 on = function(event, fn) events[event] = fn end,
}
local policy = require('monitor_policy').setup({
 laptop = 'PANEL', external = 'DOCK', laptop_scale = 1, external_scale = 1,
 status_paths = {os.getenv('TMPDIR') .. '/nonexistent-hypr-status'},
})
assert(type(policy) == 'table', 'optional monitor policy must be available')
assert(type(tick) == 'function')
assert(calls[1].output == 'PANEL' and calls[1].disabled == false)
assert(not calls[2].disabled, 'preparation must not disable a potentially working screen')
''')


if __name__ == '__main__':
    unittest.main()
