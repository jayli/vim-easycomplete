let s:enabled = 0
" let s:Stream = easycomplete#lsp#callbag_makeSubject()
let s:already_setup = 0
let s:servers = {} " { lsp_id, server_info, init_callbacks, init_result, buffers: { path: { changed_tick } }
let s:last_command_id = 0
let s:notification_callbacks = [] " { name, callback }

let s:undefined_token = '__callbag_undefined__'
let s:str_type = type('')

" This hold previous content for each language servers to make
" DidChangeTextDocumentParams. The key is buffer numbers:
"    {
"      1: {
"        "golsp": [ "first-line", "next-line", ... ],
"        "bingo": [ "first-line", "next-line", ... ]
"      },
"      2: {
"        "pyls": [ "first-line", "next-line", ... ]
"      }
"    }
let s:file_content = {}

augroup _lsp_silent_
    autocmd!
    autocmd User lsp_setup silent
    autocmd User lsp_register_server silent
    autocmd User lsp_unregister_server silent
    autocmd User lsp_server_init silent
    autocmd User lsp_server_exit silent
    autocmd User lsp_complete_done silent
    autocmd User lsp_float_opened silent
    autocmd User lsp_float_closed silent
    autocmd User lsp_buffer_enabled silent
    autocmd User lsp_diagnostics_updated silent
    autocmd User lsp_progress_updated silent
augroup END

function! easycomplete#lsp#register_server(server_info) abort
  let l:server_name = a:server_info['name']
  if has_key(s:servers, l:server_name)
    call s:log('lsp#register_server', 'server already registered', l:server_name)
  endif
  let s:servers[l:server_name] = {
        \ 'server_info': a:server_info,
        \ 'lsp_id': 0,
        \ 'buffers': {},
        \ }
  call s:log('easycomplete#lsp#register_server', 'server registered', l:server_name)
  doautocmd <nomodeline> User lsp_register_server
endfunction

function! easycomplete#lsp#get_server_capabilities(server_name) abort
  let l:server = s:servers[a:server_name]
  return has_key(l:server, 'init_result') ? l:server['init_result']['result']['capabilities'] : {}
endfunction

" call easycomplete#lsp#get_allowed_servers()
" call easycomplete#lsp#get_allowed_servers(bufnr('%'))
" call easycomplete#lsp#get_allowed_servers('typescript')
function! easycomplete#lsp#get_allowed_servers(...) abort
  if a:0 == 0
    let l:buffer_filetype = &filetype
  else
    if type(a:1) == type('')
      let l:buffer_filetype = a:1
    else
      let l:buffer_filetype = getbufvar(a:1, '&filetype')
    endif
  endif

  " TODO: cache active servers per buffer
  let l:active_servers = []

  for l:server_name in keys(s:servers)
    let l:server_info = s:servers[l:server_name]['server_info']
    let l:blocked = 0

    if has_key(l:server_info, 'blocklist')
      let l:blocklistkey = 'blocklist'
    else
      let l:blocklistkey = 'blacklist'
    endif
    if has_key(l:server_info, l:blocklistkey)
      for l:filetype in l:server_info[l:blocklistkey]
        if l:filetype ==? l:buffer_filetype || l:filetype ==# '*'
          let l:blocked = 1
          break
        endif
      endfor
    endif

    if l:blocked
      continue
    endif

    if has_key(l:server_info, 'allowlist')
      let l:allowlistkey = 'allowlist'
    else
      let l:allowlistkey = 'whitelist'
    endif
    if has_key(l:server_info, l:allowlistkey)
      for l:filetype in l:server_info[l:allowlistkey]
        if l:filetype ==? l:buffer_filetype || l:filetype ==# '*'
          let l:active_servers += [l:server_name]
          break
        endif
      endfor
    endif
  endfor

  return l:active_servers
endfunction

