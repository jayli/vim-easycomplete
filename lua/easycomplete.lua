local debug = true
local EasyComplete = {}
local Util = require "easycomplete_util"
local console = vim.fn['easycomplete#log#log']
local log = vim.fn["easycomplete#util#info"]

-- all in all 入口
local function main()
  if not Util.nvim_installer_installed() then
    return
  end

  local filetype = vim.o.filetype
  local plugin_name = vim.fn["easycomplete#util#GetLspPluginName"]()
  local nvim_lsp_installer_root = vim.fn["easycomplete#util#NVimLspInstallRoot"]()
  local current_lsp_context =vim.fn["easycomplete#GetCurrentLspContext"]()
  local current_lsp_name = Util.get(current_lsp_context, "lsp_name")
  local nvim_lsp_ready = Util.nvim_lsp_installed(current_lsp_name)
  local easy_lsp_ready = Util.easy_lsp_installed(plugin_name)
  console(easy_lsp_ready, nvim_lsp_ready, current_lsp_name)

  if not easy_lsp_ready and nvim_lsp_ready then
    vim.cmd([[InstallLspServer]])
  end

  console('-------------')
  console(Util.get(current_lsp_context,'lsp'))
  console('-------------')
  console(Util.get(current_lsp_context, "lsp_name"))
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
  if vim.api.nvim_get_var('easycomplete_kindflag_buf') == "羅" and debug == true then
    main()
  else
    return
  end
end

return EasyComplete
