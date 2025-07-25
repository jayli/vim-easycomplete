let s:save_cpo = &cpoptions
set cpoptions&vim

let s:clients = {} " { client_id: ctx }

function! s:create_context(client_id, opts) abort
  if a:client_id <= 0
    return {}
  endif

  let l:ctx = {
        \ 'opts': a:opts,
        \ 'buffer': '',
        \ 'content-length': -1,
        \ 'requests': {},
        \ 'request_sequence': 0,
        \ 'on_notifications': {},
        \ }

  let s:clients[a:client_id] = l:ctx

  return l:ctx
endfunction

function! s:dispose_context(client_id) abort
  if a:client_id > 0
    if has_key(s:clients, a:client_id)
      unlet s:clients[a:client_id]
    endif
  endif
endfunction

function! s:on_stdout(id, data, event) abort
  let l:ctx = get(s:clients, a:id, {})

  if empty(l:ctx)
    return
  endif

  if empty(l:ctx['buffer'])
    let l:ctx['buffer'] = join(a:data, "\n")
  else
    let l:ctx['buffer'] .= join(a:data, "\n")
  endif

  while 1
    if l:ctx['content-length'] < 0
      " wait for all headers to arrive
      let l:header_end_index = stridx(l:ctx['buffer'], "\r\n\r\n")
      if l:header_end_index < 0
        " no headers found
        return
      endif
      let l:headers = l:ctx['buffer'][:l:header_end_index - 1]
      let l:ctx['content-length'] = s:get_content_length(l:headers)
      if l:ctx['content-length'] < 0
        " invalid content-length
        call s:errlog("[LOG]", 'on_stdout', a:id, 'invalid content-length')
        call s:lsp_stop(a:id)
        return
      endif
      let l:ctx['buffer'] = l:ctx['buffer'][l:header_end_index + 4:] " 4 = len(\r\n\r\n)
    endif

    if len(l:ctx['buffer']) < l:ctx['content-length']
      " incomplete message, wait for next buffer to arrive
      return
    endif

    " we have full message
    let l:response_str = l:ctx['buffer'][:l:ctx['content-length'] - 1]
    let l:ctx['content-length'] = -1

    try
      let l:response = json_decode(l:response_str)
    catch
      call s:errlog("[ERR]", 's:on_stdout json_decode failed', v:exception)
    endtry

    let l:ctx['buffer'] = l:ctx['buffer'][len(l:response_str):]

    if exists('l:response')
      " call appropriate callbacks
      let l:on_notification_data = { 'response': l:response }
      if has_key(l:response, 'method') && has_key(l:response, 'id')
        " it is a request from a server
        let l:request = l:response
        if has_key(l:ctx['opts'], 'on_request')
          call l:ctx['opts']['on_request'](a:id, l:request)
        endif
      elseif has_key(l:response, 'id')
        " it is a request->response
        if !(type(l:response['id']) == type(0) || type(l:response['id']) == type(''))
          " response['id'] can be number | string | null based on the spec
          call s:errlog("[ERR]", 'invalid response id. ignoring message', l:response)
          continue
        endif
        if has_key(l:ctx['requests'], l:response['id'])
          let l:on_notification_data['request'] = l:ctx['requests'][l:response['id']]
        endif
        if has_key(l:ctx['opts'], 'on_notification')
          " call client's on_notification first
          try
            call l:ctx['opts']['on_notification'](a:id, l:on_notification_data, 'on_notification')
          catch
            call s:errlog("[ERR]", 's:on_stdout client option on_notification() error', v:exception, v:throwpoint)
          endtry
        endif
        if has_key(l:ctx['on_notifications'], l:response['id'])
          " call easycomplete#lsp#client#send({ 'on_notification }) second
          try
            call l:ctx['on_notifications'][l:response['id']](a:id, l:on_notification_data, 'on_notification')
          catch
            call s:errlog("[ERR]", 's:on_stdout client request on_notification() error', v:exception, v:throwpoint)
          endtry
          unlet l:ctx['on_notifications'][l:response['id']]
        endif
        if has_key(l:ctx['requests'], l:response['id'])
          unlet l:ctx['requests'][l:response['id']]
        else
          call s:errlog("[ERR]", 'cannot find the request corresponding to response: ', l:response)
        endif
      else
        " it is a notification
        if has_key(l:ctx['opts'], 'on_notification')
          try
            call l:ctx['opts']['on_notification'](a:id, l:on_notification_data, 'on_notification')
          catch
            call s:errlog("[ERR]", 's:on_stdout on_notification() error', v:exception, v:throwpoint)
          endtry
        endif
      endif
    endif

    if empty(l:response_str)
      " buffer is empty, wait for next message to arrive
      return
    endif
  endwhile