function! easycomplete#lsp#get_server_capabilities(server_name) abort
  let l:server = s:servers[a:server_name]
  return has_key(l:server, 'init_result') ? l:server['init_result']['result']['capabilities'] : {}
endfunction

function! easycomplete#lsp#send_request(server_name, request) abort
  echom 3333
  let l:ctx = {
        \ 'server_name': a:server_name,
        \ 'request': copy(a:request),
        \ 'cb': has_key(a:request, 'on_notification') ? a:request['on_notification'] : function('s:Noop'),
        \ }
  let l:ctx['dispose'] = easycomplete#lsp#callbag_pipe(
        \ easycomplete#lsp#request(a:server_name, a:request),
        \ easycomplete#lsp#callbag_subscribe({
        \   'next':{d->l:ctx['cb'](d)},
        \   'error':{e->s:send_request_error(l:ctx, e)},
        \   'complete':{->s:send_request_dispose(l:ctx)},
        \ })
        \)
endfunction

function! easycomplete#lsp#get_text_document_identifier(...) abort
  let l:buf = a:0 > 0 ? a:1 : bufnr('%')
  return { 'uri': easycomplete#lsp#utils#get_buffer_uri(l:buf) }
endfunction

function! s:send_request_dispose(ctx) abort
  " dispose function may not have been created so check before calling
  if has_key(a:ctx, 'dispose')
    call a:ctx['dispose']()
  endif
endfunction

function! s:send_request_error(ctx, error) abort
  call a:ctx['cb'](a:error)
  call s:send_request_dispose(a:ctx)
endfunction

function! easycomplete#lsp#callbag_subscribe(...) abort
  let l:data = {}
  if a:0 > 0 && type(a:1) == type({}) " a:1 { next, error, complete }
    if has_key(a:1, 'next') | let l:data['next'] = a:1['next'] | endif
    if has_key(a:1, 'error') | let l:data['error'] = a:1['error'] | endif
    if has_key(a:1, 'complete') | let l:data['complete'] = a:1['complete'] | endif
  else " a:1 = next, a:2 = error, a:3 = complete
    if a:0 >= 1 | let l:data['next'] = a:1 | endif
    if a:0 >= 2 | let l:data['error'] = a:2 | endif
    if a:0 >= 3 | let l:data['complete'] = a:3 | endif
  endif
  return function('s:subscribeListener', [l:data])
endfunction

function! s:subscribeListener(data, source) abort
  call a:source(0, function('s:subscribeSourceCallback', [a:data]))
  return function('s:subscribeDispose', [a:data])
endfunction

function! s:subscribeDispose(data, ...) abort
  if has_key(a:data, 'talkback') | call a:data['talkback'](2, easycomplete#lsp#callbag_undefined()) | endif
endfunction

function! s:subscribeSourceCallback(data, t, d) abort
  if a:t == 0 | let a:data['talkback'] = a:d | endif
  if a:t == 1 && has_key(a:data, 'next') | call a:data['next'](a:d) | endif
  if a:t == 1 || a:t == 0 | call a:data['talkback'](1, easycomplete#lsp#callbag_undefined()) | endif
  if a:t == 2 && s:isUndefined(a:d) && has_key(a:data, 'complete') | call a:data['complete']() | endif
  if a:t == 2 && !s:isUndefined(a:d) && has_key(a:data, 'error') | call a:data['error'](a:d) | endif
endfunction

function! s:isUndefined(d) abort
    return type(a:d) == s:str_type && a:d ==# s:undefined_token
endfunction

function! easycomplete#lsp#request(server_name, request) abort
  let l:ctx = {
        \ 'server_name': a:server_name,
        \ 'request': copy(a:request),
        \ 'request_id': 0,
        \ 'done': 0,
        \ 'cancelled': 0,
        \ }
  return easycomplete#lsp#callbag_create(function('s:request_create', [l:ctx]))
endfunction

function! s:request_create(ctx, next, error, complete) abort
  let a:ctx['next'] = a:next
  let a:ctx['error'] = a:error
  let a:ctx['complete'] = a:complete
  let a:ctx['bufnr'] = get(a:ctx['request'], 'bufnr', bufnr('%'))
  let a:ctx['request']['on_notification'] = function('s:request_on_notification', [a:ctx])
  call easycomplete#lsp#utils#step#start([
        \ {s->s:ensure_flush(a:ctx['bufnr'], a:ctx['server_name'], s.callback)},
        \ {s->s:is_step_error(s) ? s:request_error(a:ctx, s.result[0]) : s:request_send(a:ctx) },
        \ ])
  return function('s:request_cancel', [a:ctx])
endfunction

function! s:ensure_flush(buf, server_name, cb) abort
  " jayli
  call easycomplete#lsp#utils#step#start([
        \ {s->s:ensure_start(a:buf, a:server_name, s.callback)},
        \ {s->s:is_step_error(s) ? s:throw_step_error(s) : s:ensure_init(a:buf, a:server_name, s.callback)},
        \ {s->s:is_step_error(s) ? s:throw_step_error(s) : s:ensure_conf(a:buf, a:server_name, s.callback)},
        \ {s->s:is_step_error(s) ? s:throw_step_error(s) : s:ensure_open(a:buf, a:server_name, s.callback)},
        \ {s->s:is_step_error(s) ? s:throw_step_error(s) : s:ensure_changed(a:buf, a:server_name, s.callback)},
        \ {s->a:cb(s.result[0])}
        \ ])
