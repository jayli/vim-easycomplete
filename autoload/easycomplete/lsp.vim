let s:enabled = 0
let s:fixendofline_exists = exists('+fixendofline')
" let s:Stream = easycomplete#lsp#callbag_makeSubject()
let s:already_setup = 0
let s:servers = {} " { lsp_id, server_info, init_callbacks, init_result, buffers: { path: { changed_tick } }
let s:last_command_id = 0
let s:notification_callbacks = [] " { name, callback }

let s:undefined_token = '__callbag_undefined__'
let s:str_type = type('')
" vim-lsp/autoload/lsp/ui/vim/folding.vim
let s:folding_ranges = {}
let s:textprop_name = 'vim-lsp-folding-linenr'

let s:default_symbol_kinds = {
    \ '1': 'file',
    \ '2': 'module',
    \ '3': 'namespace',
    \ '4': 'package',
    \ '5': 'class',
    \ '6': 'method',
    \ '7': 'property',
    \ '8': 'field',
    \ '9': 'constructor',
    \ '10': 'enum',
    \ '11': 'interface',
    \ '12': 'function',
    \ '13': 'variable',
    \ '14': 'constant',
    \ '15': 'string',
    \ '16': 'number',
    \ '17': 'boolean',
    \ '18': 'array',
    \ '19': 'object',
    \ '20': 'key',
    \ '21': 'null',
    \ '22': 'enum member',
    \ '23': 'struct',
    \ '24': 'event',
    \ '25': 'operator',
    \ '26': 'type parameter',
    \ }

let s:default_completion_item_kinds = {
      \ '1': 'text',
      \ '2': 'method',
      \ '3': 'function',
      \ '4': 'constructor',
      \ '5': 'field',
      \ '6': 'variable',
      \ '7': 'class',
      \ '8': 'interface',
      \ '9': 'module',
      \ '10': 'property',
      \ '11': 'unit',
      \ '12': 'value',
      \ '13': 'enum',
      \ '14': 'keyword',
      \ '15': 'snippet',
      \ '16': 'color',
      \ '17': 'file',
      \ '18': 'reference',
      \ '19': 'folder',
      \ '20': 'enum member',
      \ '21': 'constant',
      \ '22': 'struct',
      \ '23': 'event',
      \ '24': 'operator',
      \ '25': 'type parameter',
      \ }

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

augroup lsp_silent
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

function! easycomplete#lsp#enable()
  call s:register_events()
endfunction

function! s:register_events() abort
  augroup lsp
    autocmd!
  augroup END

  augroup lsp
    autocmd!
    autocmd BufNewFile * call s:on_text_document_did_open()
    autocmd BufReadPost * call s:on_text_document_did_open()
    autocmd BufWritePost * call s:on_text_document_did_save()
    autocmd BufWinLeave * call s:on_text_document_did_close()
  augroup END
  for l:bufnr in range(1, bufnr('$'))
    if bufexists(l:bufnr) && bufloaded(l:bufnr)
      call s:on_text_document_did_open(l:bufnr)
    endif
  endfor
endfunction

function! s:on_text_document_did_close() abort
    let l:buf = bufnr('%')
    if getbufvar(l:buf, '&buftype') ==# 'terminal' | return | endif
    call s:log('s:on_text_document_did_close()', l:buf)
endfunction

function! s:on_text_document_did_save() abort
endfunction

