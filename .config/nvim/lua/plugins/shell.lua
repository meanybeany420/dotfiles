return {
  -- Treesitter: shell/zsh syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
      },
    },
  },

  -- LSP: shell language server
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {
          filetypes = { "sh", "bash", "zsh" },
        },
      },
    },
  },

  -- Mason: install bash-language-server automatically
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "bashls",
      },
    },
  },
  vim.filetype.add({
    filename = {
      [".zshrc"] = "zsh",
      [".zprofile"] = "zsh",
      [".zshenv"] = "zsh",
      [".p10k.zsh"] = "zsh",
    },
    pattern = {
      [".*/zsh/.*"] = "zsh",
    },
  }),
}
