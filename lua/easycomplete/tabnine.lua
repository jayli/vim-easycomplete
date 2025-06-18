local Util = require "easycomplete.util"
local loading = require "easycomplete.loading"
local log = Util.log
local console = Util.console
local Export = {}
local tabnine_ns = vim.api.nvim_create_namespace('tabnine_ns')

function Export.nvim_init_tabnine_hl()
  local cursorline_bg = vim.fn["easycomplete#ui#GetBgColor"]("CursorLine")
  local normal_bg = vim.fn["easycomplete#ui#GetBgColor"]("Normal")
  local linenr_fg = vim.fn["easycomplete#ui#GetFgColor"]("LineNr")

  local snippet_fg = ""
  if vim.fn["easycomplete#ui#HighlightGroupExists"]("EasySnippets") then
    snippet_fg = vim.fn["easycomplete#ui#GetFgColor"]("EasySnippets")
  else
    snippet_fg = linenr_fg
  end

  if vim.fn.matchstr(cursorline_bg, "^\\d\\+") ~= "" then
    cursorline_bg = vim.fn.str2nr(cursorline_bg)
  end
  if vim.fn.matchstr(normal_bg, "^\\d\\+") ~= "" then
    normal_bg = vim.fn.str2nr(normal_bg)
  end
  if vim.fn.matchstr(snippet_fg, "^\\d\\+") ~= "" then
    snippet_fg = vim.fn.str2nr(snippet_fg)
  end

  vim.api.nvim_set_hl(0, "TabNineSuggestionFirstLine", {
    bg = cursorline_bg,
    fg = snippet_fg
  })
  vim.api.nvim_set_hl(0, "TabNineSuggestionNoneFirstLine", {
    fg = snippet_fg,
    bg = normal_bg
  })
end

function Export.init()
  Export.nvim_init_tabnine_hl()
  vim.api.nvim_create_autocmd({"ColorScheme"}, {
    pattern = {"*"},
    callback = function()
      Export.nvim_init_tabnine_hl()
    end
  })
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

  local opt = {
    id = 1,
    virt_text_pos = "inline",
    virt_text = virt_text,
    virt_lines = virt_lines,
  }
  -- 用virt_text_win_col 来防止抖动
  if Export.is_cursor_at_EOL() then
    opt.virt_text_win_col = vim.fn.col('.') - 1
  end

  vim.api.nvim_buf_set_extmark(0, tabnine_ns, vim.fn.line('.') - 1, vim.fn.col('.') - 1, opt)
end

function Export.is_cursor_at_EOL()
  -- 获取当前窗口的光标位置 (返回值为 {行号, 列号})
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- 行号从0开始计数，所以减1
  local col = cursor[2]

  -- 获取当前行的文本
  local lines = vim.api.nvim_buf_get_lines(0, row, row + 1, false)
  if #lines == 0 then return true end  -- 如果没有获取到行，则认为是在行尾

  local line = vim.fn.trim(lines[1])

  -- 检查光标位置是否等于或超过行的长度
  if col >= #line then
    -- 光标位于行末或者超出行末
    return true
  else
    -- 光标不在行末
    return false
  end
end

function Export.loading_start()
  loading.start()
end

function Export.loading_stop()
  loading.stop()
end

function Export.delete_hint()
  vim.api.nvim_buf_del_extmark(0, tabnine_ns, 1)
end

return Export