function! s:on_text_document_did_open(...) abort
  let l:buf = a:0 > 0 ? a:1 : bufnr('%')
  if getbufvar(l:buf, '&buftype') ==# 'terminal' | return | endif
  if getcmdwintype() !=# '' | return | endif
  call s:log('s:on_text_document_did_open()', l:buf, &filetype, getcwd(), easycomplete#lsp#utils#get_buffer_uri(l:buf))

  " Some language server notify diagnostics to the buffer that has not been loaded yet.
  " This diagnostics was stored `autoload/lsp/internal/diagnostics/state.vim` but not highlighted.
  " So we should refresh highlights when buffer opened.
  " call lsp#internal#diagnostics#state#_force_notify_buffer(l:buf)

  for l:server_name in easycomplete#lsp#get_allowed_servers(l:buf)
    call s:ensure_flush(l:buf, l:server_name, function('s:fire_lsp_buffer_enabled', [l:server_name, l:buf]))
  endfor
endfunction

function! s:fire_lsp_buffer_enabled(server_name, buf, ...) abort
  if a:buf == bufnr('%')
    doautocmd <nomodeline> User lsp_buffer_enabled
  else
    " Not using ++once in autocmd for compatibility of VIM8.0
    let l:cmd = printf('autocmd BufEnter <buffer=%d> doautocmd <nomodeline> User lsp_buffer_enabled', a:buf)
    exec printf('augroup _lsp_fire_buffer_enabled | exec "%s | autocmd! _lsp_fire_buffer_enabled BufEnter <buffer>" | augroup END', l:cmd)
  endif
endfunction

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
  " call s:log('easycomplete#lsp#register_server', 'server registered', l:server_name)
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

function! s:Noop(...) abort
endfunction

function! easycomplete#lsp#send_request(server_name, request) abort
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

function! s:is_step_error(s) abort
  return easycomplete#lsp#client#is_error(a:s.result[0]['response'])
endfunction

function! s:ensure_init(buf, server_name, cb) abort
  let l:server = s:servers[a:server_name]

  if has_key(l:server, 'init_result')
    let l:msg = s:new_rpc_success('lsp server already initialized', { 'server_name': a:server_name, 'init_result': l:server['init_result'] })
    call s:log(l:msg)
    call a:cb(l:msg)
    return
  endif

  if has_key(l:server, 'init_callbacks')
    " waiting for initialize response
    call add(l:server['init_callbacks'], a:cb)
    let l:msg = s:new_rpc_success('waiting for lsp server to initialize', { 'server_name': a:server_name })
    call s:log(l:msg)
    return
  endif

  " server has already started, but not initialized

  let l:server_info = l:server['server_info']
  let l:root_uri = has_key(l:server_info, 'root_uri') ?  l:server_info['root_uri'](l:server_info) : ''
  if empty(l:root_uri)
    let l:msg = s:new_rpc_error('ignore initialization lsp server due to empty root_uri', { 'server_name': a:server_name, 'lsp_id': l:server['lsp_id'] })
    call s:log(l:msg)
    let l:root_uri = easycomplete#lsp#utils#get_default_root_uri()
  endif
  let l:server['server_info']['_root_uri_resolved'] = l:root_uri

  if has_key(l:server_info, 'capabilities')
    let l:capabilities = l:server_info['capabilities']
  else
    let l:capabilities = call(function('easycomplete#lsp#default_get_supported_capabilities'), [l:server_info])
  endif

  let l:request = {
        \   'method': 'initialize',
        \   'params': {
        \     'processId': getpid(),
        \     'clientInfo': { 'name': 'vim-lsp' },
        \     'capabilities': l:capabilities,
        \     'rootUri': l:root_uri,
        \     'rootPath': easycomplete#lsp#utils#uri_to_path(l:root_uri),
        \     'trace': 'off',
        \   },
        \ }

  if has_key(l:server_info, 'initialization_options')
    let l:request.params['initializationOptions'] = l:server_info['initialization_options']
  endif

  let l:server['init_callbacks'] = [a:cb]

  call s:send_request(a:server_name, l:request)
endfunction

function! s:send_request(server_name, data) abort
  let l:lsp_id = s:servers[a:server_name]['lsp_id']
  let l:data = copy(a:data)
  if has_key(l:data, 'on_notification')
    let l:data['on_notification'] = '---funcref---'
  endif
  call s:log('--->', l:lsp_id, a:server_name, l:data)
  return easycomplete#lsp#client#send_request(l:lsp_id, a:data)
endfunction

function! s:throw_step_error(s) abort
  call a:s.callback(a:s.result[0])
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

function! s:get_fixendofline(buf) abort
  let l:eol = getbufvar(a:buf, '&endofline')
  let l:binary = getbufvar(a:buf, '&binary')

  if s:fixendofline_exists
    let l:fixeol = getbufvar(a:buf, '&fixendofline')

    if !l:binary
      " When 'binary' is off and 'fixeol' is on, 'endofline' is not used
      "
      " When 'binary' is off and 'fixeol' is off, 'endofline' is used to
      " remember the presence of a <EOL>
      return l:fixeol || l:eol
    else
      " When 'binary' is on, the value of 'fixeol' doesn't matter
      return l:eol
    endif
  else
    " When 'binary' is off the value of 'endofline' is not used
    "
    " When 'binary' is on 'endofline' is used to remember the presence of
    " a <EOL>
    return !l:binary || l:eol
  endif
endfunction

function! s:get_lines(buf) abort
  let l:lines = getbufline(a:buf, 1, '$')
  if s:get_fixendofline(a:buf)
    let l:lines += ['']
  endif
  return l:lines
endfunction

function! s:ensure_open(buf, server_name, cb) abort
  let l:server = s:servers[a:server_name]
  let l:path = easycomplete#lsp#utils#get_buffer_uri(a:buf)

  if empty(l:path)
    let l:msg = s:new_rpc_success('ignore open since not a valid uri', { 'server_name': a:server_name, 'path': l:path })
    call s:log(l:msg)
    call a:cb(l:msg)
    return
  endif

  let l:buffers = l:server['buffers']

  if has_key(l:buffers, l:path)
    let l:msg = s:new_rpc_success('already opened', { 'server_name': a:server_name, 'path': l:path })
    call s:log(l:msg)
    call a:cb(l:msg)
    return
  endif

  call s:update_file_content(a:buf, a:server_name, s:get_lines(a:buf))

  let l:buffer_info = { 'changed_tick': getbufvar(a:buf, 'changedtick'), 'version': 1, 'uri': l:path }
  let l:buffers[l:path] = l:buffer_info

  call s:send_notification(a:server_name, {
        \ 'method': 'textDocument/didOpen',
        \ 'params': {
        \   'textDocument': s:get_text_document(a:buf, a:server_name, l:buffer_info)
        \ },
        \ })

  call s:folding_send_request(a:server_name, a:buf, 0)

  let l:msg = s:new_rpc_success('textDocument/open sent', { 'server_name': a:server_name, 'path': l:path, 'filetype': getbufvar(a:buf, '&filetype') })
  call s:log(l:msg)
  call a:cb(l:msg)
endfunction

function! s:folding_send_request(server_name, buf, sync) abort
  if !lsp#capabilities#has_folding_range_provider(a:server_name)
    return
  endif

  if has('textprop')
    call s:set_textprops(a:buf)
  endif

  call easycomplete#lsp#send_request(a:server_name, {
        \ 'method': 'textDocument/foldingRange',
        \ 'params': {
        \   'textDocument': easycomplete#lsp#get_text_document_identifier(a:buf)
        \ },
        \ 'on_notification': function('s:handle_fold_request', [a:server_name]),
        \ 'sync': a:sync,
        \ 'bufnr': a:buf
        \ })
