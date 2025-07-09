-- local debug = true
local EasyComplete = {}
local Util = require "easycomplete.util"
local AutoLoad = require "easycomplete.autoload"
local console = Util.console
local log = Util.log
local global_timer = vim.loop.new_timer()
local global_timer_counter = 1

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
end

-- all in all 入口
-- 每次进入 buf 时执行
local function nvim_lsp_handler()
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

function EasyComplete.setup(config)
  for key, value in pairs(config) do
    vim.g["easycomplete_" .. key] = value
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

-- 执行每个模块里的 init_once 方法
function EasyComplete.load_mojo(mojos)
  if vim.g.easycomplete_lua_mojos_loaded == 1 then
    return
  end
  vim.g.easycomplete_lua_mojos_loaded = 1
  for i, mojo in ipairs(mojos) do
    local mojo_name = "easycomplete." .. mojo
    local Mo = require(mojo_name)
    Mo.init_once()
  end
end

-- 初始化入口
function EasyComplete.init()
  EasyComplete.load_mojo({"autocmd", "tabnine", "ghost_text", "luasnip", "cmdline"})

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


-- 字符串组成的数组
function EasyComplete.distinct(items)
  return Util.distinct(items)
end

-- 返回去重之后的列表
function EasyComplete.get_buf_keywords(lines)
  local buf_keywords = {}
  for _, line in ipairs(lines) do
    if vim.bo.filetype == "lua" then
      for word in line:gmatch("[0-9a-zA-Z_]+") do
        table.insert(buf_keywords, word)
      end
    else
      for word in line:gmatch("[0-9a-zA-Z_#]+") do
        table.insert(buf_keywords, word)
      end
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
  local needle_ls_regx = string.gsub(needle, "(.)", "%1" .. middle_regx)
  local idx = string.find(haystack, needle_ls_regx)
  if idx ~= nil and idx <= 2 then
    return true
  else
    return false
  end
end

-- vim.fn.matchfuzzy 的重新实现，只返回结果，不返回分数
function EasyComplete.matchfuzzy_and_filter(match_list, needle)
  local result = {}
  for _, item in ipairs(match_list) do
    if EasyComplete.fuzzy_search(needle, item) then
      table.insert(result, item)
    end
  end
  return result
end

function EasyComplete.filter(match_list, needle)
  local result = {}
  for _, item in ipairs(match_list) do
    if #item < #needle then
      -- pass
      goto continue
    elseif item == needle then
      -- pass
      table.insert(result, item)
      goto continue
    end
    local idx = string.find(string.lower(item), "" .. string.lower(needle))
    if type(idx) == type(2) and idx <= 3 then
      table.insert(result, item)
    end
    ::continue::
  end
  return result
end

-- 假设 s:GetItemWord(item) 在 Lua 中对应 item.word
local function get_item_word(item)
  return item.word or ""
end

-- Firstcomplete 中调用
function EasyComplete.distinct_keywords(menu_list)
  if not menu_list or #menu_list == 0 then
    return {}
  end

  local result_items = menu_list
  local buf_list = {}

  -- 第一步：收集所有来自 'buf' 的 word
  for _, item in ipairs(menu_list) do
    local plugin_name = item.plugin_name or ""
    if plugin_name == "buf" then
      table.insert(buf_list, item.word)
    end
  end

  -- 第二步：如果 word 被 buf 包含，且是 buf 类型，则从结果中移除
  for _, item in ipairs(menu_list) do
    local plugin_name = item.plugin_name or ""
    if plugin_name == "buf" or plugin_name == "snips" then
      goto continue
    end

    local word = get_item_word(item)
    if vim.tbl_contains(buf_list, word) then
      -- 过滤掉 result_items 中 plugin_name == "buf" 且 word 相同的项
      for i = #result_items, 1, -1 do
        local it = result_items[i]
        if (it.plugin_name == "buf") and (it.word == word) then
          table.remove(result_items, i)
        end
      end
    end
    ::continue::
  end
  return result_items
end

-- 判断 diagnostics 中是否已经包含 item（根据 sortNumber）
function EasyComplete.has(diagnostics, item)
  local item_sort = item.sortNumber
  if not item_sort then return false end

  for _, elem in ipairs(diagnostics) do
    if elem.sortNumber == item_sort then
      return true
    end
  end

  return false
end

-- 对 diagnostics 列表进行去重
function EasyComplete.sign_distinct(diagnostics)
  if not diagnostics or #diagnostics == 0 then
    return {}
  end

  local ret = {}
  for _, item in ipairs(diagnostics) do
    if not EasyComplete.has(ret, item) then
      table.insert(ret, item)
    end
  end

  return ret
end

function EasyComplete.replacement(abbr, positions, wrap_char)
  -- 转换为字符数组（字符串 -> 字符表）
  local letters = {}
  for i = 1, #abbr do
    letters[i] = abbr:sub(i, i)
  end
  -- 对每个位置进行包裹处理
  for _, idx in ipairs(positions) do
    if idx >= 0 and idx < #letters then
      letters[idx+1] = wrap_char .. letters[idx+1] .. wrap_char
    end
  end
  -- 合并成新字符串
  local res_o = table.concat(letters)
  local res_r = string.gsub(res_o, "%" .. wrap_char .. "%" .. wrap_char, "")
  return res_r
end

function EasyComplete.global_timer_start(function_name, timeout)
  global_timer:start(timeout, 0, function()
    vim.schedule(function()
      vim.fn[function_name]()
    end)
  end)
end

function EasyComplete.global_timer_stop()
  global_timer:stop()
end

return EasyComplete
