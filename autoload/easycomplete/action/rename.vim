
function! easycomplete#action#rename#do()
  call s:do()
endfunction

function! s:do()
  let l:request_params = { 'context': { 'includeDeclaration': v:false } }
  let l:server_names = easycomplete#util#FindLspServers()['server_names']
  if empty(l:server_names)
    call s:DoTSRename()
    return
  endif
  let l:server_name = l:server_names[0]
  if !easycomplete#lsp#HasProvider(l:server_name, 'renameProvider')
    call s:log('[LSP References]: renameProvider is not supported')
    return
  endif

  let new_name = input("New Name:")

  call easycomplete#lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/rename',
        \ 'params': {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
        \   'position': easycomplete#lsp#get_position(),
        \   'newName' : new_name,
        \ },
        \ 'on_notification': function('s:HandleLspCallback', [l:server_name]),
        \ })
endfunction


function! s:DoTSRename()

endfunction

function! s:HandleLspCallback(server_name, data)
  " TODO Here
  call s:log(a:data)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
