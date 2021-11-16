

function! easycomplete#action#documentation#LspRequest(item) abort
  let l:server_name = easycomplete#util#FindLspServers()['server_names'][0]
  if easycomplete#lsp#HasProvider(l:server_name, 'completionProvider', 'resolveProvider')
    echom 222222
    try
      call easycomplete#lsp#send_request(l:server_name, {
            \ 'method': 'completionItem/resolve',
            \ 'params': extend({
            \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
            \   'position': easycomplete#lsp#get_position(),
            \   'context': { 'triggerKind': 1 }
            \ }, a:item),
            \ 'on_notification': function('s:HandleLspCallback', [l:server_name])
            \ })
    catch 
      echom v:exception
    endtry
    " let s:Dispose = easycomplete#lsp#callbag#pipe(
    "     \ easycomplete#lsp#request(l:server_name, {
    "     \   'method': 'completionitem/resolve',
    "     \   'params': a:item,
    "     \ }),
    "     \ easycomplete#lsp#callbag#map({x->{
    "     \   'server_name': l:server_name,
    "     \   'completion_item': x['response']['result'],
    "     \   'complete_position': easycomplete#lsp#get_position(),
    "     \ }})
    "     \ )
  endif
endfunction

function! s:HandleLspCallback(server_name, data) abort
  echom 'callback' . string(a:data)
  let l:ctx = easycomplete#context()
  if easycomplete#lsp#client#is_error(a:data) || !has_key(a:data, 'response') ||
        \ !has_key(a:data['response'], 'result')
    call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], [])
    echom "lsp error response"
    return
  endif
  echom a:data
endfunction
