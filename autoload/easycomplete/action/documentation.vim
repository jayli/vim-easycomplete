
let b:easycomplete_documentation_popup = 0

function! easycomplete#action#documentation#LspRequest(item) abort
  let l:server_name = easycomplete#util#FindLspServers()['server_names'][0]
  if easycomplete#lsp#HasProvider(l:server_name, 'completionProvider', 'resolveProvider')
    if !exists("b:easycomplete_documentation_popup")
      let b:easycomplete_documentation_popup = 0
    endif
    if b:easycomplete_documentation_popup > 0
      call timer_stop(b:easycomplete_documentation_popup)
    endif
    let b:easycomplete_documentation_popup = timer_start(300, { -> s:ClosePopup() })
    let params = s:GetDocumentParams(copy(a:item), l:server_name)
    try
      call easycomplete#lsp#send_request(l:server_name, {
            \ 'method': 'completionItem/resolve',
            \ 'params': params.completion_item,
            \ 'on_notification': function('s:HandleLspCallback', [l:server_name])
            \ })
    catch
      " echom v:exception
    endtry
  else
    call s:ClosePopup()
  endif
endfunction

function! s:HandleLspCallback(server_name, data) abort
  " call s:console('<---', a:data.response)
  if b:easycomplete_documentation_popup > 0
    call timer_stop(b:easycomplete_documentation_popup)
    let b:easycomplete_documentation_popup = 0
  endif
  let l:ctx = easycomplete#context()

  if has_key(a:data.response, "error")
        \ || easycomplete#lsp#client#is_error(a:data)
        \ || !has_key(a:data, 'response')
        \ || !has_key(a:data['response'], 'result')
    call s:ClosePopup()
    " echom "lsp error response"
    return
  endif

  try
    let info = a:data.response.result.documentation.value
    let oringal_name = a:data.response.result.label
    if empty(info)
      call s:ClosePopup()
    elseif oringal_name == get(g:easycomplete_completed_item, "word", "")
      " let info = substitute(info, '```', '', 'g')
      let info = easycomplete#util#NormalizeLspInfo(info)
      if type(info) == type("")
        let info = [info]
      endif
      call easycomplete#ShowCompleteInfo(info)
      if g:easycomplete_menu_abbr == 1
        let menu_flag = "[" . toupper(b:easycomplete_lsp_plugin["name"]) . "]"
      else
        let menu_flag = get(g:easycomplete_completed_item, "menu", "")
      endif
      let menu_word = get(g:easycomplete_completed_item, "word", "")
      call easycomplete#SetMenuInfo(menu_word, info, menu_flag)
    endif
  catch
    call s:ClosePopup()
    " echom v:exception
  endtry
endfunction

function! s:ClosePopup()
  call easycomplete#popup#close("popup")
endfunction

