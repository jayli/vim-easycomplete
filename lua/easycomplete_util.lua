
local Util = {}

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

function Util.nvim_installer_installed()
  return vim.g.loaded_nvim_lsp_installer
end

function Util.nvim_lsp_installed(lsp_name)
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

function Util.easy_lsp_installed(plugin_name)
  if vim.fn["easycomplete#installer#GetCommand"](plugin_name) ~= "" then
    return true
  else
    return false
  end
end




return Util
