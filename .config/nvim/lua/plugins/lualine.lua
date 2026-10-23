return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      theme = {
        normal = {
          c = { bg = "#050505", fg = "#5d3036" },
        },
        inactive = {
          c = { bg = "#050505", fg = "#5d3036" },
        },
      },
      globalstatus = true,
      component_separators = "",
      section_separators = "",
    },
    sections = {
      lualine_a = {
        {
          "mode",
          fmt = function(s)
            return s:sub(1, 3)
          end,
        },
      },
      lualine_b = {},
      lualine_c = {
        {
          "filename",
          path = 1, -- relative file path
          padding = { left = 2, right = 2 },
        },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },

    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = {
        {
          "filename",
          path = 1,
          padding = { left = 2, right = 2 },
        },
      },
      lualine_x = {},
      lualine_y = {},
      lualine_z = {},
    },
  },
}
