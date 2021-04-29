if exists('g:easycomplete_json')
  finish
endif
let g:easycomplete_json = 1

function! easycomplete#sources#json#constructor(opt, ctx)
  if executable('json-languageserver')
    " TODO 不好使
    call easycomplete#lsp#register_server({
        \ 'name': 'json-languageserver',
        \ 'cmd': ['json-languageserver', '--stdio'],
        \ 'initialization_options': {'provideFormatter': v:true},
        \ 'config':{'refresh_pattern': '\("\k*\|\[\|\k\+\)$'},
        \ 'allowlist': ['json'],
        \ })
        " \ 'root_uri': fnamemodify(expand('%'), ':p:h'),
  endif
endfunction

function! easycomplete#sources#json#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#json#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["json"])
endfunction

