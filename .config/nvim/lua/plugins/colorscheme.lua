return {
  {
    dir = vim.fn.expand("~/the_bean_theme.nvim"),
    name = "the_bean_theme",
    lazy = false,
    priority = 1000,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "bean_theme",
    },
  },
}
