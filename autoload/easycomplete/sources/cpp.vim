if get(g:, 'easycomplete_sources_cpp')
  finish
endif
let g:easycomplete_sources_cpp = 1

function! easycomplete#sources#cpp#constructor(opt, ctx)
  if executable('ccls')
    call easycomplete#lsp#register_server({
        \ 'name': 'ccls',
        \ 'cmd': {server_info->['ccls']},
        \ 'initialization_options': {'cache': {'directory': '/tmp/ccls/cache'}},
        \ 'allowlist': ['c', 'cpp', 'objc', 'objcpp', 'cc'],
        \ })
  endif
endfunction

function! easycomplete#sources#cpp#completor(opt, ctx) abort
  return easycomplete#DoLspComplete(a:opt, a:ctx)
endfunction

function! easycomplete#sources#cpp#GotoDefinition(...)
  return easycomplete#DoLspDefinition(["cpp","c","h"])
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