function! s:GetDocumentParams(item, server_name)
  " {'label': 'aa', 'data': {'name': 'aa', 'type': 1}, 'kind': 12}
  let ret = {}
  let ret.server_name = a:server_name
  let kind_number = str2nr(easycomplete#util#GetKindNumber(a:item))
  let lsp_item = easycomplete#util#GetLspItem(a:item)
  let text_edit = s:TextEditParser(get(lsp_item, 'textEdit', {}))
  " TODO
  "  rust 依赖 position / textDocument 字段
  "      \  'label' : substitute(a:item.word, '(.*)$', '', ''),
  let ret.completion_item = extend({
        \  'label' : a:item.word,
        \  'data' : extend({
        \     'name' : a:item.word,
        \   }, s:GetExtendedParamData(get(lsp_item, 'data', {}))),
        \  'kind' : kind_number,
        \  'sortText' : get(lsp_item, 'sortText', ""),
        \  'detail' : get(lsp_item, 'detail', ""),
        \ },  {})
  if !empty(text_edit)
    let ret.completion_item["textEdit"] = text_edit
  endif
  " let ret.completion_item = extend({
  "       \  'label' : a:item.word,
  "       \  'data' : extend({
  "       \     'name' : a:item.word,
  "       \     'type' : 1,
  "       \     'position' : {
  "       \        'position' : easycomplete#lsp#get_position(),
  "       \        'textDocument' : easycomplete#lsp#get_text_document_identifier()
  "       \     },
  "       \     'full_import_path': a:item.word,
  "       \     'imported_name' : a:item.word,
  "       \     'import_for_trait_assoc_item' : v:false,
  "       \   }, get(lsp_item, 'data', {})),
        " \  'documentation' : {
        " \    'kind' : 'markdown',
        " \    'value' : '123',
        " \  },
  "       \  'additionalTextEdits' : [],
  "       \  'kind' : kind_number
  "       \ },  {})
  let ret.complete_position = easycomplete#lsp#get_position()
  return ret
endfunction

function! s:GetExtendedParamData(data)
  let plugin_name = easycomplete#util#GetLspPluginName()
  if plugin_name == "dart"
    return s:DartParamParser(a:data)
  endif
  if plugin_name == "sh"
    return s:ShParamParser(a:data)
  endif
  if plugin_name == "rust"
    return s:RustParamParser(a:data)
  endif
  if plugin_name == "rb"
    return s:RbParamParser(a:data)
  endif
  return a:data
endfunction

" Rust Hacking
" TODO Rust completionItem/resolve not ready
function! s:RustParamParser(data)
  let ret_data = {}
  let ret_data["position"] = {
        \ 'position' : easycomplete#lsp#get_position(),
        \ 'textDocument' : easycomplete#lsp#get_text_document_identifier(),
        \ }
  let item = get(g:easycomplete_completechanged_event, 'completed_item', {})
  let word = get(item, 'word', "")
  let ret_data["imports"] = []
  let ret_data["import_for_trait_assoc_item"] = v:false
  return ret_data
endfunction

" Dart hacking
function! s:DartParamParser(data)
  let ret_data = {}
  if has_key(a:data, 'file')       | let ret_data["file"] = a:data["file"]               | endif
  if has_key(a:data, 'iLength')    | let ret_data["iLength"] = str2nr(a:data["iLength"]) | endif
  if has_key(a:data, "libId")      | let ret_data["libId"] = str2nr(a:data["libId"])     | endif
  if has_key(a:data, "displayUri") | let ret_data["displayUri"] = a:data["displayUri"]   | endif
  if has_key(a:data, "offset")     | let ret_data["offset"] = str2nr(a:data["offset"])   | endif
  if has_key(a:data, "rOffset")    | let ret_data["rOffset"] = str2nr(a:data["rOffset"]) | endif
  if has_key(a:data, "rLength")    | let ret_data["rLength"] = str2nr(a:data["rLength"]) | endif
  return ret_data
endfunction

" ruby Hacking
function! s:RbParamParser(data)
  let ret_data = deepcopy(a:data)
  let ret_data["deprecated"] = v:false
  if get(a:data, "location", "") == ""
    let ret_data["location"] = v:null
  endif
  return ret_data
endfunction

" Bash Shell Script Hacking
function! s:ShParamParser(data)
  let ret_data = {}
  let ret_data["type"] = 1
  return ret_data
endfunction

function! s:TextEditParser(text_edit)
  try
    let l:te = {
          \ 'range' : {
          \    'end': {
          \       'character' : str2nr(a:text_edit["range"]["end"]["character"]),
          \       'line' : str2nr(a:text_edit["range"]["end"]["line"]),
          \     },
          \    'start': {
          \       'character' : str2nr(a:text_edit["range"]["start"]["character"]),
          \       'line' : str2nr(a:text_edit["range"]["start"]["line"]),
          \    },
          \ },
          \ 'newText' : get(a:text_edit, "newText", ""),
          \ }
    return l:te
  catch
    return {}
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
