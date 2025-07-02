local Util = require "easycomplete.util"
local log = Util.log
local console = Util.console
local normal_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRST0123456789#$_"
-- cmdline_start_cmdpos 是不带偏移量的，偏移量只给 pum 定位用
local cmdline_start_cmdpos = 0
local zizz_flag = 0
local zizz_timer = vim.loop.new_timer()
local M = {}

function pum_complete(start_col, menu_items)
  vim.fn["easycomplete#pum#complete"](start_col, menu_items)
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

function flush()
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  cmdline_start_cmdpos = 0
  pum_close()
end

function pum_selected()
  return vim.fn['easycomplete#pum#CompleteCursored']()
end

function pum_selected_item()
  return vim.fn['easycomplete#pum#CursoredItem']()
end

function M.select_next()
  vim.fn['easycomplete#pum#next']()
  zizz()
  local backing_count = vim.fn.getcmdpos() - cmdline_start_cmdpos
  local oprator_str = string.rep("\b", backing_count)
  local new_whole_word = ""
  if pum_selected() then
    local item = pum_selected_item()
    local word = item.word
    new_whole_word = oprator_str .. word
  else
    new_whole_word = oprator_str
  end
  return new_whole_word
end

function M.select_prev()
  vim.fn['easycomplete#pum#prev']()
  zizz()
end

local function bind_cmdline_event()
  local augroup = vim.api.nvim_create_augroup('CustomCmdlineComplete', { clear = true })

  vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = augroup,
      pattern = ":",
      callback = function()
        vim.g.easycomplete_cmdline_pattern = ":"
      end,
    })
  vim.api.nvim_create_autocmd("CmdlineEnter", {
      group = augroup,
      pattern = "/",
      callback = function()
        vim.g.easycomplete_cmdline_pattern = "/"
      end,
    })
  vim.cmd [[
    cnoremap <expr> <Tab> v:lua.require("easycomplete.cmdline").select_next()
    cnoremap <expr> <S-Tab> v:lua.require("easycomplete.cmdline").select_prev()
  ]]
  vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = augroup,
      callback = function()
        flush()
      end
    })
  vim.on_key(function(keys, _)
    if vim.api.nvim_get_mode().mode ~= "c" then
      return
    end
    local key_str = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.g.easycomplete_cmdline_typing = 1
    vim.defer_fn(function()
      vim.schedule(function()
        local ok, ret = pcall(cmdline_handler, keys, key_str)
        if not ok then
          print(ret)
        end
      end)
    end, 10)
  end)
end

function normalize_list(arr)
  if #arr == 0 then return arr end
  local ret = {}
  for index, value in ipairs(arr) do
    table.insert(ret, {
        word = arr[index],
        abbr = arr[index],
        kind = vim.g.easycomplete_kindflag_cmdline,
        menu = vim.g.easycomplete_menuflag_cmdline
      })
  end
  return ret
end

function cmdline_handler(keys, key_str)
  if vim.g.easycomplete_cmdline_pattern == "" then
    return
  end
  if zizzing() then return end
  local cmdline = vim.fn.getcmdline()
  cmdline_start_cmdpos = 0
  if string.byte(key_str) == 9 then
    console("Tab 键被按下")
  elseif string.byte(key_str) == 32 then
    console("空格键被按下")
    pum_close()
  elseif string.byte(key_str) == 8 or string.byte(key_str) == 128 then
    console("退格键被按下")
    pum_close()
  elseif string.byte(key_str) == 13 then
    console("回车键被按下")
    pum_close()
  else
    console("其他键被按下: " .. keys)
    local word = get_typing_word()
    local menu_items = vim.fn.getcompletion(word, "cmdline")
    local start_col = vim.fn.getcmdpos() - calculate_sign_and_linenr_width() - #word
    cmdline_start_cmdpos = vim.fn.getcmdpos() - #word
    pum_complete(start_col, normalize_list(menu_items))
  end
  vim.cmd("redraw")
end

function zizz()
  if zizz_flag > 0 then
    zizz_timer:stop()
    zizz_flag = 0
  end
  zizz_timer:start(30, 0, function()
    zizz_flag = 0
  end)
  zizz_flag = 1
end

function zizzing()
  if zizz_flag == 1 then
    return true
  else
    return false
  end
end


function M.init_once()
  -- TODO here -----------------------------
  if true then return end
  console(1)
  -- TODO here -----------------------------
  vim.g.easycomplete_cmdline_pattern = ""
  vim.g.easycomplete_cmdline_typing = 0
  bind_cmdline_event()
end


return M