endfunction

function! s:ensure_start(buf, server_name, cb) abort
  let l:path = easycomplete#lsp#utils#get_buffer_path(a:buf)

  if easycomplete#lsp#utils#is_remote_uri(l:path)
    let l:msg = s:new_rpc_error('ignoring start server due to remote uri', { 'server_name': a:server_name, 'uri': l:path})
    call s:log(l:msg)
    call a:cb(l:msg)
    return
  endif

  let l:server = s:servers[a:server_name]
  let l:server_info = l:server['server_info']
  if l:server['lsp_id'] > 0
    let l:msg = s:new_rpc_success('server already started', { 'server_name': a:server_name })
    call s:log(l:msg)
    call a:cb(l:msg)
    return
  endif

  if has_key(l:server_info, 'tcp')
    let l:tcp = l:server_info['tcp'](l:server_info)
    let l:lsp_id = easycomplete#lsp#client#start({
          \ 'tcp': l:tcp,
          \ 'on_stderr': function('s:on_stderr', [a:server_name]),
          \ 'on_exit': function('s:on_exit', [a:server_name]),
          \ 'on_notification': function('s:on_notification', [a:server_name]),
          \ 'on_request': function('s:on_request', [a:server_name]),
          \ })
  elseif has_key(l:server_info, 'cmd')
    let l:cmd_type = type(l:server_info['cmd'])
    if l:cmd_type == v:t_list
      let l:cmd = l:server_info['cmd']
    else
      let l:cmd = l:server_info['cmd'](l:server_info)
    endif

    if empty(l:cmd)
      let l:msg = s:new_rpc_error('ignore server start since cmd is empty', { 'server_name': a:server_name })
      call s:log(l:msg)
      call a:cb(l:msg)
      return
    endif

    call lsp#log('Starting server', a:server_name, l:cmd)

    let l:lsp_id = lsp#client#start({
          \ 'cmd': l:cmd,
          \ 'on_stderr': function('s:on_stderr', [a:server_name]),
          \ 'on_exit': function('s:on_exit', [a:server_name]),
          \ 'on_notification': function('s:on_notification', [a:server_name]),
          \ 'on_request': function('s:on_request', [a:server_name]),
          \ })
  endif

  if l:lsp_id > 0
    let l:server['lsp_id'] = l:lsp_id
    let l:msg = s:new_rpc_success('started lsp server successfully', { 'server_name': a:server_name, 'lsp_id': l:lsp_id })
    call s:log(l:msg)
    call a:cb(l:msg)
  else
    let l:msg = s:new_rpc_error('failed to start server', { 'server_name': a:server_name, 'cmd': l:cmd })
    call s:log(l:msg)
    call a:cb(l:msg)
  endif
