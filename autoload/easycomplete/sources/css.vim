if exists('g:easycomplete_css')
  finish
endif
let g:easycomplete_css = 1

function! easycomplete#sources#css#constructor(opt, ctx)
  if executable('css-languageserver')
    call easycomplete#lsp#register_server({
        \ 'name': 'css-languageserver',
        \ 'cmd': ['css-languageserver', '--stdio'],
        \ 'allowlist': ['css', 'less', 'sass', 'scss'],
        \ 'config': {'refresh_pattern': '\([a-zA-Z0-9_-]\+\)$'},
        \ })
  endif
endfunction

function! easycomplete#sources#css#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#css#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["css","less","scss","sass"])
endfunction

