local Util = require "easycomplete_util"
local console = Util.console
local AutoLoad = {}

AutoLoad.lua = {
  a = 1,
  setup = function(self)
    -- TODO here 先获取 nvim_lsp_installed 的各种参数，拼成新的配置
    vim.cmd([[
      let g:easycomplete_source.lua.command = "/Users/bachi/.local/share/nvim/lsp_servers/sumneko_lua/extension/server/bin/lua-language-server"
      let g:easycomplete_source.lua.lsp.cmd = ["/Users/bachi/.local/share/nvim/lsp_servers/sumneko_lua/extension/server/bin/lua-language-server -E -e LANG=en /Users/bachi/.local/share/nvim/lsp_servers/sumneko_lua/extension/server/bin/main.lua"]
      let g:easycomplete_source.lua.lsp.ready = v:true
      call easycomplete#lsp#register_server(g:easycomplete_source.lua.lsp)
    ]])
  end
}

function AutoLoad.get(plugin_name)
  return Util.get(AutoLoad, plugin_name)
end


return AutoLoad
