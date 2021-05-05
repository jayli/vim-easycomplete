if exists('g:easycomplete_bash')
  finish
endif
let g:easycomplete_bash = 1

function! easycomplete#sources#bash#constructor(opt, ctx)
  if executable('bash-language-server')
    call easycomplete#lsp#register_server({
        \ 'name': 'bash-languageserver',
        \ 'cmd': ['bash-language-server', 'start'],
        \ 'root_uri':{server_info->fnamemodify(expand('%'), ':p:h')},
        \ 'allowlist': ['sh'],
        \ 'config': {'refresh_pattern': '\([a-zA-Z0-9_-]\+\|\k\+\)$'},
        \ })
  else
    echo printf("'bash-language-server' is not avilable, Please install: '%s'", 'npm -g install bash-language-server')
  endif
endfunction

function! easycomplete#sources#bash#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#bash#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["sh"])
endfunction

