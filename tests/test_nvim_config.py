"""Offline characterization tests; never load LazyVim or launch real Ghostty.

Run: python -m unittest discover -s tests -p 'test_nvim*.py' -v
Requires Neovim; compiler cases also require g++, sh, and mkfifo.
"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
CONFIG = REPO / ".config" / "nvim"
NVIM = shutil.which("nvim")
HAS_COMPILER = all(shutil.which(tool) for tool in ("g++", "sh", "mkfifo"))

LUA_SETUP = r'''
local root = vim.env.NVIM_TEST_ROOT
local config = vim.env.NVIM_TEST_CONFIG
local notes = {}
vim.notify = function(message, level)
  notes[#notes + 1] = { message = message, level = level }
end
-- Stub BEFORE init.lua: no bootstrap, plugin discovery, downloads or user config.
package.loaded["config.lazy"] = true
dofile(config .. "/init.lua")
local function edit(name)
  vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. name .. "/main.cpp"))
end
local function read_log()
  local path = root .. "/runner.log"
  return vim.fn.filereadable(path) == 1 and table.concat(vim.fn.readfile(path), "\n") or ""
end
local function await_output(text, count)
  count = count or 1
  assert(vim.wait(5000, function()
    local _, matches = read_log():gsub(vim.pesc(text), "")
    return matches >= count
  end, 10), "Runner did not print " .. text .. ": " .. read_log())
end
local function notified(text, level)
  for _, note in ipairs(notes) do
    if tostring(note.message):find(text, 1, true) and (not level or note.level == level) then
      return true
    end
  end
  return false
end
'''

OIL_SETUP = r'''
local entries = { { name = "existing" }, { name = "new file.cpp" }, { name = "other" } }
local oil = {
  setup = function(opts) assert(opts.default_file_explorer) end,
  get_cursor_entry = function() return { parsed_name = "new file.cpp/" } end,
  get_entry_on_line = function(_, line) return entries[line] end,
  open = function() error("Oil startup must not run in this isolated test") end,
}
package.loaded.oil = oil
dofile(config .. "/lua/plugins/oil.lua").config()
vim.api.nvim_buf_set_name(0, "oil:///fixture/")
vim.bo.filetype = "oil"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "001 existing", "002 new file.cpp", "003 other" })
vim.bo.modified = false
local function event(name, data)
  vim.api.nvim_exec_autocmds("User", { pattern = name, data = data or {} })
end
local function complete()
  event("OilMutationComplete")
  vim.wait(50, function() return false end, 5)
end
local create = { type = "create", url = "oil:///fixture/new file.cpp" }
'''


@unittest.skipUnless(NVIM, "Neovim is required")
class NeovimConfigTests(unittest.TestCase):
    def run_lua(self, body):
        assert NVIM is not None  # The class skip also guards execution without Neovim.
        # Every writable path belongs to this disposable tree under TMPDIR.
        with tempfile.TemporaryDirectory(prefix="dotfiles-nvim-", dir=os.environ.get("TMPDIR")) as temporary:
            root = Path(temporary)
            for name in ("home", "config", "data", "state", "cache", "runtime", "tmp", "bin"):
                (root / name).mkdir(mode=0o700)
            for name, marker in (("project A's sources", "PROJECT_A"), ("project B", "PROJECT_B")):
                project = root / name
                project.mkdir()
                (project / "main.cpp").write_text(
                    '#include <iostream>\n#include <filesystem>\nint helper();\n'
                    'int main() { std::cout << "' + marker + ':" << helper() << ":" '
                    '<< std::filesystem::current_path().string() << std::endl; }\n'
                )
                (project / "helper.cpp").write_text("int helper() { return 7; }\n")
            # This must not be compiled: source selection is beside the buffer,
            # not the editor's cwd and not recursive.
            (root / "unrelated.cpp").write_text("#error OUTSIDE_PROJECT\n")
            nested = root / "project A's sources" / "nested"
            nested.mkdir()
            (nested / "broken.cpp").write_text("#error NOT_RECURSIVE\n")
            ghostty = root / "bin" / "ghostty"
            ghostty.write_text(
                '#!/bin/sh\n'
                'printf "%s\\n" "$@" >> "$NVIM_TEST_ROOT/ghostty.args"\n'
                'while [ "$#" -gt 0 ] && [ "$1" != "-e" ]; do shift; done\n'
                '[ "$#" -gt 0 ] || exit 90\nshift\n'
                'exec "$@" >> "$NVIM_TEST_ROOT/runner.log" 2>&1\n'
            )
            ghostty.chmod(0o700)
            env = os.environ.copy()
            env.update({
                "HOME": str(root / "home"),
                "XDG_CONFIG_HOME": str(root / "config"),
                "XDG_DATA_HOME": str(root / "data"),
                "XDG_STATE_HOME": str(root / "state"),
                "XDG_CACHE_HOME": str(root / "cache"),
                "XDG_RUNTIME_DIR": str(root / "runtime"),
                "TMPDIR": str(root / "tmp"),
                "NVIM_TEST_ROOT": str(root),
                "NVIM_TEST_CONFIG": str(CONFIG),
                "PATH": str(root / "bin") + os.pathsep + env.get("PATH", ""),
            })
            for key in ("NVIM", "NVIM_LISTEN_ADDRESS", "VIMINIT", "EXINIT", "LUA_PATH", "LUA_CPATH"):
                env.pop(key, None)
            script = root / "test.lua"
            script.write_text(
                "local ok, err = xpcall(function()\n" + LUA_SETUP + body
                + '\nend, debug.traceback)\nif not ok then\n'
                + '  io.stderr:write(err .. "\\n")\n  vim.cmd("cquit 1")\nend\nvim.cmd("qa!")\n'
            )
            result = subprocess.run(
                [NVIM, "--headless", "--noplugin", "-u", "NONE", "-i", "NONE", "-n",
                 "-c", "lua dofile(" + json.dumps(str(script)) + ")"],
                cwd=root, env=env, capture_output=True, text=True, timeout=30,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            # Neovim may report errors but still exit zero: reject those too.
            self.assertNotIn("Error", result.stderr, result.stderr)

    def test_cpp_commands_registered(self):
        self.run_lua('''
for _, name in ipairs({ "Cbuild", "Crun", "Cgo" }) do
  assert(vim.fn.exists(":" .. name) == 2, "Missing command " .. name)
end
''')

    @unittest.skipUnless(HAS_COMPILER, "g++, sh and mkfifo are required")
    def test_builds_all_cpp_beside_buffer_and_runs_in_that_directory(self):
        self.run_lua('''
edit("project A's sources")
vim.cmd.Cbuild()
assert(notified("C++ build succeeded"))
assert(read_log() == "", "Cbuild must not run")
vim.cmd.Crun()
await_output("PROJECT_A:7:" .. root .. "/project A's sources")
local args = vim.fn.readfile(root .. "/ghostty.args")
assert(args[1] == "--working-directory=" .. root .. "/project A's sources")
assert(args[2] == "--wait-after-command=false")
''')

    @unittest.skipUnless(HAS_COMPILER, "g++, sh and mkfifo are required")
    def test_failed_build_preserves_last_success_and_failed_cgo_does_not_run(self):
        self.run_lua('''
edit("project A's sources")
vim.cmd.Cgo()
await_output("PROJECT_A:7:")
vim.fn.writefile({ "#error DELIBERATE_BUILD_FAILURE" }, root .. "/project A's sources/helper.cpp")
vim.cmd.Cbuild()
assert(notified("DELIBERATE_BUILD_FAILURE", vim.log.levels.ERROR))
vim.cmd.Crun()
await_output("PROJECT_A:7:", 2)
vim.wait(50, function() return false end)
local before = read_log()
vim.cmd.Cgo()
vim.wait(100, function() return false end)
assert(read_log() == before, "Failed Cgo must not run the previous artifact")
local args = vim.fn.readfile(root .. "/ghostty.args")
local launches = 0
for _, arg in ipairs(args) do
  if arg:find("--working-directory=", 1, true) == 1 then launches = launches + 1 end
end
assert(launches == 1, "Repeat runs must reuse one mocked Ghostty/FIFO")
''')

    @unittest.skipUnless(HAS_COMPILER, "g++, sh and mkfifo are required")
    def test_successful_artifacts_are_scoped_by_directory(self):
        self.run_lua('''
edit("project A's sources")
vim.cmd.Cbuild()
edit("project B")
vim.cmd.Crun()
assert(notified("Run :Cbuild or :Cgo first for this directory", vim.log.levels.WARN))
assert(read_log() == "", "Must not run a different directory's artifact")
vim.cmd.Cgo()
await_output("PROJECT_B:7:" .. root .. "/project B")
edit("project A's sources")
vim.cmd.Crun()
await_output("PROJECT_A:7:" .. root .. "/project A's sources")
''')

    @unittest.skipUnless(HAS_COMPILER, "g++, sh and mkfifo are required")
    def test_scratch_buffer_uses_cwd_and_explicit_directory_override(self):
        self.run_lua('''
vim.bo.buftype = "nofile"
vim.cmd.cd(vim.fn.fnameescape(root .. "/project B"))
vim.cmd.Cgo()
await_output("PROJECT_B:7:" .. root .. "/project B")
vim.b.cpp_directory = root .. "/project A's sources"
vim.cmd.Cgo()
await_output("PROJECT_A:7:" .. root .. "/project A's sources")
''')

    @unittest.skipUnless(HAS_COMPILER, "g++, sh and mkfifo are required")
    def test_build_wall_saves_other_modified_buffers(self):
        self.run_lua('''
vim.cmd.edit(vim.fn.fnameescape(root .. "/project A's sources/helper.cpp"))
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "int helper() { return 9; }" })
vim.bo.bufhidden = "hide"
edit("project A's sources")
vim.cmd.Cgo()
await_output("PROJECT_A:9:")
assert(vim.fn.readfile(root .. "/project A's sources/helper.cpp")[1]:find("return 9", 1, true))
''')

    def test_no_cpp_files_warns_without_launching_terminal(self):
        self.run_lua('''
vim.cmd.cd(vim.fn.fnameescape(root .. "/home"))
vim.cmd.Cgo()
assert(notified("No .cpp files in ", vim.log.levels.WARN))
assert(vim.fn.filereadable(root .. "/ghostty.args") == 0)
''')

    def test_arrow_and_shift_arrow_mappings_are_disabled(self):
        self.run_lua('''
dofile(config .. "/lua/config/keymaps.lua")
for _, mode in ipairs({ "n", "i", "x", "s" }) do
  for _, key in ipairs({ "Up", "Down", "Left", "Right" }) do
    for _, prefix in ipairs({ "", "S-" }) do
      assert(vim.fn.maparg("<" .. prefix .. key .. ">", mode) == "<Nop>", mode .. prefix .. key)
    end
  end
end
''')

    def test_oil_follows_created_entry_and_prefers_cursor_entry(self):
        self.run_lua(OIL_SETUP + '''
event("OilActionsPre", { actions = { create, { type = "create", url = "oil:///fixture/other" } } })
event("OilActionsPost", {})
complete()
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 2, 4 }))
-- Pending state is consumed once, not reused on unrelated mutations.
vim.api.nvim_win_set_cursor(0, { 1, 0 })
complete()
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, 0 }))
''')

    def test_oil_ignores_failed_and_unrelated_creates_and_changed_window(self):
        self.run_lua(OIL_SETUP + '''
event("OilActionsPre", { actions = { create } })
event("OilActionsPost", { err = "fixture failure" })
complete()
assert(vim.api.nvim_win_get_cursor(0)[1] == 1)
event("OilActionsPre", { actions = { { type = "create", url = "oil:///elsewhere/new file.cpp" } } })
complete()
assert(vim.api.nvim_win_get_cursor(0)[1] == 1)
event("OilActionsPre", { actions = { create } })
vim.cmd.enew()
complete()
assert(vim.deep_equal(vim.api.nvim_win_get_cursor(0), { 1, 0 }))
''')


if __name__ == "__main__":
    unittest.main()
