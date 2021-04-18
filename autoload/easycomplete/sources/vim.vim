if get(g:, 'easycomplete_sources_vim')
  finish
endif
let g:easycomplete_sources_vim = 1

function! easycomplete#sources#vim#constructor(opt, ctx)
  if executable('vim-language-server')
    " TODO 首次 lsp 返回的不是匹配全集
    call easycomplete#lsp#register_server({
          \ 'name': 'vimls',
          \ 'cmd': {server_info->['vim-language-server', '--stdio']},
          \ 'whitelist': ['vim'],
          \ 'initialization_options': {
          \   'vimruntime': expand($VIMRUNTIME),
          \   'runtimepath': &rtp,
          \   'iskeyword': '@,48-57,_,192-255,-#',
          \   'diagnostic':{'enable':1},
          \   'indexes':{'runtime':1, 'gap':10, 'count':50, 'runtimepath': 0},
          \   'suggest': { 'from_vimruntime': 1 , 'from_runtimepath': 0}
          \ }
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
