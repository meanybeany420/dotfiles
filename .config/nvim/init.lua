-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

local cpp_builds = {}
local cpp_terminal

local function cpp_directory()
  if vim.b.cpp_directory then
    return vim.b.cpp_directory
  end
  if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "" then
    return vim.fn.expand("%:p:h")
  end
  return vim.fn.getcwd()
end

local function cpp_build()
  vim.cmd("wall")
  local cwd = cpp_directory()
  local files = vim.fn.globpath(cwd, "*.cpp", false, true)
  if #files == 0 then
    vim.notify("No .cpp files in " .. cwd, vim.log.levels.WARN)
    return false
  end

  -- Build to a fresh path so a failed build preserves the previous executable.
  local output = vim.fn.tempname()
  local command = { "g++", "-std=c++20", "-Wall", "-Wextra", "-g" }
  vim.list_extend(command, files)
  vim.list_extend(command, { "-o", output })
  local result = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.fn.delete(output)
    vim.notify(result, vim.log.levels.ERROR)
    return false
  end

  if cpp_builds[cwd] then
    vim.fn.delete(cpp_builds[cwd])
  end
  cpp_builds[cwd] = output
  vim.notify(result ~= "" and result or "C++ build succeeded")
  return true
end

local function cpp_run()
  local cwd = cpp_directory()
  local executable = cpp_builds[cwd]
  if not executable or vim.fn.executable(executable) ~= 1 then
    vim.notify("Run :Cbuild or :Cgo first for this directory", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("ghostty") ~= 1 then
    vim.notify("Ghostty is not installed or is not on PATH", vim.log.levels.ERROR)
    return
  end
  if not cpp_terminal or vim.fn.jobwait({ cpp_terminal.job }, 0)[1] ~= -1 then
    if cpp_terminal then
      vim.uv.fs_close(cpp_terminal.fd)
      vim.fn.delete(cpp_terminal.pipe)
      cpp_terminal = nil
    end
    local pipe = vim.fn.tempname()
    vim.fn.system({ "mkfifo", "-m", "600", pipe })
    if vim.v.shell_error ~= 0 then
      vim.notify("Could not create C++ runner pipe", vim.log.levels.ERROR)
      return
    end
    -- Open both ends so sending a run never blocks Neovim waiting for a reader.
    local fd, err = vim.uv.fs_open(pipe, "r+", 384)
    if not fd then
      vim.fn.delete(pipe)
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    local job = vim.fn.jobstart({
      "ghostty",
      "--working-directory=" .. cwd,
      "--wait-after-command=false",
      "-e", "sh", "-c", [[
trap ':' INT
exec 3<> "$1"
while IFS= read -r directory <&3 && IFS= read -r executable <&3; do
  printf '\033[2J\033[H'
  (cd -- "$directory" && "$executable" 3<&-)
  status=$?
  printf '\n[Exit %s — run :Cgo or :Crun in Neovim to run again]\n' "$status"
done
]], "cpp-runner", pipe,
    }, { cwd = cwd })
    if job <= 0 then
      vim.uv.fs_close(fd)
      vim.fn.delete(pipe)
      vim.notify("Could not launch Ghostty", vim.log.levels.ERROR)
      return
    end
    cpp_terminal = { job = job, pipe = pipe, fd = fd }
  end
  vim.uv.fs_write(cpp_terminal.fd, cwd .. "\n" .. executable .. "\n", -1)
end

vim.api.nvim_create_user_command("Cbuild", cpp_build, { desc = "Compile C++ files beside the current file" })
vim.api.nvim_create_user_command("Crun", cpp_run, { desc = "Run the last successful C++ build" })
vim.api.nvim_create_user_command("Cgo", function()
  if cpp_build() then
    cpp_run()
  end
end, { desc = "Compile and run C++ files beside the current file" })
