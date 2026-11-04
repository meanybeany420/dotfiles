return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,

  config = function()
    local oil = require("oil")

    oil.setup({
      default_file_explorer = true,
      view_options = {
        show_hidden = false,
      },
    })

    local pending_cursor
    local group = vim.api.nvim_create_augroup("OilFollowCreatedEntry", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "OilActionsPre",
      callback = function(event)
        pending_cursor = nil
        if vim.bo.filetype ~= "oil" then
          return
        end
        local buf = vim.api.nvim_get_current_buf()
        local url = vim.api.nvim_buf_get_name(buf)
        local current = oil.get_cursor_entry()
        for _, action in ipairs(event.data.actions) do
          if action.type == "create" and action.url:sub(1, #url) == url then
            local name = action.url:sub(#url + 1):match("^([^/]+)")
            if name then
              pending_cursor = { buf = buf, win = vim.api.nvim_get_current_win(), name = name }
              if current and (current.parsed_name or current.name):gsub("/$", "") == name then
                break
              end
            end
          end
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "OilActionsPost",
      callback = function(event)
        if event.data.err then
          pending_cursor = nil
        end
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "OilMutationComplete",
      callback = function()
        local target = pending_cursor
        pending_cursor = nil
        if not target then
          return
        end
        vim.schedule(function()
          if not vim.api.nvim_win_is_valid(target.win)
            or vim.api.nvim_win_get_buf(target.win) ~= target.buf then
            return
          end
          for line = 1, vim.api.nvim_buf_line_count(target.buf) do
            local entry = oil.get_entry_on_line(target.buf, line)
            if entry and entry.name == target.name then
              local text = vim.api.nvim_buf_get_lines(target.buf, line - 1, line, false)[1]
              local column = text:find(target.name, 1, true) or 1
              vim.api.nvim_win_set_cursor(target.win, { line, column - 1 })
              return
            end
          end
        end)
      end,
    })

    vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open Oil" })

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc() == 0 then
          vim.schedule(function()
            vim.cmd("only | enew")
            oil.open(vim.fn.getcwd())
          end)
        end
      end,
    })
  end,
}
