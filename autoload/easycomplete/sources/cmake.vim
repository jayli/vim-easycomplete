if get(g:, 'easycomplete_sources_cmake')
  finish
endif
let g:easycomplete_sources_cmake = 1

" TODO 仍未调通
function! easycomplete#sources#cmake#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'cmake-language-server',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name'])],
      \ 'root_uri':{server_info -> "file://" . fnamemodify(expand('%'), ':p:h')},
      \ 'initialization_options': {'buildDirectory': 'build'},
      \ 'allowlist': ['cmake']
      \ })
endfunction

function! easycomplete#sources#cmake#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#cmake#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["cmake"])
endfunction



" \ 'name': 'cmake-language-server',
"       \ 'cmd': {server_info->lsp_settings#get('cmake-language-server', 'cmd', [lsp_settings#exec_path('cmake-language-server')]+lsp_settings#get('cmake-language-server', 'args', []))},
"       \ 'root_uri':{server_info->lsp_settings#get('cmake-language-server', 'root_uri', lsp_settings#root_uri('cmake-language-server'))},
"       \ 'initialization_options': lsp_settings#get('cmake-language-server', 'initialization_options', {'buildDirectory': 'build'}),
"       \ 'allowlist': lsp_settings#get('cmake-language-server', 'allowlist', ['cmake']),
"       \ 'blocklist': lsp_settings#get('cmake-language-server', 'blocklist', []),
"       \ 'config': lsp_settings#get('cmake-language-server', 'config', lsp_settings#server_config('cmake-language-server')),
"       \ 'workspace_config': lsp_settings#get('cmake-language-server', 'workspace_config', {}),
"       \ 'semantic_highlight': lsp_settings#get('cmake-language-server', 'semantic_highlight', {}),
"       \ }