endfunction

function! s:get_content_length(headers) abort
  for l:header in split(a:headers, "\r\n")
    let l:kvp = split(l:header, ':')
    if len(l:kvp) == 2
      if l:kvp[0] =~? '^Content-Length'
        return str2nr(l:kvp[1], 10)
      endif
    endif
  endfor
  return -1
endfunction

function! s:on_stderr(id, data, event) abort
  let l:ctx = get(s:clients, a:id, {})
  if empty(l:ctx)
    return
  endif
  if has_key(l:ctx['opts'], 'on_stderr')
    try
      call l:ctx['opts']['on_stderr'](a:id, a:data, a:event)
    catch
      call s:errlog("[ERR]", 's:on_stderr exception', v:exception, v:throwpoint)
      echom v:exception
    endtry
  endif
endfunction

function! s:on_exit(id, status, event) abort
  let l:ctx = get(s:clients, a:id, {})
  if empty(l:ctx)
    return
  endif
  if has_key(l:ctx['opts'], 'on_exit')
    try
      call l:ctx['opts']['on_exit'](a:id, a:status, a:event)
    catch
      call s:errlog("[ERR]", 's:on_exit exception', v:exception, v:throwpoint)
      echom v:exception
    endtry
  endif
  call s:dispose_context(a:id)
endfunction

function! s:lsp_start(opts) abort
  " let l:jobopt = { 'in_mode': 'lsp', 'out_mode': 'lsp', 'noblock': 1,
  "     \ 'out_cb': function('s:native_out_cb', [l:cbctx]),
  "     \ 'err_cb': function('s:native_err_cb', [l:cbctx]),
  "     \ 'exit_cb': function('s:native_exit_cb', [l:cbctx]),
  "     \ }
  if has_key(a:opts, 'cmd')
    let l:client_id = easycomplete#job#start(a:opts.cmd, {
          \ 'in_mode': 'lsp', 'out_mode': 'lsp', 'noblock': 1,
          \ 'on_stdout': function('s:on_stdout'),
          \ 'on_stderr': function('s:on_stderr'),
          \ 'on_exit': function('s:on_exit'),
          \ })
  elseif has_key(a:opts, 'tcp')
    let l:client_id = easycomplete#job#connect(a:opts.tcp, {
          \ 'on_stdout': function('s:on_stdout'),
          \ 'on_stderr': function('s:on_stderr'),
          \ 'on_exit': function('s:on_exit'),
          \ })
  else
    return -1
  endif
  let l:ctx = s:create_context(l:client_id, a:opts)
  let l:ctx['id'] = l:client_id
  return l:client_id
endfunction

function! s:lsp_stop(id) abort
  call easycomplete#job#stop(a:id)
endfunction

