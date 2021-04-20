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
          \ 'initializationOptions': {
          \   'vimruntime': expand($VIMRUNTIME),
          \   'runtimepath': &rtp,
          \   'iskeyword': '@,48-57,_,192-255,-#',
          \   'indexes':{'runtime':"true", 'gap':100, 'count':1, 'runtimepath': "true"},
          \   "projectRootPatterns" : ["strange-root-pattern", ".git", "autoload", "plugin"],
          \   'suggest': { 'fromVimruntime': "true" , 'fromRuntimepath': "true"}
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
