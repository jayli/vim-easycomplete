
let b:easycomplete_documentation_popup = 0

function! easycomplete#action#documentation#LspRequest(item) abort
  let l:server_name = easycomplete#util#FindLspServers()['server_names'][0]
  if easycomplete#lsp#HasProvider(l:server_name, 'completionProvider', 'resolveProvider')
    let params = s:GetDocumentParams(copy(a:item), l:server_name)
    try
      call easycomplete#lsp#send_request(l:server_name, {
            \ 'method': 'completionItem/resolve',
            \ 'params': params.completion_item,
            \ 'on_notification': function('s:HandleLspCallback', [l:server_name])
            \ })
      if b:easycomplete_documentation_popup > 0
        call timer_stop(b:easycomplete_documentation_popup)
      endif
      let b:easycomplete_documentation_popup = timer_start(300, { -> s:ClosePopup() })
    catch
      echom v:exception
    endtry
  else
    call s:ClosePopup()
  endif
endfunction

function! s:ClosePopup()
  call easycomplete#popup#close("popup")
endfunction

function! s:GetDocumentParams(item, server_name)
  " {'label': 'aa', 'data': {'name': 'aa', 'type': 1}, 'kind': 12}
  let ret = {}
  let ret.server_name = a:server_name
  let ret.completion_item = {
        \  'label' : a:item.word,
        \  'data' : {
        \     'name' : a:item.word,
        \     'type' : 1,
        \     'file' : easycomplete#util#GetCurrentFullName(),
        \     'offset' : easycomplete#context()['col']
        \    },
        \  'kind' : 12
        \ }
  let ret.complete_position = easycomplete#lsp#get_position()
  return ret
endfunction

function! s:HandleLspCallback(server_name, data) abort
  if b:easycomplete_documentation_popup > 0
    call timer_stop(b:easycomplete_documentation_popup)
    let b:easycomplete_documentation_popup = 0
  endif
  let l:ctx = easycomplete#context()
  if easycomplete#lsp#client#is_error(a:data) || !has_key(a:data, 'response') ||
        \ !has_key(a:data['response'], 'result')
    call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], [])
    call easycomplete#popup#close("popup")
    echom "lsp error response"
    return
  endif

  try
    let info = a:data.response.result.documentation.value
    let oringal_name = a:data.response.result.label
    if empty(info)
      call easycomplete#popup#close("popup")
    elseif oringal_name == get(g:easycomplete_completed_item, "word", "")
      let info = substitute(info, '```', '', 'g')
      let info = easycomplete#util#NormalizeLspInfo(info)
      if type(info) == type("")
        let info = [info]
      endif
      call easycomplete#ShowCompleteInfo(info)
      let menu_flag = "[" . toupper(b:easycomplete_lsp_plugin["name"]) . "]"
      let menu_word = get(g:easycomplete_completed_item, "word", "")
      call easycomplete#SetMenuInfo(menu_word, info, menu_flag)
    endif
  catch
    call easycomplete#popup#close("popup")
    " echom v:exception
  endtry
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:AsyncRun(...)
  return call('easycomplete#util#AsyncRun', a:000)
endfunction

function! s:StopAsyncRun(...)
  return call('easycomplete#util#StopAsyncRun', a:000)
endfunction
