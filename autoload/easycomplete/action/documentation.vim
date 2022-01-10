

function! easycomplete#action#documentation#LspRequest(item) abort
  call s:console('------->', a:item)
  let l:server_name = easycomplete#util#FindLspServers()['server_names'][0]
  if easycomplete#lsp#HasProvider(l:server_name, 'completionProvider', 'resolveProvider')
    let params = s:GetDocumentParams(copy(a:item), l:server_name)
    call s:console(params)
    try
      call easycomplete#lsp#send_request(l:server_name, {
            \ 'method': 'completionItem/resolve',
            \ 'params': params.completion_item,
            \ 'on_notification': function('s:HandleLspCallback', [l:server_name])
            \ })
      " call easycomplete#lsp#send_request(l:server_name, {
      "       \ 'method': 'completionItem/resolve',
      "       \ 'params': extend({
      "       \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
      "       \   'position': easycomplete#lsp#get_position(),
      "       \   'context': { 'triggerKind': 1 }
      "       \ }, a:item),
      "       \ 'on_notification': function('s:HandleLspCallback', [l:server_name])
      "       \ })
    catch 
      echom v:exception
    endtry
  endif
endfunction

function! s:GetDocumentParams(item, server_name)
  " {'label': 'aa', 'data': {'name': 'aa', 'type': 1}, 'kind': 12}
  let ret = {}
  let ret.server_name = a:server_name
  let ret.completion_item = {
        \ 'label' : a:item.word,
        \ 'data' : {'name' : a:item.word, 'type' : 1},
        \ 'kind' : 12
        \ }
  let ret.complete_position = easycomplete#lsp#get_position()
  return ret
endfunction

function! s:HandleLspCallback(server_name, data) abort
  call s:console('<------ HandleLspCallback', a:data)
  call s:log(a:data.response.result.documentation)
  let l:ctx = easycomplete#context()
  if easycomplete#lsp#client#is_error(a:data) || !has_key(a:data, 'response') ||
        \ !has_key(a:data['response'], 'result')
    call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], [])
    echom "lsp error response"
    return
  endif


  try
    let info = a:data.response.result.documentation.value
    " TODO here jayli 这一句不起作用
    call easycomplete#popup#MenuPopupChanged([info])
  catch
    echom '-----------------------------'
    echom v:exception
    echom '-----------------------------'
  endtry

  echom a:data
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
