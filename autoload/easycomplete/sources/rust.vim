
if exists('g:easycomplete_rust')
  finish
endif
let g:easycomplete_rust = 1

function! easycomplete#sources#rust#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'rust-analyzer',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name'])],
      \ 'root_uri':{server_info -> easycomplete#util#GetDefaultRootUri()},
      \ 'allowlist': ['rust'],
      \ 'initialization_options': {
      \     'completion': {
      \       'autoimport': { 'enable': v:true },
      \     },
      \ },
      \ 'config': {'refresh_pattern': '\([a-zA-Z0-9_-]\+\|\k\+\)$'},
      \ })
endfunction

function! easycomplete#sources#rust#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#rust#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["rs", "rust"])
endfunction

