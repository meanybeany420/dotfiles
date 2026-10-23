return {
  "folke/noice.nvim",
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",
    },

    views = {
      cmdline_popup = {
        position = {
          row = "100%",
          col = "70%",
        },
        size = {
          width = "60%",
          height = "auto",
        },
        border = {
          style = "none",
          padding = { 0, 1 },
        },
        win_options = {
          winhighlight = {
            Normal = "Normal",
            FloatBorder = "Normal",
          },
        },
      },
    },

    presets = {
      command_palette = false,
    },
  },

  config = function(_, opts)
    require("noice").setup(opts)

    vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { fg = "#968b7a" })
    vim.api.nvim_set_hl(0, "NoiceCmdlineIconCmdline", { fg = "#968b7a" })
    vim.api.nvim_set_hl(0, "NoiceCmdlineIconSearch", { fg = "#968b7a" })
  end,
}
