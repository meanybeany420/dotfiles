return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "lua_ls",
        "jdtls",
        "pyright",
        "clangd",
        "rust_analyzer",
        "ts_ls",
        "html",
        "cssls",
        "jsonls",
        "yamlls",
      },
    },
  },
}
