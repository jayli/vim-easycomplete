
function! easycomplete#action#reference#do()
  call s:do()
endfunction

function! s:do()
  let l:request_params = { 'context': { 'includeDeclaration': v:false } }
  let l:server_names = easycomplete#util#FindLspServers()['server_names']
  if empty(l:server_names) | return | endif
  let l:server_name = l:server_names[0]
  if !easycomplete#lsp#HasProvider(l:server_name, 'referencesProvider')
    call s:log('[LSP References]: referencesProvider is not supported')
    return
  endif

  call easycomplete#lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/references',
        \ 'params': {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
        \   'position': easycomplete#lsp#get_position(),
        \   'context': {
        \      "includeDeclaration": v:false
        \   },
        \ },
        \ 'on_notification': function('s:HandleLspCallback', [l:server_name]),
        \ })
endfunction

function! s:HandleLspCallback(server_name, data)
  if easycomplete#lsp#client#is_error(a:data['response'])
    call easycomplete#lsp#utils#error('Failed ' . a:server_name)
    return
  endif

  if !has_key(a:data['response'], 'result')
    return
  endif
  let reference_list = get(a:data['response'], 'result', [])
  call s:log(reference_list)
  let quick_window_list = []
  for item in reference_list
    call add(quick_window_list, {
          \  'filename': easycomplete#util#TrimFileName(get(item, "uri", "")),
          \  'lnum': str2nr(get(item, "range", "")['start']['line']) + 1,
          \  'col':str2nr(get(item, "range", "")['start']['character']),
          \  'type':'W',
          \  'text':'sdf',
          \  'valid':1,
          \ })
  endfor
  try
    call s:log(quick_window_list)
    call setqflist([])
    " TODO not work
    call setqflist(quick_window_list, 'r')
  catch
    echom v:exception

  endtry
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
