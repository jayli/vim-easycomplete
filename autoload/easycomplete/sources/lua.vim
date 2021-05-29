if get(g:, 'easycomplete_sources_lua')
  finish
endif
let g:easycomplete_sources_lua = 1

function! easycomplete#sources#lua#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'emmylua-ls',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'whitelist': ['lua'],
      \ })
endfunction

function! easycomplete#sources#lua#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#lua#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["lua"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
