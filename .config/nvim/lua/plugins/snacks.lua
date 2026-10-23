return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>E",
        function()
          Snacks.explorer()
        end,
        desc = "Snacks Explorer",
      },
    },
  },
}
