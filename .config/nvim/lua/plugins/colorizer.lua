-- ~/.config/nvim/lua/plugins/colorizer.lua
return {
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("colorizer").setup({
        filetypes = {
          "*",
        },
        user_default_options = {
          RGB = true,
          RRGGBB = true,
          RRGGBBAA = true,
          AARRGGBB = true,
          names = false,
          rgb_fn = true,
          hsl_fn = true,
          css = true,
          css_fn = true,
          mode = "background",
          tailwind = true,
        },
      })

      vim.defer_fn(function()
        require("colorizer").attach_to_buffer(0)
      end, 0)
    end,
  },
}