endfunction

function! s:on_request(server_name, id, request) abort
  call s:log('<---', 's:on_request', a:id, a:request)

  let l:stream_data = { 'server': a:server_name, 'request': a:request }
  call easycomplete#lsp#stream(1, l:stream_data) " notify stream before callbacks

  if a:request['method'] ==# 'workspace/applyEdit'
    call s:workspace_edit_apply_workspace_edit(a:request['params']['edit'])
    call s:send_response(a:server_name, { 'id': a:request['id'], 'result': { 'applied': v:true } })
  elseif a:request['method'] ==# 'workspace/configuration'
    let l:response_items = map(a:request['params']['items'], { key, val -> s:workspace_config_get_value(a:server_name, val) })
    call s:send_response(a:server_name, { 'id': a:request['id'], 'result': l:response_items })
  elseif a:request['method'] ==# 'window/workDoneProgress/create'
    call s:send_response(a:server_name, { 'id': a:request['id'], 'result': v:null})
  else
    " TODO: for now comment this out until we figure out a better solution.
    " We need to comment this out so that others outside of vim-lsp can
    " hook into the stream and provide their own response.
    " " Error returned according to json-rpc specification.
    " call s:send_response(a:server_name, { 'id': a:request['id'], 'error': { 'code': -32601, 'message': 'Method not found' } })
  endif
endfunction

function! s:workspace_edit_apply_workspace_edit(workspace_edit) abort
  let l:loclist_items = []

  if has_key(a:workspace_edit, 'documentChanges')
    for l:text_document_edit in a:workspace_edit['documentChanges']
      let l:loclist_items += s:_apply(l:text_document_edit['textDocument']['uri'], l:text_document_edit['edits'])
    endfor
  elseif has_key(a:workspace_edit, 'changes')
    for [l:uri, l:text_edits] in items(a:workspace_edit['changes'])
      let l:loclist_items += s:_apply(l:uri, l:text_edits)
    endfor
  endif
endfunction

"
" _apply
"
function! s:_apply(uri, text_edits) abort
  call lsp#utils#text_edit#apply_text_edits(a:uri, a:text_edits)
  return lsp#utils#text_edit#_lsp_to_vim_list(a:uri, a:text_edits)
endfunction

function! easycomplete#lsp#get_position(...) abort
  let l:line = line('.')
  let l:char = easycomplete#lsp#utils#to_char('%', l:line, col('.'))
  return { 'line': l:line - 1, 'character': l:char }
endfunction

function! s:workspace_config_get_value(server_name, item) abort
  try
    let l:server_info = easycomplete#lsp#get_server_info(a:server_name)
    let l:config = l:server_info['workspace_config']

    for l:section in split(a:item['section'], '\.')
      let l:config = l:config[l:section]
    endfor

    return l:config
  catch
    return v:null
  endtry
endfunction

function! easycomplete#lsp#get_server_info(server_name) abort
  return s:servers[a:server_name]['server_info']
endfunction

function! s:on_notification(server_name, id, data, event) abort
  call s:log('<---', a:id, a:server_name, a:data)
  let l:response = a:data['response']
  let l:server = s:servers[a:server_name]
  let l:server_info = l:server['server_info']

  let l:stream_data = { 'server': a:server_name, 'response': l:response }
  if has_key(a:data, 'request')
    let l:stream_data['request'] = a:data['request']
  endif
  call easycomplete#lsp#stream(1, l:stream_data) " notify stream before callbacks

  if easycomplete#lsp#client#is_server_instantiated_notification(a:data)
    if has_key(l:response, 'method')
      if l:response['method'] ==# 'textDocument/semanticHighlighting'
        " call lsp#ui#vim#semantic#handle_semantic(a:server_name, a:data)
      endif
    endif
  else
    let l:request = a:data['request']
    let l:method = l:request['method']
    if l:method ==# 'initialize'
      call s:handle_initialize(a:server_name, a:data)
    endif
  endif

  for l:callback_info in s:notification_callbacks
    call l:callback_info.callback(a:server_name, a:data)
  endfor
