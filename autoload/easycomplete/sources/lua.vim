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
        \  },
        \  "sumneko-lua": {
        \    'enableNvimLuaDev': v:true
        \  }
        \ }

function! easycomplete#sources#lua#constructor(opt, ctx)
  let config_param = ""
  let config_path = easycomplete#util#GetConfigPath(a:opt["name"])
  if easycomplete#util#FileExists(config_path)
    let config_param = "--configpath=" . config_path
  endif
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'sumneko_lua',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name']), config_param],
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
  let ctx = easycomplete#context()
  let matches = a:matches
  let matches = map(copy(matches), function("easycomplete#util#FunctionSurffixMap"))
  return matches
  " return a:matches
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
