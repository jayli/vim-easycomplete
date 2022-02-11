if get(g:, 'easycomplete_sources_deno')
  finish
endif
let g:easycomplete_sources_deno = 1
let s:file_extensions = ["js","jsx","ts","tsx","mjs","ejs"]

function! easycomplete#sources#deno#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
        \ 'name': 'deno',
        \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name']), 'lsp']},
        \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
        \ 'initialization_options' : {
        \   'enable': v:true,
        \   'lint': v:true,
        \   'unstable': v:true,
        \   'importMap': v:null,
        \   'codeLens': {
        \     'implementations': v:true,
        \     'references': v:true,
        \     'referencesAllFunctions': v:true,
        \     'test': v:true,
        \     'testArgs': ['--allow-all'],
        \   },
        \   "suggest": {
        \     "autoImports": v:true,
        \     "completeFunctionCalls": v:true,
        \     "names": v:true,
        \     "paths": v:true,
        \     "imports": {
        \       "autoDiscover": v:false,
        \       "hosts": {
        \         "https://deno.land/": v:true,
        \       },
        \     },
        \   },
        \   'config': v:null,
        \   'internalDebug': v:false,
        \  },
        \ 'config': {'refresh_pattern': '\(\$[a-zA-Z0-9_:]*\|\k\+\)$'},
        \ 'allowlist': a:opt["whitelist"],
        \ 'blocklist' : [],
        \ 'workspace_config' : {},
        \ 'semantic_highlight' : {},
        \ })
endfunction

function! easycomplete#sources#deno#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#deno#GotoDefinition(...)
  return easycomplete#DoLspDefinition(s:file_extensions)
endfunction

function! easycomplete#sources#deno#filter(matches)
  let ctx = easycomplete#context()
  let matches = a:matches
  let matches = map(copy(matches), function("easycomplete#util#FunctionSurffixMap"))
  return matches
endfunction
