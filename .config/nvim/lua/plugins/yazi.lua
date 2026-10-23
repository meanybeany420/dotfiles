-- ~/.config/nvim/lua/plugins/yazi.lua

return {
  {
    "mikavilpas/yazi.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      {
        "<leader>y",
        "<cmd>Yazi<cr>",
        desc = "Open Yazi at current file",
      },
      {
        "<leader>Y",
        "<cmd>Yazi cwd<cr>",
        desc = "Open Yazi in cwd",
      },
    },
    opts = {
      open_for_directories = true,
    },
  },
}
