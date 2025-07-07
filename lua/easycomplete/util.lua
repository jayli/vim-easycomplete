local util = {}
local zizz_flag = 0
local zizz_timer = vim.loop.new_timer()
local async_timer = vim.loop.new_timer()
local async_timer_counter = 0

function util.zizz()
  if zizz_flag > 0 then
    zizz_timer:stop()
    zizz_flag = 0
  end
  zizz_timer:start(30, 0, function()
    zizz_flag = 0
  end)
  zizz_flag = 1
end

function util.zizzing()
  if zizz_flag == 1 then
    return true
  else
    return false
  end
end

function util.get_servers()
  if not util.nvim_installer_installed() then
    return nil
  end
  local Servers = require("nvim-lsp-installer.servers")
  return Servers
end

function util.get_server()
  if not util.nvim_installer_installed() then
    return nil
  end
  local Server = require("nvim-lsp-installer.server")
  return Server
end

-- TODO 需要再测试一下这个函数
function util.get(a, ...)
  local args = {...}
  if type(a) ~= "table" then
    return a
  end
  local tmp_obj = a
  for i = 1, #args do
    tmp_obj = tmp_obj[args[i]]
    if tmp_obj == nil or type(tmp_obj) == nil then
      break
    end
  end
  return tmp_obj
end

-- get word or abbr
function util.get_word(a)
  local k = a.abbr
  if type(k) == nil or k == nil or k ~= "" then
    local k = a.word
  end
  return k
end

function util.isTN(item)
  local plugin_name = util.get_item_plugin_name(item)
  if plugin_name == "tn" then
    return true
  else
    return false
  end
end

function util.curr_lsp_constructor_calling()
  util.constructor_calling_by_name(util.current_plugin_name())
end

function util.show_success_message()
  vim.defer_fn(function()
    util.log("LSP is initalized successfully!")
  end, 100)
end

function util.get_configuration()
  local curr_lsp_name = util.current_lsp_name()
  local Servers       = util.get_servers()
  local Server        = util.get_server()
  local ok, server    = Servers.get_server(curr_lsp_name)
  return {
    easy_plugin_ctx      = util.current_plugin_ctx(),
    easy_plugin_name     = util.current_plugin_name(),
    easy_lsp_name        = curr_lsp_name,
    easy_lsp_config_path = util.get_default_config_path(),
    easy_cmd_full_path   = util.get_default_command_full_path(),
    nvim_lsp_root        = util.get(server, "root_dir"),
    nvim_lsp_root_path   = Server.get_server_root_path(),
    nvim_lsp_ok          = ok,
  }
end

-- 定义日志函数，日志写在 ~/debuglog 中
function util.debug(...)
  local args = {...}
  local homedir = os.getenv("HOME") or os.getenv("USERPROFILE")
  local filename = homedir .. "/debuglog"
  local file = io.open(filename, "w")
  if not file then
    print("无法创建或打开日志文件: ~/debuglog")
    return
  end
  -- 获取当前时间（可选）
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")

  local output_msg = ""
  for i, v in ipairs(args) do
    output_msg = output_msg .. " " .. vim.inspect(v)
  end
  -- 写入日志内容
  file:write(string.format("[%s]%s\n", timestamp, output_msg))
  -- 关闭文件
  file:close()
end

function util.constructor_calling_by_name(plugin_name)
  vim.fn['easycomplete#ConstructorCallingByName'](plugin_name)
end

function util.console(...)
  return vim.fn['easycomplete#log#log'](...)
end

function util.log(...)
  return vim.fn['easycomplete#util#info'](...)
end

function util.get_item_plugin_name(...)
  return vim.fn['easycomplete#util#GetPluginNameFromUserData'](...)
end

function util.current_plugin_ctx()
  return vim.fn['easycomplete#GetCurrentLspContext']()
end

function util.current_plugin_name()
  local curr_ctx = util.current_plugin_ctx()
  local plugin_name = util.get(curr_ctx, 'name')
  return plugin_name
end

function util.current_lsp_name()
  local curr_plugin_ctx = util.current_plugin_ctx()
  if curr_plugin_ctx.name == "ts" then
    return "tsserver"
  end
  local lsp_name = util.get(curr_plugin_ctx, "lsp", "name")
  return lsp_name
end

function util.get_default_lsp_root_path()
  local all_root = vim.fn['easycomplete#installer#LspServerDir']()
  local plugin_name = util.current_plugin_name()
  local root_path = vim.fn.join({
    all_root,
    plugin_name,
  }, "/")
  return root_path