endfunction

function! s:handle_initialize(server_name, data) abort
  let l:response = a:data['response']
  let l:server = s:servers[a:server_name]

  if has_key(l:server, 'exited')
    unlet l:server['exited']
  endif

  let l:init_callbacks = l:server['init_callbacks']
  unlet l:server['init_callbacks']

  if !easycomplete#lsp#client#is_error(l:response)
    let l:server['init_result'] = l:response
    " Delete cache of trigger chars
    if has_key(b:, 'lsp_signature_help_trigger_character')
      unlet b:lsp_signature_help_trigger_character
    endif
  else
    let l:server['failed'] = l:response['error']
    call easycomplete#lsp#utils#error('Failed to initialize ' . a:server_name .
          \ ' with error ' . l:response['error']['code'] . ': ' . l:response['error']['message'])
  endif

  call s:send_notification(a:server_name, { 'method': 'initialized', 'params': {} })

  for l:Init_callback in l:init_callbacks
    call l:Init_callback(a:data)
  endfor

  doautocmd <nomodeline> User lsp_server_init
endfunction

function! s:send_notification(server_name, data) abort
  let l:lsp_id = s:servers[a:server_name]['lsp_id']
  let l:data = copy(a:data)
  if has_key(l:data, 'on_notification')
    let l:data['on_notification'] = '---funcref---'
  endif
  call s:log('--->', l:lsp_id, a:server_name, l:data)
  call easycomplete#lsp#client#send_notification(l:lsp_id, a:data)
endfunction

function! s:on_stderr(server_name, id, data, event) abort
  call s:log('<---(stderr)', a:id, a:server_name, a:data)
endfunction

function! s:on_exit(server_name, id, data, event) abort
  call s:log('s:on_exit', a:id, a:server_name, 'exited', a:data)
  if has_key(s:servers, a:server_name)
    let l:server = s:servers[a:server_name]
    let l:server['lsp_id'] = 0
    let l:server['buffers'] = {}
    let l:server['exited'] = 1
    if has_key(l:server, 'init_result')
      unlet l:server['init_result']
    endif
    call easycomplete#lsp#stream(1, { 'server': '$vimlsp',
          \ 'response': { 'method': '$/vimlsp/lsp_server_exit', 'params': { 'server': a:server_name } } })
    doautocmd <nomodeline> User lsp_server_exit
  endif
endfunction

function! easycomplete#lsp#stream(...) abort
  let s:Stream = easycomplete#lsp#callbag_makeSubject()
  if a:0 == 0
    return easycomplete#lsp#callbag_share(s:Stream)
  else
    call s:Stream(a:1, a:2)
  endif
endfunction

function! s:shareFactory(data, start, sink) abort
  if a:start != 0 | return | endif
  call add(a:data['sinks'], a:sink)

  let a:data['talkback'] = function('s:shareTalkbackCallback', [a:data, a:sink])

  if len(a:data['sinks']) == 1
    call a:data['source'](0, function('s:shareSourceCallback', [a:data, a:sink]))
    return
  endif

  call a:sink(0, a:data['talkback'])
endfunction

function! s:shareSourceCallback(data, sink, t, d) abort
  if a:t == 0
    let a:data['sourceTalkback'] = a:d
    call a:sink(0, a:data['talkback'])
  else
    for l:S in a:data['sinks']
      call l:S(a:t, a:d)
    endfor
  endif
  if a:t == 2
    let a:data['sinks'] = []
  endif
endfunction

