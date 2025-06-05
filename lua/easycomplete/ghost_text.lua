local M = {}
local hint_ns = vim.api.nvim_create_namespace('hint_ns')

function M.init()
  M.init_hl()
  vim.api.nvim_create_autocmd({"ColorScheme"}, {
    pattern = {"*"},
    callback = function()
      M.init_hl()
    end
  })
end

function M.init_hl()
  local cursorline_bg = vim.fn["easycomplete#ui#GetBgColor"]("CursorLine")
  local normal_bg = vim.fn["easycomplete#ui#GetBgColor"]("Normal")
  local linenr_fg = vim.fn["easycomplete#ui#GetFgColor"]("LineNr")
  if vim.fn.matchstr(cursorline_bg, "^\\d\\+") ~= "" then
    cursorline_bg = vim.fn.str2nr(cursorline_bg)
  end
  if vim.fn.matchstr(normal_bg, "^\\d\\+") ~= "" then
    normal_bg = vim.fn.str2nr(normal_bg)
  end
  if vim.fn.matchstr(linenr_fg, "^\\d\\+") ~= "" then
    linenr_fg = vim.fn.str2nr(linenr_fg)
  end

  vim.api.nvim_set_hl(0, "HintFirstLine", {
    bg = cursorline_bg,
    fg = linenr_fg
  })
  vim.api.nvim_set_hl(0, "HintNoneFirstLine", {
    fg = linenr_fg,
    bg = normal_bg
  })
end

-- code_block 是一个字符串，有可能包含回车符
-- call v:lua.require("copilot").show_hint()
-- code_block 是数组类型
function M.show_hint(code_block)
  local lines = {}
  local count = 1
  local code_lines = code_block
  for key, line in pairs(code_lines) do
    local highlight_group = ""
    if count == 1 then
      highlight_group = "HintFirstLine"
    else
      highlight_group = "HintNoneFirstLine"
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

  vim.api.nvim_buf_set_extmark(0, hint_ns, vim.fn.line('.') - 1, vim.fn.col('.') - 1, {
    id = 1,
    virt_text_pos = "overlay",
    virt_text = virt_text,
    virt_lines = virt_lines
  })
end

function M.delete_hint()
  vim.api.nvim_buf_del_extmark(0, hint_ns, 1)
end

return M
