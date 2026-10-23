-- ~/.config/nvim/lua/colors/bean.lua

local M = {}

M.palette = {
  -- backgrounds
  bg0 = "#050505",
  bg1 = "#090909",
  bg2 = "#0d0d0d",
  bg3 = "#121212",
  bg4 = "#181818",

  -- foregrounds
  fg0 = "#968b7a",
  fg1 = "#968b7a",
  fg2 = "#746b5f",
  fg3 = "#524c44",

  -- greys
  gray0 = "#1a1a1a",
  gray1 = "#242424",
  gray2 = "#303030",
  gray3 = "#3d3d3d",

  -- very dim muted colours
  red = "#67413f",
  orange = "#bb8861",
  green = "#38433a",
  blue = "#5c6569",
  pink = "#7a6d81",
  purple = "#35263f",

  -- diagnostics
  error = "#460f15",
  warn = "#8b1c28",
  info = "#66788f",
  hint = "#637f78",
}

function M.setup()
  vim.cmd("highlight clear")

  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "bean"

  local c = M.palette

  local groups = {
    -- UI
    Normal = { fg = c.fg0, bg = c.bg0 },
    NormalNC = { fg = c.fg1, bg = c.bg0 },
    NormalFloat = { fg = c.fg0, bg = c.bg1 },
    FloatBorder = { fg = c.gray1, bg = c.bg1 },

    CursorLine = { bg = c.bg2 },
    Visual = { bg = c.gray1 },
    Search = { fg = c.fg0, bg = c.gray2 },
    IncSearch = { fg = c.bg0, bg = c.orange },

    LineNr = { fg = c.gray3, bg = c.bg0 },
    CursorLineNr = { fg = c.fg1, bg = c.bg0 },
    SignColumn = { bg = c.bg0 },
    EndOfBuffer = { fg = c.bg0, bg = c.bg0 },
    WinSeparator = { fg = c.gray0 },

    Directory = { fg = c.orange },
    OilDir = { link = "Directory" },

    StatusLine = { fg = c.fg1, bg = c.bg3 },
    StatusLineNC = { fg = c.fg3, bg = c.bg1 },

    Pmenu = { fg = c.fg1, bg = c.bg1 },
    PmenuSel = { fg = c.fg0, bg = c.gray1 },
    PmenuSbar = { bg = c.bg2 },
    PmenuThumb = { bg = c.gray2 },

    VertSplit = { fg = c.gray0 },
    MatchParen = { fg = c.orange, bg = c.bg3 },

    -- comments
    Comment = { fg = c.fg3, italic = true },

    -- strings: "text"
    String = { fg = c.green },
    Character = { fg = c.green },

    -- numbers / constants
    Number = { fg = c.purple },
    Boolean = { fg = c.red },
    Float = { fg = c.purple },
    Constant = { fg = c.purple },

    -- variables / normal identifiers
    Identifier = { fg = c.fg0 },

    -- functions and class-like names
    Function = { fg = c.orange },
    Type = { fg = c.red },
    Structure = { fg = c.orange },
    Typedef = { fg = c.orange },

    -- keywords: public, private, class, if, else, return, etc.
    Statement = { fg = c.blue },
    Conditional = { fg = c.blue },
    Repeat = { fg = c.blue },
    Label = { fg = c.blue },
    Keyword = { fg = c.blue },
    Exception = { fg = c.blue },
    StorageClass = { fg = c.blue },

    -- imports / macros / preprocessors
    PreProc = { fg = c.blue },
    Include = { fg = c.blue },
    Define = { fg = c.pink },
    Macro = { fg = c.pink },

    -- types: bool, int, string, list, etc.
    -- In old Vim syntax these often fall under Type.
    -- Keep Type red for your requested behaviour.

    -- operators / punctuation / special
    Operator = { fg = c.fg2 },
    Delimiter = { fg = c.fg3 },
    Special = { fg = c.pink },
    SpecialChar = { fg = c.pink },
    Tag = { fg = c.orange },

    -- misc
    Title = { fg = c.orange },
    Todo = { fg = c.orange, bg = c.bg0 },
    Error = { fg = c.error, bg = c.bg0 },
    WarningMsg = { fg = c.warn },

    -- diagnostics
    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.warn },
    DiagnosticInfo = { fg = c.info },
    DiagnosticHint = { fg = c.hint },
    DiagnosticOk = { fg = c.green },

    DiagnosticVirtualTextError = { fg = c.error, bg = c.bg0 },
    DiagnosticVirtualTextWarn = { fg = c.warn, bg = c.bg0 },
    DiagnosticVirtualTextInfo = { fg = c.info, bg = c.bg0 },
    DiagnosticVirtualTextHint = { fg = c.hint, bg = c.bg0 },

    DiagnosticSignError = { fg = c.error, bg = c.bg0 },
    DiagnosticSignWarn = { fg = c.warn, bg = c.bg0 },
    DiagnosticSignInfo = { fg = c.info, bg = c.bg0 },
    DiagnosticSignHint = { fg = c.hint, bg = c.bg0 },

    -- LSP references, not semantic colouring
    LspReferenceText = { bg = c.bg2 },
    LspReferenceRead = { bg = c.bg2 },
    LspReferenceWrite = { bg = c.bg2 },
    -- Tree-sitter
    ["@comment"] = { link = "Comment" },

    -- strings
    ["@string"] = { link = "String" },
    ["@string.documentation"] = { link = "String" },
    ["@character"] = { link = "Character" },

    -- numbers / constants
    ["@number"] = { link = "Number" },
    ["@number.float"] = { link = "Float" },
    ["@float"] = { link = "Float" },
    ["@boolean"] = { link = "Boolean" },
    ["@constant"] = { link = "Constant" },
    ["@constant.builtin"] = { link = "Constant" },
    ["@constant.macro"] = { link = "Macro" },

    -- variables / identifiers
    ["@variable"] = { link = "Identifier" },
    ["@variable.member"] = { link = "Identifier" },
    ["@variable.parameter"] = { link = "Identifier" },
    ["@parameter"] = { link = "Identifier" },
    ["@property"] = { link = "Identifier" },
    ["@field"] = { link = "Identifier" },

    -- functions: orange
    ["@function"] = { link = "Function" },
    ["@function.call"] = { link = "Function" },
    ["@method"] = { link = "Function" },
    ["@method.call"] = { link = "Function" },
    ["@function.method"] = { link = "Function" },
    ["@function.method.call"] = { link = "Function" },

    -- builtins: keep normal foreground
    ["@function.builtin"] = { fg = c.fg0 },
    ["@function.method.builtin"] = { fg = c.fg0 },
    ["@variable.builtin"] = { fg = c.fg0 },

    -- class-like / constructors: orange
    ["@constructor"] = { link = "Structure" },
    ["@module"] = { link = "Structure" },
    ["@namespace"] = { link = "Structure" },

    -- types: red
    ["@type"] = { link = "Type" },
    ["@type.builtin"] = { link = "Type" },
    ["@type.definition"] = { link = "Typedef" },

    -- keywords: blue
    ["@keyword"] = { link = "Keyword" },
    ["@keyword.function"] = { link = "Keyword" },
    ["@keyword.return"] = { link = "Keyword" },
    ["@keyword.operator"] = { link = "Keyword" },
    ["@keyword.import"] = { link = "Include" },
    ["@keyword.storage"] = { link = "StorageClass" },
    ["@conditional"] = { link = "Conditional" },
    ["@repeat"] = { link = "Repeat" },
    ["@exception"] = { link = "Exception" },

    -- operators / punctuation
    ["@operator"] = { link = "Operator" },
    ["@punctuation"] = { link = "Delimiter" },
    ["@punctuation.bracket"] = { link = "Delimiter" },
    ["@punctuation.delimiter"] = { link = "Delimiter" },
    ["@punctuation.special"] = { link = "Special" },

    -- markup / tags
    ["@tag"] = { link = "Tag" },
    ["@tag.attribute"] = { link = "Identifier" },
    ["@tag.delimiter"] = { link = "Delimiter" },
    ["@markup.heading"] = { link = "Title" },
    ["@markup.link"] = { link = "Underlined" },
    ["@markup.raw"] = { link = "String" },
    ["@markup.strong"] = { bold = true },
    ["@markup.italic"] = { italic = true },
  }
  for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
