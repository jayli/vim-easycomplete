









function! easycomplete#signature#DoSignature()
  call easycomplete#lsp#get_signature_help_under_cursor()
endfunction

function! easycomplete#signature#callback(server, response)
  let title = a:response[0]
  let kind = a:response[1]["kind"]
  let body = a:response[1]["value"]
  call s:console(title,kind,body)
  call easycomplete#popup#show([title,kind,body], 'Pmenu', 1)

endfunction


function! easycomplete#signature#flush()
  call easycomplete#popup#close()
endfunction


function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
