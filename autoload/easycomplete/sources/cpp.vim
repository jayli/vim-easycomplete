if get(g:, 'easycomplete_sources_cpp')
  finish
endif
let g:easycomplete_sources_cpp = 1

function! easycomplete#sources#cpp#constructor(opt, ctx)
  call easycomplete#RegisterLspServer(a:opt, {
      \ 'name': 'clangd',
      \ 'cmd': {server_info->[easycomplete#installer#GetCommand(a:opt['name'])]},
      \ 'initialization_options':{
      \    'cache': {'directory': '/tmp/clangd/cache'},
      \    'completion': {'detailedLabel': v:false }
      \  },
      \ 'allowlist': a:opt['whitelist'],
      \ })
endfunction

function! easycomplete#sources#cpp#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#cpp#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["cpp","c","h","cc","objc","objcpp","m","hpp"])
endfunction

function! easycomplete#sources#cpp#filter(matches)
  let ctx = easycomplete#context()
  let matches = map(copy(a:matches), function("easycomplete#util#FunctionSurffixMap"))
  return matches
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
