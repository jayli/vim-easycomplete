if get(g:, 'easycomplete_sources_lua')
  finish
endif
let g:easycomplete_sources_lua = 1

let g:sumneko_lua_language_server_workspace_config = {
        \  'Lua': {
        \    'color': {
        \      'mode': 'Semantic'
        \    },
        \    'completion': {
        \      'callSnippet': 'Disable',
        \      'enable': v:true,
        \      'keywordSnippet': 'Replace'
        \    },
        \    'develop': {
        \      'debuggerPort': 11412,
        \      'debuggerWait': v:false,
        \      'enable': v:false
        \    },
        \    'diagnostics': {
        \      'enable': v:true,
        \      'globals': '',
        \      'severity': {}
        \    },
        \    'hover': {
        \      'enable': v:true,
        \      'viewNumber': v:true,
        \      'viewString': v:true,
        \      'viewStringMax': 1000
        \    },
        \    'runtime': {
        \      'path': ['?.lua', '?/init.lua', '?/?.lua'],
        \      'version': 'Lua 5.3'
        \    },
        \    'signatureHelp': {
        \      'enable': v:true
        \    },
        \    'workspace': {
        \      'ignoreDir': [],
        \      'maxPreload': 1000,
        \      'preloadFileSize': 100,
        \      'useGitIgnore': v:true
        \    }
        \  }
        \}

function! easycomplete#sources#lua#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'sumneko-lua-language-server',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
      \ 'config': {},
      \ 'workspace_config': g:sumneko_lua_language_server_workspace_config,
      \ 'allowlist': a:opt["whitelist"],
      \ })
endfunction

function! easycomplete#sources#lua#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#lua#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["lua"])
endfunction

function! easycomplete#sources#lua#filter(matches)
  " LUA lsp 功能不强，部分支持了 function expand
  " 而且匹配项的类型判断有一些错误，先保持原样不做修饰了
  return a:matches
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
