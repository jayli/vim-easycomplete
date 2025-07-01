local Util = require "easycomplete.util"
local log = Util.log
local console = Util.console
local normal_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRST0123456789#$_"
local M = {}

function pum_complete()
  print(get_typing_word())
  local word = get_typing_word()
  local t = {
    {
      word = "s",
      abbr = word,
      kind = "x",
      menu = "x"
    },
    {
      word = "abcd",
      abbr = "abcd",
      kind = "x",
      menu = "x"
    }
  }
  local start_col = vim.fn.getcmdpos() - calculate_sign_and_linenr_width() - #word
  vim.fn["easycomplete#pum#complete"](start_col, t)
end

function pum_close()
  vim.fn["easycomplete#pum#close"]()
end

function get_typing_word()
  -- 获取当前行的文本
  local current_line = string.sub(vim.fn.getcmdline(),1,vim.fn.getcmdpos())

  -- 使用 gmatch 迭代所有单词（假设单词由空格分隔）
  local last_word = ""
  for word in string.gmatch(current_line, "[%w%-]+") do
    last_word = word
  end

  return last_word
end

function calculate_sign_and_linenr_width()
  local width = 0

  -- 检查是否有 sign 列
  local signcolumn = vim.api.nvim_win_get_option(0, "signcolumn")
  if signcolumn == "yes" or signcolumn == "auto" or signcolumn == "number" then
    width = width + 2 -- sign 列通常占据 2 个字符宽度
  end

  -- 检查是否显示行号
  if vim.wo.number or vim.wo.relativenumber then
    -- 计算行号的最大宽度
    local max_num_width = #tostring(vim.fn.line("$"))
    width = width + max_num_width + 1 -- 加 1 是为了考虑空隙或者额外的字符
  end

  return width
end

local function bind_cmdline_event()
  vim.on_key(function(keys, _)
    -- 这里不论是否是插入模式，都会触发，需要过滤掉
    if vim.api.nvim_get_mode().mode ~= "c" then
      return
    end
    -- 将按键字节序列转换为字符串
    local key_str = vim.api.nvim_replace_termcodes(keys, true, false, true)

    vim.defer_fn(function()
      pum_complete()
      console(string.byte(key_str))
      if string.byte(key_str) == 9 then
        console("Tab 键被按下")
      elseif string.byte(key_str) == 32 then
        console("空格键被按下")
        pum_close()
      elseif string.byte(key_str) == 8 or string.byte(key_str) == 128 then
        console("退格键被按下")
      elseif string.byte(key_str) == 13 then
        console("回车键被按下")
      else
        console("其他键被按下: " .. keys)
      end
      -- console(key_str)
      vim.cmd("redraw")
      -- vim.fn["easycomplete#CmdlineChanged"](key_str)
    end, 10)
  end)
end


function M.init_once()
  -- TODO here -----------------------------
  if true then return end
  -- TODO here -----------------------------
  if vim.g.easycomplete_cmdline_loaded == 1 then
    return
  end
  vim.g.easycomplete_cmdline_loaded = 1
  bind_cmdline_event()
end


return M
