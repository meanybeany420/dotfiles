-- ~/.config/nvim/lua/plugins/lsp.lua

return {
  {
    "SmiteshP/nvim-navic",
  },

  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local ok, navic = pcall(require, "nvim-navic")

      local function navic_on_attach(client, bufnr)
        if ok and client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end
      end

      opts.servers = opts.servers or {}

      opts.servers.jdtls = opts.servers.jdtls or {}
      opts.servers.jdtls.on_attach = function(client, bufnr)
        navic_on_attach(client, bufnr)
      end

      opts.servers.gopls = vim.tbl_deep_extend("force", opts.servers.gopls or {}, {
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = true,
            semanticTokens = true,
            analyses = {
              unusedparams = true,
              shadow = true,
            },
          },
        },
        on_attach = function(client, bufnr)
          navic_on_attach(client, bufnr)
        end,
      })

      return opts
    end,
  },
}
