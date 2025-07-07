Full config in lua script with Packer.nvim:

```lua
-- Packer.nvim
use { 'jayli/vim-easycomplete', requires = {'L3MON4D3/LuaSnip'}}
-- For snippet support, 'SirVer/ultisnips' is an alternative option

-- Enable the plugin. Default is on. Set `0` if you want to turn off the plugin.
-- Install lsp via `:InstallLspServer`
vim.g.easycomplete_enable = 1

-- pum border. Default is on.
vim.g.easycomplete_winborder = 1

-- Highlight the symbol when holding the cursor if you need it.
-- Default is off.
vim.g.easycomplete_cursor_word_hl = 0

-- GoTo code navigation
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
vim.keymap.set('n', 'gh', ':EasyCompleteHover<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')

-- Using nerdfont is highly recommended
vim.g.easycomplete_nerd_font = 1
-- Custom kind icons. Of course you can use default settings without redefined kind icons
vim.g.easycomplete_kind_icons = {
  buf = "",
  dict = "󰈍",
  snip = "",
  tabnine = "󱙺",
  operator = "󰞷",
  class = "",
  local = "✎",
  constant = "",
  enum = "",
  field = "",
  folder = "",
  interface = "",
  snippet = "",
  text = "",
  variable = "",
  event = "",
  const = "",
  let = "",
  color = "",
  constructor = "",
  enummember = "",
  file = "",
  function = "ƒ",
  keyword = "",
  struct = "󰙅",
  typeparameter = "§",
  module = "",
  var = "",
  alias = "",
  parameter = "󰏗",
  property = "󰙅"
}

-- Custom pum format. Only avilable with `g:easycomplete_nerd_font == 1` in nvim
vim.g.easycomplete_pum_format = {"kind", "abbr", "menu"}

-- Define highlight group for fuzzy matched charactors.
-- All customizable highlight name:
--  EasyPmenu
--  EasyPmenuKind
--  EasyPmenuExtra
--  EasyFunction
--  EasySnippet
--  EasyTabNine
--  EasySnippets
vim.cmd[[
  hi PmenuKind guifg=LightSteelBlue guibg=#2c2c3e
  hi Pmenu guifg=Lavender guibg=#2c2c3e
  hi PmenuExtra guifg=SlateGray guibg=#2c2c3e
  hi PmenuSel guifg=white guibg=#3a3a4c
  hi EasyFuzzyMatch guifg=#75adf3
]]

-- Enable Tabnine, default is on, install tabnine lsp via `:InstallLspServer tn`
vim.g.easycomplete_tabnine_enable = 1
-- Enable Tabnine suggestion, default is off
vim.g.easycomplete_tabnine_suggestion = 0

-- Enable directory complete. Default is on
vim.g.easycomplete_directory_enable = 1

-- Show abbr(shortname) at `menu` position in pum
vim.g.easycomplete_menu_abbr = 1

-- Custom lsp support for a specific filetype
vim.g.easycomplete_filetypes = {
  vim = {
    whitelist = vim.fn["easycomplete#FileTypes"]("vim", {"vim","vimrc","nvim"})
  }
}

-- Enable ghost text support, default is on
vim.g.easycomplete_ghost_text = 1

-- Change the default complete trigger to another keymap
-- Default is "<tab>"
vim.g.easycomplete_tab_trigger = "<tab>"
vim.g.easycomplete_shift_tab_trigger = "<S-Tab>"

-- Define the signature offset, default is 0
vim.g.easycomplete_signature_offset = 0
-- diagnostics keymap. Default is c-n
vim.g.easycomplete_diagnostics_next = "<c-n>"
vim.g.easycomplete_diagnostics_prev = "<S-C-N>"
-- Enable diagnostics, default is 1
vim.g.easycomplete_diagnostics_enable = 1
-- Enable signature, default is 1
vim.g.easycomplete_signature_enable = 1
-- Enable diagnostics via cursor hold event, default is 1
vim.g.easycomplete_diagnostics_hover = 1

-- close pum keymap
-- vim.keymap.set('i', '<C-M>', '<Plug>EasycompleteClosePum')

-- Select next/previous pum items Keymap
-- vim.g.easycomplete_tab_trigger = "<C-J>"
-- vim.g.easycomplete_shift_tab_trigger = "<C-K>"

-- Redefine CR action
-- vim.g.easycomplete_use_default_cr = 0
-- vim.keymap.set('i', '<C-L>', '<Plug>EasycompleteCR')

-- set 0 to Custom Pum style with border, default is 1
vim.g.easycomplete_pum_pretty_style = 1
-- vim.cmd("hi FloatBorder guifg=green")
-- vim.cmd("hi Pmenu guibg=gray")

-- recommended
vim.opt.updatetime = 150

-- Do not select first matched item
-- "set completeopt-=noselect" to automatically select first matched item
vim.g.easycomplete_pum_noselect = 0
```

Lua style setup

```lua
-- lua style setup
-- `tabnine_enable = 0` alias `vim.g.easycomplete_tabnine_enable = 0`
require("easycomplete").setup({
    pum_noselect = 0,
    tabnine_enable = 0,
    nerd_font = 1,
    enable = 1,
    winborder = 1,
    ghost_text = 1,
    menu_abbr = 0,
    pum_format = {"abbr", "kind", "menu"}
  })
```
