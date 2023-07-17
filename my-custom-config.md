## my custom config with lua

```lua
vim.g.easycomplete_diagnostics_enable = 1
vim.g.easycomplete_signature_enable = 1
vim.g.easycomplete_tabnine_enable = 1
vim.g.easycomplete_cursor_word_hl = 1
vim.g.easycomplete_nerd_font = 1
vim.keymap.set('n', 'gr', ':EasyCompleteReference<CR>')
vim.keymap.set('n', 'gd', ':EasyCompleteGotoDefinition<CR>')
vim.keymap.set('n', 'rn', ':EasyCompleteRename<CR>')
vim.keymap.set('n', 'gb', ':BackToOriginalBuffer<CR>')
```
