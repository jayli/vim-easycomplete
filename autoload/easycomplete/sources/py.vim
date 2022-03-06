if get(g:, 'easycomplete_sources_py')
  finish
endif
let g:easycomplete_sources_py = 1

function! easycomplete#sources#py#constructor(opt, ctx)
  " 注册 lsp
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'pyls',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
      \ 'allowlist': a:opt["whitelist"],
      \ })
endfunction

function! easycomplete#sources#py#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#py#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["py", "pyi"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
