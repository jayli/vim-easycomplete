-- local debug = true
local EasyComplete = {}
local Util = require "easycomplete.util"
local AutoLoad = require "easycomplete.autoload"
local console = Util.console
local log = Util.log

local function nvim_init_hl()
  vim.api.nvim_set_hl(0, "TabNineSuggestion", {
    link = "LineNr",
    bg = "none",
  })
  vim.api.nvim_set_hl(0, "TabNineSuggestion", {
    link = "CursorLine",
    fg = "none",
  })
end

-- all in all 入口
local function nvim_lsp_handler()
  -- nvim_init_hl()

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

local function test()
  -- console(vim.inspect(Util))
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

return EasyComplete