end

function util.get_default_config_path()
  local lsp_root = util.get_default_lsp_root_path()
  local config_path = vim.fn.join({
    lsp_root,
    "config.json",
  }, "/")
  return config_path
end

function util.get_default_command_full_path()
  local curr_plugin_ctx   = util.current_plugin_ctx()
  local command_name      = util.get(curr_plugin_ctx, "command")
  local command_full_path = vim.fn.join({
    util.get_default_lsp_root_path(),
    command_name
  }, "/")
  return command_full_path
end

function util.nvim_installer_installed()
  return vim.g.loaded_nvim_lsp_installer
end

-- concat is a array
function util.create_command(file_path, content)
  if vim.fn.executable(file_path) then
    vim.fn.delete(file_path, "rf")
  end
  vim.fn.writefile(content, file_path, "a")
  vim.fn.setfperm(file_path, "rwxr-xr-x")
end

function util.create_config(file_path, content)
  if vim.fn.executable(file_path) then
    vim.fn.delete(file_path, "rf")
  end
  vim.fn.writefile(content, file_path, "a")
end

function util.nvim_lsp_installed()
  local current_lsp_ctx = util.current_plugin_ctx()
  local lsp_name = util.current_lsp_name()
  if not util.nvim_installer_installed() or type(lsp_name) == nil then
    return false
  end
  local Servers = util.get_servers()
  local install_list = Servers.get_installed_server_names()
  local flag = false
  for i = 1, #install_list do
    if lsp_name == install_list[i] then
      flag = true
      break
    end
  end
  return flag
end

function util.easy_lsp_installed()
  local plugin_name = vim.fn["easycomplete#util#GetLspPluginName"]()
  local current_lsp_ctx = util.current_plugin_ctx()
  local easy_available_command = vim.fn["easycomplete#installer#GetCommand"](plugin_name) 
  if plugin_name == "ts" and string.find(easy_available_command, "tsserver$") then
    return true
  end
  local easy_lsp_ready = util.get(current_lsp_ctx, "lsp", "ready")
  if easy_available_command ~= "" and easy_lsp_ready == true then
    return true
  else
    return false
  end
end

function util.async_run(func, args, timeout)
  async_timer:start(timeout, 0, function()
    if type(func) == "string" then
      -- 如果是字符串，则作为全局函数名调用
      local f = vim.fn[func]
      if type(f) == "function" then
        vim.schedule(function()
          local ok,err = pcall(f, unpack(args))
          if not ok then
            print("async_run调用失败:", err)
          end
        end)
      else
        vim.schedule(function()
          vim.notify("async_run: 全局函数不存在或不是函数: " .. func, vim.log.levels.ERROR)
        end)
      end
    elseif type(func) == "function" then
      -- 如果是函数对象，直接调用
      vim.schedule(function()
        local ok,err = pcall(func, unpack(args))
        if not ok then
          print("async_run调用失败:", err)
        end
      end)
    else
      -- print('------------', vim.inspect(func), args, timeout)
      vim.schedule(function()
        vim.notify("async_run: 无效的函数类型", func, vim.log.levels.ERROR)
      end)
    end
  end)
  return async_timer_counter + 1
end

function util.trim_before(str)
  if str == "" then return "" end
  return string.gsub(str, "^%s*(.-)$", "%1")
end

-- 判断一个list中是否包含某个字符串元素
function util.has_item(tb, it)
  if #tb == 0 then return false end
  local idx = vim.fn.index(tb, it)
  if idx == -1 then
    return false
  else
    return true
  end
end

function util.stop_async_run()
  async_timer:stop()
  async_timer_counter = 0
end

function util.defer_fn(func_name, args, timeout)
  if type(func_name) == "string" then
    -- 如果是字符串，则作为全局函数名调用
    local f = vim.fn[func_name]
    if type(f) == "function" then
      vim.defer_fn(function()
        vim.schedule(function()
          local ok, err = pcall(f, unpack(args))
          if not ok then
            print("defer_fn调用失败:", err)
          end
        end)
      end, timeout)
    else
      vim.schedule(function()
        vim.notify("defer_fn: 全局函数不存在或不是函数: " .. func_name, timeout, vim.log.levels.ERROR)
      end)
    end
  else
    vim.schedule(function()
      vim.notify("defer_fn: 传入参数不是字符串", vim.log.levels.ERROR)
    end)
  end
end

return util
