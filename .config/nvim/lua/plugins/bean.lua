return {
  dir = "~/the_bean_theme.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("bean_theme")
  end,
}
