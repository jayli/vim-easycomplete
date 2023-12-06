local Util = require "easycomplete.util"
local log = Util.log
local Export = {}
local tabnine_ns = vim.api.nvim_create_namespace('tabnine_ns')

function Export.nvim_init_tabnine_hl()
  local cursorline_bg = vim.fn["easycomplete#ui#GetBgColor"]("CursorLine")
  local normal_bg = vim.fn["easycomplete#ui#GetBgColor"]("Normal")
  local linenr_fg = vim.fn["easycomplete#ui#GetFgColor"]("LineNr")
  vim.api.nvim_set_hl(0, "TabNineSuggestionFirstLine", {
    bg = cursorline_bg,
    fg = linenr_fg,
  })
  vim.api.nvim_set_hl(0, "TabNineSuggestionNoneFirstLine", {
    fg = linenr_fg,
    bg = normal_bg
  })
end

function Export.init()
  Export.nvim_init_tabnine_hl()
  vim.cmd [[
    autocmd ColorScheme * call v:lua.require("easycomplete.tabnine").nvim_init_tabnine_hl()
  ]]
end

-- code_block 是一个字符串，有可能包含回车符
-- call v:lua.require("easycomplete.tabnine").show_hint()
-- code_block 是数组类型
function Export.show_hint(code_block)
  local lines = {}
  local count = 1
  local code_lines = code_block
  for key, line in pairs(code_lines) do
    local highlight_group = ""
    if count == 1 then
      highlight_group = "TabNineSuggestionFirstLine"
    else
      highlight_group = "TabNineSuggestionNoneFirstLine"
    end
    count = count + 1
    table.insert(lines, {{line, highlight_group}})
  end

  local virt_text = lines[1]
  local virt_lines

  if #lines >= 2 then
    table.remove(lines, 1)
    virt_lines = lines
  else
    virt_lines = nil
  end

  vim.api.nvim_buf_set_extmark(0, tabnine_ns, vim.fn.line('.') - 1, vim.fn.col('.') - 1, {
    id = 1,
    virt_text_pos = "overlay",
    virt_text = virt_text,
    virt_lines = virt_lines
  })

end

function Export.delete_hint()
  vim.api.nvim_buf_del_extmark(0, tabnine_ns, 1)
end

return Export
