if get(g:, 'easycomplete_sources_grvy')
  finish
endif
let g:easycomplete_sources_grvy = 1

function! easycomplete#sources#grvy#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'groovy-language-server',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
      \ 'allowlist': a:opt["whitelist"],
      \ })
endfunction

function! easycomplete#sources#grvy#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#grvy#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["groovy","gradle"])
endfunction

