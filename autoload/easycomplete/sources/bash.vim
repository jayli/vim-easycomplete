if exists('g:easycomplete_bash')
  finish
endif
let g:easycomplete_bash = 1

function! easycomplete#sources#bash#constructor(opt, ctx)
  if easycomplete#installer#executable('bash-language-server')
    call easycomplete#lsp#register_server({
        \ 'name': 'bash-languageserver',
        \ 'cmd': [easycomplete#installer#GetCommand(a:opt['name']), 'start'],
        \ 'root_uri':{server_info->fnamemodify(expand('%'), ':p:h')},
        \ 'allowlist': ['sh'],
        \ 'config': {'refresh_pattern': '\([a-zA-Z0-9_-]\+\|\k\+\)$'},
        \ })
  else
    call easycomplete#util#log("'bash-language-server' is not avilable. Please Install: ':EasyCompleteInstallServer sh' ")
  endif
endfunction

function! easycomplete#sources#bash#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#bash#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["sh"])
endfunction

