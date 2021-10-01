if get(g:, 'easycomplete_sources_vim')
  finish
endif
let g:easycomplete_sources_vim = 1

function! easycomplete#sources#vim#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'vimls',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name']), '--stdio']},
      \ 'whitelist': ['vim'],
      \ 'initialization_options': {
      \   'vimruntime': expand($VIMRUNTIME),
      \   'runtimepath': &rtp,
      \   'iskeyword': '@,48-57,_,192-255,-#',
      \   'indexes':{'runtime':"true", 'gap':100, 'count':3, 'runtimepath': "true"},
      \   "projectRootPatterns" : ["strange-root-pattern", ".git", "autoload", "plugin"],
      \   'diagnostic': {"enable": v:true},
      \   'suggest': { 'fromVimruntime': v:true , 'fromRuntimepath': v:true}
      \ }
      \ })
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
