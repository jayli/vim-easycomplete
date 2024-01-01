Full config in lua script:

```lua
use { 'jayli/vim-easycomplete', requires = {'SirVer/ultisnips'}}

-- Enable the plugin. Default is on.
vim.g.easycomplete_enable = 1

-- Highlight the symbol when holding the cursor if you need it.
-- Default is off.
vim.g.easycomplete_cursor_word_hl = 1

-- GoTo code navigation
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
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
vim.g.easycomplete_fuzzymatch_hlgroup = "MyGroup"

-- Enable Tabnine, default is on
vim.g.easycomplete_tabnine_enable
-- Enable Tabnine suggestion, default is on
vim.g.easycomplete_tabnine_suggestion = 1

-- Enable directory complete. Default is on
vim.g.easycomplete_directory_enable = 1

-- Custom lsp support for a specific filetype
vim.g.easycomplete_filetypes = {
  vim = {
    whitelist = vim.fn["easycomplete#FileTypes"]("vim", {"vim","vimrc","nvim"})
  }
}

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
```
