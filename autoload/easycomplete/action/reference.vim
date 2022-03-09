
augroup easycomplete#closeQF
  autocmd!
  autocmd QuitPre * call easycomplete#action#reference#CloseQF()
augroup END

function! easycomplete#action#reference#CloseQF()
  cclose
endfunction

function! easycomplete#action#reference#do()
  call s:do()
endfunction

function! s:do()
  let l:request_params = { 'context': { 'includeDeclaration': v:false } }
  let l:server_names = easycomplete#util#FindLspServers()['server_names']
  if empty(l:server_names)
    call s:DoTSReference()
    return
  endif
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

function! s:DoTSReference()
  let all_plugins = easycomplete#GetAllPlugins()
  if has_key(all_plugins, "ts") && easycomplete#sources#deno#IsTSOrJSFiletype() &&
        \ !easycomplete#sources#deno#IsDenoProject()
    if get(easycomplete#GetCurrentLspContext(), "name", "") == 'ts'
      call easycomplete#sources#ts#reference()
    endif
  endif
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
  let quick_window_list = []
  if empty(reference_list)
    call s:log("No references found")
    return
  endif
  for item in reference_list
    let filename = easycomplete#util#TrimFileName(get(item, "uri", ""))
    let lnum = str2nr(get(item, "range", "")['start']['line']) + 1
    let col = str2nr(get(item, "range", "")['start']['character']) + 1
    call add(quick_window_list, {
          \  'filename': filename,
          \  'lnum':     lnum,
          \  'col':      col,
          \  'text':     s:GetFileContext(filename, lnum, col),
          \  'valid':    0,
          \ })
  endfor
  call setqflist(quick_window_list, 'r')
  copen
endfunction

function! s:GetFileContext(filename, lnum, col)
  let lines = readfile(a:filename, '', a:lnum)
  let str = lines[a:lnum - 1][0:100]
  return str
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