function! s:shareTalkbackCallback(data, sink, t, d) abort
  if a:t == 2
    let l:i = 0
    let l:found = 0
    while l:i < len(a:data['sinks'])
      if a:data['sinks'][l:i] == a:sink
        let l:found = 1
        break
      endif
      let l:i += 1
    endwhile

    if l:found
      call remove(a:data['sinks'], l:i)
    endif

    if empty(a:data['sinks'])
      call a:data['sourceTalkback'](2, easycomplete#lsp#callbag_undefined())
    endif
  else
    call a:data['sourceTalkback'](a:t, a:d)
  endif
endfunction

function! easycomplete#lsp#callbag_undefined() abort
  return s:undefined_token
endfunction

function! easycomplete#lsp#callbag_makeSubject() abort
  let l:data = { 'sinks': [] }
  return function('s:makeSubjectFactory', [l:data])
endfunction


function! s:makeSubjectFactory(data, t, d) abort
  if a:t == 0
    let l:Sink = a:d
    call add(a:data['sinks'], l:Sink)
    call l:Sink(0, function('s:makeSubjectSinkCallback', [a:data, l:Sink]))
  else
    let l:zinkz = copy(a:data['sinks'])
    let l:i = 0
    let l:n = len(l:zinkz)
    while l:i < l:n
      let l:Sink = l:zinkz[l:i]
      let l:j = -1
      let l:found = 0
      for l:Item in a:data['sinks']
        let l:j += 1
        if l:Item == l:Sink
          let l:found = 1
          break
        endif
      endfor

      if l:found
        call l:Sink(a:t, a:d)
      endif
      let l:i += 1
    endwhile
  endif
endfunction

function! s:makeSubjectSinkCallback(data, Sink, t, d) abort
  if a:t == 2
    let l:i = -1
    let l:found = 0
    for l:Item in a:data['sinks']
      let l:i += 1
      if l:Item == a:Sink
        let l:found = 1
        break
      endif
    endfor
    if l:found
      call remove(a:data['sinks'], l:i)
    endif
  endif
endfunction


function! easycomplete#lsp#callbag_share(source) abort
    let l:data = { 'source': a:source, 'sinks': [] }
    return function('s:shareFactory', [l:data])
endfunction

function! s:new_rpc_success(message, data) abort
  return {
        \ 'response': {
        \   'message': a:message,
        \   'data': extend({ '__data__': 'vim-lsp'}, a:data),
        \ }
        \ }
endfunction

function! s:new_rpc_error(message, data) abort
  return {
        \ 'response': {
        \   'error': {
        \       'code': 0,
        \       'message': a:message,
        \       'data': extend({ '__error__': 'vim-lsp'}, a:data),
        \   },
        \ }
        \ }
endfunction

function! s:request_on_notification(ctx, id, data, event) abort
  if a:ctx['cancelled'] | return | endif " caller already unsubscribed so don't bother notifying
  let a:ctx['done'] = 1
  call a:ctx['next'](extend({ 'server_name': a:ctx['server_name'] }, a:data))
  call a:ctx['complete']()
endfunction

function! easycomplete#lsp#callbag_create(...) abort
    let l:data = {}
    if a:0 > 0
        let l:data['prod'] = a:1
    endif
    return function('s:createProd', [l:data])
endfunction

function! easycomplete#lsp#callbag_pipe(...) abort
    let l:Res = a:1
    let l:i = 1
    while l:i < a:0
        let l:Res = a:000[l:i](l:Res)
        let l:i = l:i + 1
    endwhile
    return l:Res
endfunction

function! s:log(...)
  let l:args = a:000
  let l:res = ""
  if empty(a:000)
    let l:res = ""
  elseif len(a:000) == 1
    if index([2,7], type(a:000))
      let l:res = string(a:1)
    else
      let l:res = a:1
    endif
  else
    for item in l:args
      let l:res = l:res . " " . json_encode(item)
    endfor
  endif
  echohl MoreMsg
  echom '>>> '. l:res
  echohl NONE
endfunction
