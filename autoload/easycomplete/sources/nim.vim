if exists('g:easycomplete_nim')
  finish
endif
let g:easycomplete_nim = 1

function! easycomplete#sources#nim#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'nimlsp',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
      \ 'initialization_options' : {'diagnostics': 'true'},
      \ 'allowlist': ['nim'],
      \ })
endfunction

function! easycomplete#sources#nim#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#nim#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["nim","nimble"])
endfunction

