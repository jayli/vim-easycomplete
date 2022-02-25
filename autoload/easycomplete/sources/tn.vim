if exists('g:easycomplete_tn')
  finish
endif
let g:easycomplete_tn = 1

function! easycomplete#sources#tn#constructor(opt, ctx)
  return v:true
endfunction

function! easycomplete#sources#tn#completor(opt, ctx) abort
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  return v:true
endfunction
