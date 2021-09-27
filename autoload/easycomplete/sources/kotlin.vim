if exists('g:easycomplete_kotlin')
  finish
endif
let g:easycomplete_kotlin = 1

function! easycomplete#sources#kotlin#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'kotlin-language-server',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name'])],
      \ 'root_uri':{server_info -> "file://" . fnamemodify(expand('%'), ':p:h')},
      \ 'initialization_options': v:null,
      \ 'config': {},
      \ 'allowlist': ['kotlin']
      \ })
endfunction

function! easycomplete#sources#kotlin#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#kotlin#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["kt"])
endfunction