endfunction

function! s:set_textprops(buf) abort
  " Use zero-width text properties to act as a sort of "mark" in the buffer.
  " This is used to remember the line numbers at the time the request was
  " sent. We will let Vim handle updating the line numbers when the user
  " inserts or deletes text.

  " Skip if the buffer doesn't exist. This might happen when a buffer is
  " opened and quickly deleted.
  if !bufloaded(a:buf) | return | endif

  " Create text property, if not already defined
  silent! call prop_type_add(s:textprop_name, {'bufnr': a:buf})

  let l:line_count = s:get_line_count_buf(a:buf)

  " First, clear all markers from the previous run
  call prop_remove({'type': s:textprop_name, 'bufnr': a:buf}, 1, l:line_count)

  " Add markers to each line
  let l:i = 1
  while l:i <= l:line_count
    call prop_add(l:i, 1, {'bufnr': a:buf, 'type': s:textprop_name, 'id': l:i})
    let l:i += 1
  endwhile
endfunction

function! s:get_line_count_buf(buf) abort
  if !has('patch-8.1.1967')
    return line('$')
  endif
  let l:winids = win_findbuf(a:buf)
  return empty(l:winids) ? line('$') : line('$', l:winids[0])
endfunction

function! s:get_text_document_text(buf, server_name) abort
  return join(s:get_last_file_content(a:buf, a:server_name), "\n")
endfunction

function! s:get_last_file_content(buf, server_name) abort
  if has_key(s:file_content, a:buf) && has_key(s:file_content[a:buf], a:server_name)
    return s:file_content[a:buf][a:server_name]
  endif
  return []
endfunction

function! s:get_text_document(buf, server_name, buffer_info) abort
  let l:server = s:servers[a:server_name]
  let l:server_info = l:server['server_info']
  let l:language_id = has_key(l:server_info, 'languageId') ?  l:server_info['languageId'](l:server_info) : &filetype
  return {
        \ 'uri': easycomplete#lsp#utils#get_buffer_uri(a:buf),
        \ 'languageId': l:language_id,
        \ 'version': a:buffer_info['version'],
        \ 'text': s:get_text_document_text(a:buf, a:server_name),
        \ }
endfunction

