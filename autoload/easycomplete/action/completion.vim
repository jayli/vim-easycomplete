" ----------------------------------------------------------------------
" LSP 专用工具函数
" 参考 vim-lsp 完全重构了，无须再安装外部依赖，这里的 LSP
" 工具函数主要是给 easycomplete 的插件用的通用方法，内部使用方便
" ----------------------------------------------------------------------

function! easycomplete#action#completion#do(opt, ctx)
  if empty(easycomplete#installer#GetCommand(a:opt['name']))
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif

  let l:info = easycomplete#util#FindLspServers()
  let l:ctx = easycomplete#context()
  if empty(l:info['server_names'])
    call easycomplete#complete(a:opt['name'], l:ctx, l:ctx['startcol'], [])
    return v:true
  endif
  call easycomplete#action#completion#LspRequest(l:info, a:opt['name'])
  return v:true
endfunction

" 原 s:send_completion_request(info)
" info: lsp server 信息
" plugin_name: 插件的名字，比如 py, ts
function! easycomplete#action#completion#LspRequest(info, plugin_name) abort
  " call s:console('-->', 'lsp request start')
  let l:server_name = a:info['server_names'][0]
  call easycomplete#lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/completion',
        \ 'params': {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
        \   'position': easycomplete#lsp#get_position(),
        \   'context': { 'triggerKind': 1 }
        \ },
        \ 'on_notification': function('s:HandleLspCallback', [l:server_name, a:plugin_name])
        \ })
endfunction

function! s:HandleLspCallback(server_name, plugin_name, data) abort
  " call s:console('<--', 'lsp response')
  if easycomplete#IsBacking() | return | endif
  let l:ctx = easycomplete#context()
  if easycomplete#lsp#client#is_error(a:data) || !has_key(a:data, 'response') ||
        \ !has_key(a:data['response'], 'result')
    call easycomplete#complete(a:plugin_name, l:ctx, l:ctx['startcol'], [])
    if a:plugin_name == "py"
      call s:log('Lsp Error', 'Please delete global pyls `rm /usr/local/bin/pyls` and reinstall pyls.')
    else
      echom "lsp error response"
    endif
    return
  endif

  let l:result = s:GetLspCompletionResult(a:server_name, a:data, a:plugin_name)
  let l:matches = l:result['matches']
  let l:startcol = l:ctx['startcol']

  let l:matches = s:MatchResultFilterPipe(a:plugin_name, l:matches)
  call s:console(l:matches)
  call easycomplete#complete(a:plugin_name, l:ctx, l:startcol, l:matches)
endfunction

function! s:GetLspCompletionResult(server_name, data, plugin_name) abort
  let l:result = a:data['response']['result']
  let l:response = a:data['response']

  " 这里包含了 info document 和 matches
  let l:completion_result = easycomplete#util#GetVimCompletionItems(l:response, a:plugin_name)
  return {'matches': l:completion_result['items'], 'incomplete': l:completion_result['incomplete'] }
endfunction

function! s:MatchResultFilterPipe(plugin_name, matches)
  let lsp_ctx = easycomplete#GetCurrentLspContext()
  if type(get(lsp_ctx, "constructor")) != type('')
    let fn_name = a:plugin_name
    let Fun_name = "easycomplete#sources#" . fn_name . "#filter"
  else
    let constructor_str = lsp_ctx["constructor"]
    let Fun_name = substitute(constructor_str, "#constructor$", "#filter", "g")
  endif
  if !easycomplete#util#FuncExists(Fun_name)
    return a:matches
  endif
  return call(funcref(Fun_name), [a:matches])
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction
