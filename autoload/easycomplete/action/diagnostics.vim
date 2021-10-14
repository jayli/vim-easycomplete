" diagnostics

function! easycomplete#action#diagnostics#do()
  if !easycomplete#util#LspServerReady() | return | endif
  call easycomplete#lsp#notify_diagnostics_update()
  call s:AsyncRun(function("easycomplete#lsp#ensure_flush_all"),[],10)
endfunction

function! easycomplete#action#diagnostics#HandleCallback(server, response)
  " call s:log("<----",a:response)
  call easycomplete#sign#hold()
  call easycomplete#sign#flush()
  call easycomplete#sign#cache(a:response)
  call easycomplete#sign#render()
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction
