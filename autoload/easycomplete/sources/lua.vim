if get(g:, 'easycomplete_sources_lua')
  finish
endif
let g:easycomplete_sources_lua = 1

function! easycomplete#sources#lua#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'emmylua-ls',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'whitelist': ['lua'],
      \ })
endfunction

function! easycomplete#sources#lua#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#lua#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["lua"])
endfunction

function! easycomplete#sources#lua#filter(matches)
  " LUA lsp 功能不强，部分支持了 function expand
  " 而且匹配项的类型判断有一些错误，先保持原样不做修饰了
  return a:matches
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
