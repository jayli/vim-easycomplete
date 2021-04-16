if get(g:, 'easycomplete_sources_vim')
  finish
endif
let g:easycomplete_sources_vim = 1

function! easycomplete#sources#vim#constructor(opt, ctx)
  if executable('vim-language-server')
    call easycomplete#lsp#register_server({
        \ 'name': 'vimls',
        \ 'cmd': {server_info->['vim-language-server', '--stdio']},
        \ 'initialization_options':{'vimruntime': $VIMRUNTIME, 'runtimepath': &rtp, 'iskeyword': "@,48-57,_,192-255,-#"},
        \ 'suggest': {'fromVimruntime': v:true},
        \ 'allowlist': ['vim'],
        \ })
  endif
endfunction

function! easycomplete#sources#vim#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#vim#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["vim"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
