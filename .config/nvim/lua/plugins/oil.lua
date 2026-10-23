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
