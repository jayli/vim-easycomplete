if exists('g:easycomplete_bash')
  finish
endif
let g:easycomplete_bash = 1

function! easycomplete#sources#bash#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'bash-languageserver',
      \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name']), 'start'],
      \ 'root_uri':{server_info->fnamemodify(expand('%'), ':p:h')},
      \ 'allowlist': a:opt['whitelist'],
      \ 'config': {'refresh_pattern': '\([a-zA-Z0-9_-]\+\|\k\+\)$'},
      \ })
endfunction

function! easycomplete#sources#bash#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#bash#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["sh"])
endfunction

