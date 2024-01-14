-- local debug = true
local EasyComplete = {}
local Util = require "easycomplete.util"
local AutoLoad = require "easycomplete.autoload"
local TabNine = require "easycomplete.tabnine"
local console = Util.console
local log = Util.log

local function test()
  console(vim.inspect(Util))
  console(replaceCharacters("XMLDocument", {0,1,7}, "*"))

  do
    return
  end

  console('-------------')
  console(Util.get(current_lsp_ctx,'lsp'))
  console('-------------')
  console(Util.get(current_lsp_ctx, "lsp_name"))
  console(require'nvim-lsp-installer.servers'.get_installed_server_names())
  console(require'nvim-lsp-installer'.get_install_completion())

  -- vim.cmd([[
  --   autocmd TextChangedI * lua require("easycomplete").typing()
  -- ]])
  -- console(1,1,2,9, "sdf")
  -- console('------------------------')
  -- console('xcv')
  -- console(table)
  -- foo()
  -- console("=================================")
  -- vim.cmd([[
  --   autocmd CompleteChanged * lua require("easycomplete").complete_changed()
  -- ]])
end

-- all in all 入口
local function nvim_lsp_handler()
  TabNine.init()

  if not Util.nvim_installer_installed() then
    return
  end

  local filetype = vim.o.filetype
  local plugin_name = Util.current_plugin_name()
  local nvim_lsp_ready = Util.nvim_lsp_installed()
  local easy_lsp_ready = Util.easy_lsp_installed()

  if not easy_lsp_ready and nvim_lsp_ready then
    local AutoLoad_script = AutoLoad.get(plugin_name)
    if type(AutoLoad_script) == nil or AutoLoad_script == nil then
      return
    else
      AutoLoad_script:setup()
    end
  end
end

function EasyComplete.complete_changed()
  console('--',Util.get(vim.v.event, "completed_item", "user_data"))
end

function EasyComplete.typing(...)
  local ctx = vim.fn['easycomplete#context']()
  print({
    console(vim.v.event)
  })

  print({
    pcall(function()
      console { aaa = 123 , bb = 456 }
      local aaa = vim.api.nvim_command("echo g:easycomplete_default_plugin_init")
    end)
  })
end

function foo()
  vim.api.nvim_command("echom 123")
  vim.fn["easycomplete#lua#api"]()
  vim.fn["easycomplete#lua#test"]()
  console(1,2,3,4,5,6)
  for i=1,80 do
    console(math.random())
  end
  console('>>---------------')
end

-- for nvim only
function EasyComplete.lsp_handler()
  nvim_lsp_handler()
  if vim.api.nvim_get_var('easycomplete_kindflag_buf') == "羅" and debug == true then
    test()
  else
    return
  end
end

function EasyComplete.normalize_sort(items)
  table.sort(items, function(a1, a2)
    local k1 = Util.get_word(a1)
    local l1 = #k1
    local k2 = Util.get_word(a2)
    local l2 = #k2
    return l1 > l2
  end)

  table.sort(items, function(a1, a2)
    local k1 = Util.get_word(a1)
    local k2 = Util.get_word(a2)
    return k1 > k2
  end)
  return items
end


function EasyComplete.distinct(items)
  local unique_values = {}
  local result = {}
  table.sort(items)
  for _, value in ipairs(items) do
    if #value == 0 or #value == 1 then
      -- 空字符串，一个长度的字符
      -- continue
    elseif tonumber(value:sub(1,1)) ~= nil then
      -- 首字符是数字
      -- continue
    elseif not unique_values[value] then
      unique_values[value] = true
      table.insert(result, value)
    end
  end
  return result
end

-- 返回去重之后的列表
function EasyComplete.get_buf_keywords(lines)
  local buf_keywords = {}
  for _, line in ipairs(lines) do
    for word in line:gmatch("[0-9a-zA-Z_#]+") do
      table.insert(buf_keywords, word)
    end
  end
  return buf_keywords
end

-- 一个单词的 fuzzy 比对
function EasyComplete.fuzzy_search(needle, haystack)
  if #needle > #haystack then
    return false
  end
  local needle = string.lower(needle)
  local haystack = string.lower(haystack)
  if #needle == #haystack then
    if needle == haystack then
      return true
    else
      return false
    end
  end
  -- string.find("easycomplete#context","[0-9a-z#]*z[0-9a-z#]*t[0-9a-z#_]*")
  -- string.gsub("easy", "(.)", "-%1")
  local middle_regx = "[0-9a-z#_]*"
  local needle_ls_regx = string.gsub(needle, "(.)", middle_regx .. "%1") .. middle_regx
  if string.find(haystack, needle_ls_regx) ~= nil then
    return true
  else
    return false
  end
end

-- vim.fn.matchfuzzy 的重新实现，只返回结果，不返回分数
function EasyComplete.matchfuzzy(match_list, needle)
  local result = {}
  for _, item in ipairs(match_list) do
    if EasyComplete.fuzzy_search(needle, item) then
      table.insert(result, item)
    end
  end
  return result
end

return EasyComplete
