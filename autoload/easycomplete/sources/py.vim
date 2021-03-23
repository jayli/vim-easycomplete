if get(g:, 'easycomplete_sources_py')
  finish
endif
let g:easycomplete_sources_py = 1


function! easycomplete#sources#py#constructor(opt, ctx)
endfunction

function! easycomplete#sources#py#completor(opt, ctx) abort
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  return v:true
endfunction

