local Util = require "easycomplete.util"
local Servers = require("nvim-lsp-installer.servers")
local Server  = require("nvim-lsp-installer.server")
local console = Util.console
local log = Util.log
local AutoLoad = {}

local function get_configuration()
  local curr_lsp_name = Util.current_lsp_name()
  local ok, server = Servers.get_server(curr_lsp_name)
  return {
    easy_plugin_ctx = Util.current_plugin_ctx(),
    easy_plugin_name = Util.current_plugin_name(),
    easy_lsp_name = curr_lsp_name,
    easy_lsp_config_path = Util.get_default_config_path(),
    easy_cmd_full_path = Util.get_default_command_full_path(),
    nvim_lsp_root = Util.get(server, "root_dir"),
    nvim_lsp_root_path = Server.get_server_root_path(),
    nvim_lsp_ok = ok,
  }
end

local function curr_lsp_constructor_calling()
  Util.constructor_calling_by_name(Util.current_plugin_name())
end

local function show_success_message()
  vim.defer_fn(function()
    log("LSP is initalized successfully!")
  end, 100)
end

AutoLoad.html = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'vscode-html-language-server'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.css = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'vscode-css-language-server'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

-- Not tested
AutoLoad.cpp = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'bin',
      'clangd',
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.vim = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'vim-language-server'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.deno = {
  setup = function(self)
    local configuration = get_configuration()
    if not configuration.nvim_lsp_ok then
      return
    end
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'deno'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.ts = {
  setup = function(self) 
    local configuration = get_configuration()
    if not configuration.nvim_lsp_ok then
      return
    end
    local tsserver_js_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      'typescript',
      'lib',
      'tsserver.js'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env node",
      "require('" .. tsserver_js_path .. "')",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.lua = {
  setup = function(self)
    local curr_plugin_ctx = Util.current_plugin_ctx()
    local plugin_name = Util.current_plugin_name()
    local curr_lsp_name = Util.current_lsp_name()
    local ok, server = Servers.get_server(curr_lsp_name)
    if not ok then
      return
    end

    local lua_config_path = Util.get_default_config_path()
    local lua_cmd_full_path = Util.get_default_command_full_path()
    local nvim_lsp_root = Util.get(server, "root_dir")
    local nvim_cmd_path = vim.fn.join({nvim_lsp_root, "extension", "server", "bin"}, "/")
    local nvim_cmd_bin = "lua-language-server"
    local nvim_lua_script = "main.lua"
    local full_cmd_str = vim.fn.join({
      nvim_cmd_path .. "/" .. nvim_cmd_bin,
      "-E",
      "-e",
      "LANG=en",
      nvim_cmd_path .. "/" .. nvim_lua_script,
      "--configpath=" .. lua_config_path
    }, " ")

    Util.create_command(lua_cmd_full_path, {
      "#!/usr/bin/env bash",
      full_cmd_str .. " $*",
    })
    Util.create_config(lua_config_path, {
      '{',
      '  "Lua": {',
      '    "workspace.library": {',
      '      "/usr/share/nvim/runtime/lua": true,',
      '      "/usr/share/nvim/runtime/lua/vim": true,',
      '      "/usr/share/nvim/runtime/lua/vim/lsp": true',
      '    },',
      '    "diagnostics": {',
      '      "globals": [ "vim", "use", "use_rocks"]',
      '    }',
      '  },',
      '  "sumneko-lua.enableNvimLuaDev": true',
      '}',
    })

    curr_lsp_constructor_calling()
    show_success_message()
  end
}

function AutoLoad.get(plugin_name)
  return Util.get(AutoLoad, plugin_name)
end

return AutoLoad
