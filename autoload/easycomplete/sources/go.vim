" TODO Gocode → gopls
if exists('g:easycomplete_gopls')
  finish
endif
let g:easycomplete_gopls = 1

function! easycomplete#sources#go#constructor(opt, ctx)
  if executable('gopls')
    call easycomplete#lsp#register_server({
        \ 'name': 'gopls',
        \ 'cmd': {server_info->['gopls']},
        \ 'initialization_options':  {
        \     'completeUnimported': v:true,
        \     'matcher': 'fuzzy',
        \     'codelenses': {
        \         'generate': v:true,
        \         'test': v:true,
        \     },
        \ },
        \ 'allowlist': ['go'],
        \ })
  endif
endfunction

function! easycomplete#sources#go#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#go#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["go"])
endfunction

