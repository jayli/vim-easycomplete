local Util = require "easycomplete.util"
local log = Util.log
local console = Util.console
local normal_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRST0123456789#$_"
local global_ghost_tx_ns = vim.api.nvim_create_namespace('global_ghost_tx_ns')
local M = {}

function M.nvim_init_ghost_hl()
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

-- code_block 是一个字符串，有可能包含回车符
-- call v:lua.require("easycomplete.ghost_text").show_hint()
-- code_block 是数组类型
function M.show_hint(code_block)
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
    -- virt_text_win_col = vim.fn.virtcol('.') - 1
  }
  -- 用virt_text_win_col 来防止抖动
  if is_cursor_at_EOL() then
    opt.virt_text_win_col = vim.fn.virtcol('.') - 1
  end

  vim.api.nvim_buf_set_extmark(0, global_ghost_tx_ns, vim.fn.line('.') - 1, vim.fn.col('.') - 1, opt)
end

local function onkey_event_prevented()
  if vim.g.easycomplete_onkey_event == nil or vim.g.easycomplete_onkey_event == 0 then
    return true
  else
    return false
  end
end

local function ghost_text_bind_event()
  if not vim.g.easycomplete_ghost_text then
    return
  end
  local curr_key = nil
  -- 注册按键监听器
  vim.on_key(function(keys, _)
    -- 这里不论是否是插入模式，都会触发，需要过滤掉
    if vim.api.nvim_get_mode().mode ~= "i" then
      return
    end
    if onkey_event_prevented() then
      return
    end
    -- 将按键字节序列转换为字符串
    local key_str = vim.api.nvim_replace_termcodes(keys, true, false, true)
    -- 更新 last_key 变量
    curr_key = key_str
    -- console('on_key', string.byte(curr_key))
    do
      ------{{ ghost_handler --------------------------------
      -- 这里的作用是输入过程中处理 ghost_text 的占位，封装到函数中
      -- 就会有闪烁, 原因未知
      if vim.api.nvim_get_mode().mode ~= "i" then
        return
      end
      if onkey_event_prevented() then
        return
      end
      if curr_key == nil or string.byte(curr_key) == nil then
        return
      end
      -- console("输入字符" .. vim.inspect(string.byte(curr_key)))
      if curr_key and string.find(normal_chars, curr_key, 1, true) then
        -- 正常输入
        if vim.fn["easycomplete#pum#visible"]() then
          local ok, err = pcall(function()
            local ghost_text = get_current_extmark()
            if ghost_text == "" or #ghost_text == 1 then
              M.delete_hint()
              vim.g.easycomplete_ghost_text_str = ""
            elseif #ghost_text >= 2 then
              local new_ghost_text = string.sub(ghost_text, 2)
              M.show_hint({new_ghost_text})
              vim.g.easycomplete_ghost_text_str = new_ghost_text
            end
          end)
          if not ok then
            print("Ghost Text Error: " .. err)
          end
        end
      elseif curr_key and string.byte(curr_key) == 8 then
        -- 退格键
        if vim.fn["easycomplete#pum#visible"]() then
          local ok, err = pcall(function()
            local ghost_text = get_current_extmark()
            if ghost_text == "" then
              -- M.delete_hint()
              vim.g.easycomplete_ghost_text_str = ""
            elseif #ghost_text >= 1 then
              local new_ghost_text = "a" .. ghost_text
              M.show_hint({new_ghost_text})
              vim.g.easycomplete_ghost_text_str = new_ghost_text
            end
          end)
          if not ok then
            print("Ghost Text Error BackSpace " .. err)
          end
        else
          M.delete_hint()
          vim.g.easycomplete_ghost_text_str = ""
        end
      else
        -- 其他字符
      end
      curr_key = nil
      ------}} ghost_handler --------------------------------
    end -- end do
  end)
  vim.api.nvim_create_autocmd({"CursorMovedI"}, {
      pattern = "*",
      callback = function()
      end,
    })
end

function M.init_once()
  if vim.g.easycomplete_ghost_txt_tmp_ready == 1 then
    return
  end
  vim.g.easycomplete_ghost_txt_tmp_ready = 1
  ghost_text_bind_event()
end


function get_current_extmark()
  local row = vim.fn.line('.') - 1
  local mks = vim.api.nvim_buf_get_extmarks(0, global_ghost_tx_ns, { row, 0 }, { row, -1 }, {
    details = true,
  })
  local mk_text = ""
  if not mks or #mks == 0 then
    return ""
  end
  for _, mark in ipairs(mks) do
    local info = mark[4]
    if info.virt_text and #info.virt_text > 0 then
      mk_text = info.virt_text[1][1]
    end
  end
  return mk_text
end

function is_cursor_at_EOL()
  -- 获取当前窗口的光标位置 (返回值为 {行号, 列号})
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- 行号从0开始计数，所以减1
  local col = cursor[2]

  -- 获取当前行的文本
  local lines = vim.api.nvim_buf_get_lines(0, row, row + 1, false)
  if #lines == 0 then return true end  -- 如果没有获取到行，则认为是在行尾

  local line = lines[1]
  line = line:gsub("%s*$", "")

  -- 检查光标位置是否等于或超过行的长度
  if col >= #line then
    -- 光标位于行末或者超出行末
    return true
  else
    -- 光标不在行末
    return false
  end
end

function M.delete_hint()
  vim.api.nvim_buf_del_extmark(0, global_ghost_tx_ns, 1)
end

return M
