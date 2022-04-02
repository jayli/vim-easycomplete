local Util = require "easycomplete.util"
local console = Util.console
local log = Util.log
local AutoLoad = {}
local get_configuration = Util.get_configuration
local show_success_message = Util.show_success_message
local curr_lsp_constructor_calling = Util.curr_lsp_constructor_calling

AutoLoad.grvy = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'build',
      'libs',
      'groovyls-all.jar'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      'java -jar ' .. cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.kt = {
  setup = function(self)
    local configuration = get_configuration()
    local command = 'kotlin-language-server'
    if vim.fn.has('win32') or vim.fn.has('win64') then
      local command = command .. '.bat'
    end
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'server',
      'bin',
      command
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.rust = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'rust-analyzer',
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.nim = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'nimlsp',
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

-- DIR/Gemfile 的引用位置对了，但lsp不生效
-- AutoLoad.rb = {
--   setup = function(self)
--     local configuration = get_configuration()
--     local gemfile = vim.fn.join({
--       configuration.nvim_lsp_root,
--       "gems/solargraph-0.44.3/Gemfile"
--     }, "/")
--     local solargraph_path = vim.fn.join({
--       configuration.nvim_lsp_root,
--       "bin",
--       "solargraph"
--     }, "/")
--     -- BUNDLE_GEMFILE=$DIR/Gemfile bundle exec ruby $DIR/bin/solargraph $*
--     Util.create_command(configuration.easy_cmd_full_path, {
--       "#!/usr/bin/env sh",
--       vim.fn.join({"BUNDLE_GEMFILE=" .. gemfile,
--         "bundle",
--         "exec",
--         "ruby",
--         solargraph_path,
--         "$*"
--       }, " ")
--     })
--     curr_lsp_constructor_calling()
--     show_success_message()
--   end
-- }

AutoLoad.go = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'gopls',
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.py = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'venv',
      'bin',
      'pylsp'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.dart = {
  setup = function(self)
    if not vim.fn.executable('dart') then
      return
    end
    local configuration = get_configuration()
    local dart_bin = vim.fn.resolve(vim.fn.exepath('dart'))
    local dart_bin_dir = vim.fn.fnamemodify(dart_bin, ':h')
    local snapshots = vim.fn.join({
      dart_bin_dir,
      "snapshots",
      "analysis_server.dart.snapshot"
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      vim.fn.join({
        dart_bin,
        snapshots,
        "--lsp",
        "$*",
      }, " ")
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.php = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'intelephense'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

-- JSON: nvim-lsp-installer 只支持 vscode-langservers-extracted, 不支持 json-languageserver
-- AutoLoad.json = {
--    setup = function(self)
--    end
-- }

AutoLoad.sh = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'bash-language-server'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.xml = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'lemminx',
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

AutoLoad.yml = {
  setup = function(self)
    local configuration = get_configuration()
    local cmd_path = vim.fn.join({
      configuration.nvim_lsp_root,
      'node_modules',
      '.bin',
      'yaml-language-server'
    }, "/")
    Util.create_command(configuration.easy_cmd_full_path, {
      "#!/usr/bin/env sh",
      cmd_path .. " $*",
    })
    curr_lsp_constructor_calling()
    show_success_message()
  end
}

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
    local configuration = get_configuration()
    if not configuration.nvim_lsp_ok then
      return
    end
    local curr_plugin_ctx = Util.current_plugin_ctx()
    local plugin_name = Util.current_plugin_name()
    local curr_lsp_name = Util.current_lsp_name()

    local lua_config_path = Util.get_default_config_path()
    local lua_cmd_full_path = configuration.easy_cmd_full_path
    local nvim_lsp_root = configuration.nvim_lsp_root
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
