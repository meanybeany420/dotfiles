return {
  { import = "lazyvim.plugins.extras.editor.overseer" },

  {
    "stevearc/overseer.nvim",
    opts = {
      strategy = {
        "toggleterm",
        direction = "horizontal",
        auto_scroll = true,
        quit_on_exit = "success",
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>o", group = "overseer" },
      },
    },
  },
}