function! s:ensure_conf(buf, server_name, cb) abort
  let l:server = s:servers[a:server_name]
  let l:server_info = l:server['server_info']
  if has_key(l:server_info, 'workspace_config')
    let l:workspace_config = l:server_info['workspace_config']
    call s:send_notification(a:server_name, {
          \ 'method': 'workspace/didChangeConfiguration',
          \ 'params': {
          \   'settings': l:workspace_config,
          \ }
          \ })
  endif
  let l:msg = s:new_rpc_success('configuration sent', { 'server_name': a:server_name })
  call s:log(l:msg)
  call a:cb(l:msg)
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

    call s:log('Starting server', a:server_name, l:cmd)

    let l:lsp_id = easycomplete#lsp#client#start({
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
  call easycomplete#lsp#utils#text_edit#apply_text_edits(a:uri, a:text_edits)
  return easycomplete#lsp#utils#text_edit#_lsp_to_vim_list(a:uri, a:text_edits)
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
  echom '>>>> ' . string(a:data)
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
  " jayli TODO 这里执行一次就不再往下走了，很奇怪，正常启动文件会执行四次
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
  return
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

function! easycomplete#lsp#default_get_supported_capabilities(server_info) abort
    " Sorted alphabetically
    return {
    \   'textDocument': {
    \       'codeAction': {
    \         'dynamicRegistration': v:false,
    \         'codeActionLiteralSupport': {
    \           'codeActionKind': {
    \             'valueSet': ['', 'quickfix', 'refactor', 'refactor.extract', 'refactor.inline', 'refactor.rewrite', 'source', 'source.organizeImports'],
    \           }
    \         },
    \         'disabledSupport': v:true,
    \       },
    \       'codeLens': {
    \           'dynamicRegistration': v:false,
    \       },
    \       'completion': {
    \           'dynamicRegistration': v:false,
    \           'completionItem': {
    \              'documentationFormat': ['markdown', 'plaintext'],
    \              'snippetSupport': v:false,
    \              'resolveSupport': {
    \                  'properties': ['additionalTextEdits']
    \              }
    \           },
    \           'completionItemKind': {
    \              'valueSet': s:get_completion_item_kinds()
    \           }
    \       },
    \       'declaration': {
    \           'dynamicRegistration': v:false,
    \           'linkSupport' : v:true
    \       },
    \       'definition': {
    \           'dynamicRegistration': v:false,
    \           'linkSupport' : v:true
    \       },
    \       'documentHighlight': {
    \           'dynamicRegistration': v:false,
    \       },
    \       'documentSymbol': {
    \           'dynamicRegistration': v:false,
    \           'symbolKind': {
    \              'valueSet': s:get_symbol_kinds()
    \           },
    \           'hierarchicalDocumentSymbolSupport': v:false,
    \           'labelSupport': v:false
    \       },
    \       'foldingRange': {
    \           'dynamicRegistration': v:false,
    \           'lineFoldingOnly': v:true,
    \           'rangeLimit': 5000,
    \       },
    \       'formatting': {
    \           'dynamicRegistration': v:false,
    \       },
    \       'hover': {
    \           'dynamicRegistration': v:false,
    \           'contentFormat': ['markdown', 'plaintext'],
    \       },
    \       'implementation': {
    \           'dynamicRegistration': v:false,
    \           'linkSupport' : v:true
    \       },
    \       'rangeFormatting': {
    \           'dynamicRegistration': v:false,
    \       },
    \       'references': {
    \           'dynamicRegistration': v:false,
    \       },
    \       'semanticHighlightingCapabilities': {
    \           'semanticHighlighting': v:false
    \       },
    \       'synchronization': {
    \           'didSave': v:true,
    \           'dynamicRegistration': v:false,
    \           'willSave': v:false,
    \           'willSaveWaitUntil': v:false,
    \       },
    \       'typeHierarchy': v:false,
    \       'typeDefinition': {
    \           'dynamicRegistration': v:false,
    \           'linkSupport' : v:true
    \       },
    \   },
    \   'window': {
    \       'workDoneProgress': v:false
    \   },
    \   'workspace': {
    \       'applyEdit': v:true,
    \       'configuration': v:true
    \   },
    \ }
endfunction

function! s:get_completion_item_kinds() abort
  return map(keys(s:default_completion_item_kinds), {idx, key -> str2nr(key)})
endfunction

function! s:get_symbol_kinds() abort
    return map(keys(s:default_symbol_kinds), {idx, key -> str2nr(key)})
endfunction
