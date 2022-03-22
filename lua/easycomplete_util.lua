
local Util = {}
Util.console = vim.fn['easycomplete#log#log']

function Util.get(a, ...)
  local args = {...}
  if type(a) ~= "table" then
    return a
  end
  local tmp_obj = a
  for i = 1, #args do
    tmp_obj = tmp_obj[args[i]]
    if type(tmp_obj) == nil then
      break
    end
  end
  return tmp_obj
end

function Util.current_plugin_name()
  local curr_ctx = vim.fn['easycomplete#GetCurrentLspContext']()
  local plugin_name = Util.get(curr_ctx, 'name')
  return plugin_name
end

function Util.nvim_installer_installed()
  return vim.g.loaded_nvim_lsp_installer
end

function Util.nvim_lsp_installed()
  local current_lsp_ctx =vim.fn["easycomplete#GetCurrentLspContext"]()
  local lsp_name = Util.get(current_lsp_ctx, "lsp", "name")
  if not Util.nvim_installer_installed() or type(lsp_name) == nil then
    return false
  end
  local install_list = require'nvim-lsp-installer.servers'.get_installed_server_names()
  local flag = false
  for i = 1, #install_list do
    if lsp_name == install_list[i] then
      flag = true
      break
    end
  end
  return flag
end

function Util.easy_lsp_installed()
  local plugin_name = vim.fn["easycomplete#util#GetLspPluginName"]()
  local current_lsp_ctx =vim.fn["easycomplete#GetCurrentLspContext"]()
  local easy_available_command = vim.fn["easycomplete#installer#GetCommand"](plugin_name) 
  local easy_lsp_ready = Util.get(current_lsp_ctx, "lsp", "ready")
  if easy_available_command ~= "" and easy_lsp_ready == true then
    return true
  else
    return false
  end
end

return Util
