
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
  let new_name = input("New Name:")
  call easycomplete#sources#ts#rename(new_name)
endfunction

function! s:HandleLspCallback(server_name, data)
  let changes = s:get(a:data, "response", "result", "changes")
  if empty(changes)
    call s:log("Nothing to be changed")
    return
  endif

  let changed_count = 0
  for filename in changes->keys()
    let file_edits = s:get(changes, filename)
    let fullfname = easycomplete#util#TrimFileName(filename)
    for item in file_edits
      let lnum = s:get(item, "range", "start", "line") + 1
      let col_start = s:get(item, "range", "start", "character") + 1
      let col_end = s:get(item, "range", "end", "character")
      let new_text = s:get(item, "newText")
      call easycomplete#util#TextEdit(fullfname, lnum, col_start, col_end, new_text)
      let changed_count += 1
    endfor
  endfor
  call s:log("Changed", changed_count, "locations!")
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:get(...)
  return call('easycomplete#util#get', a:000)
endfunction