let s:send_type_request = 1
let s:send_type_notification = 2
let s:send_type_response = 3
function! s:lsp_send(id, opts, type) abort " opts = { id?, method?, result?, params?, on_notification }
  let l:ctx = get(s:clients, a:id, {})
  if empty(l:ctx)
    return -1
  endif

  let l:request = { 'jsonrpc': '2.0' }

  if (a:type == s:send_type_request)
    let l:ctx['request_sequence'] = l:ctx['request_sequence'] + 1
    let l:request['id'] = l:ctx['request_sequence']
    let l:ctx['requests'][l:request['id']] = l:request
    if has_key(a:opts, 'on_notification')
      let l:ctx['on_notifications'][l:request['id']] = a:opts['on_notification']
    endif
  endif

  if has_key(a:opts, 'id')
    let l:request['id'] = a:opts['id']
  endif
  if has_key(a:opts, 'method')
    let l:request['method'] = a:opts['method']
  endif
  if has_key(a:opts, 'params')
    let l:request['params'] = a:opts['params']
  endif
  if has_key(a:opts, 'result')
    let l:request['result'] = a:opts['result']
  endif
  if has_key(a:opts, 'error')
    let l:request['error'] = a:opts['error']
  endif

  let l:json = json_encode(l:request)
  let l:payload = 'Content-Length: ' . len(l:json) . "\r\n\r\n" . l:json

  call easycomplete#job#send(a:id, l:payload)

  if (a:type == s:send_type_request)
    let l:id = l:request['id']
    if get(a:opts, 'sync', 0) !=# 0
      let l:timeout = get(a:opts, 'sync_timeout', -1)
      if easycomplete#lsp#utils#_wait(l:timeout, {-> !has_key(l:ctx['requests'], l:request['id'])}, 1) == -1
        throw 'lsp#client: timeout'
      endif
    endif
    return l:id
  else
    return 0
  endif
endfunction

function! s:lsp_get_last_request_id(id) abort
  return s:clients[a:id]['request_sequence']
endfunction

function! s:lsp_is_error(obj_or_response) abort
  let l:vt = type(a:obj_or_response)
  if l:vt == type('')
    return len(a:obj_or_response) > 0
  elseif l:vt == type({})
    return has_key(a:obj_or_response, 'error')
  endif
  return 0
endfunction

function! s:errlog(...)
  return call('easycomplete#util#errlog', a:000)
endfunction

function! s:is_server_instantiated_notification(notification) abort
  return !has_key(a:notification, 'request')
endfunction

" public apis {{{

function! easycomplete#lsp#client#start(opts) abort
  let job_id = s:lsp_start(a:opts)
  call s:errlog("LSP job start", job_id)
  return job_id
endfunction

" #222
function! easycomplete#lsp#client#stop(client_id) abort
  let l:client_job = 0
  if exists("b:lsp_job_id") && b:lsp_job_id != 0 && a:client_id == 0
    let l:client_job = b:lsp_job_id
  else
    let l:client_job = a:client_id
  endif

  if l:client_job > 0
    call s:errlog('[LOG]','lsp job stop, job id is', string(b:lsp_job_id))
    return s:lsp_stop(l:client_job)
  else
    return 0
  endif
endfunction

function! easycomplete#lsp#client#send_request(client_id, opts) abort
  return s:lsp_send(a:client_id, a:opts, s:send_type_request)
endfunction

function! easycomplete#lsp#client#send_notification(client_id, opts) abort
  return s:lsp_send(a:client_id, a:opts, s:send_type_notification)
endfunction

function! easycomplete#lsp#client#send_response(client_id, opts) abort
  return s:lsp_send(a:client_id, a:opts, s:send_type_response)
endfunction

function! easycomplete#lsp#client#get_last_request_id(client_id) abort
  return s:lsp_get_last_request_id(a:client_id)
endfunction

function! easycomplete#lsp#client#is_error(obj_or_response) abort
  return s:lsp_is_error(a:obj_or_response)
endfunction

function! easycomplete#lsp#client#error_message(obj_or_response) abort
  try
    return a:obj_or_response['error']['data']['message']
  catch
  endtry
  try
    return a:obj_or_response['error']['message']
  catch
  endtry
  return string(a:obj_or_response)
endfunction

function! easycomplete#lsp#client#is_server_instantiated_notification(notification) abort
  return s:is_server_instantiated_notification(a:notification)
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction

" }}}

let &cpoptions = s:save_cpo
unlet s:save_cpo
" vim sw=2 ts=2 et
