









function! easycomplete#signature#DoSignature()
  call easycomplete#lsp#get_signature_help_under_cursor()
endfunction

function! easycomplete#signature#callback(server, response)
  let title = a:response[0]
  let kind = a:response[1]["kind"]
  let content = a:response[1]["value"]
  call s:console(title,kind,content)
  let content = substitute(content, "```", "", "g")
  let content = split(content, "\\n")

  " call easycomplete#popup#show([title], 'Pmenu', 1)
  call s:console('<---', 'signature callback', content)
  call easycomplete#popup#float([title,'----'] + content, 'Pmenu', 1, "", [0,0])

endfunction


function! easycomplete#signature#flush()
  call easycomplete#popup#close("float")
endfunction


function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
