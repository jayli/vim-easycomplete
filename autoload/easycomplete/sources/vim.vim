if get(g:, 'easycomplete_sources_vim')
  finish
endif
let g:easycomplete_sources_vim = 1

let s:servers = {} " { server_name: 1 }

function! easycomplete#sources#vim#constructor(opt, ctx)
  call lsp#register_server({
        \ 'name': 'efm-langserver',
        \ 'cmd': {server_info->['efm-langserver', '-c=/path/to/your/config.yaml']},
        \ 'allowlist': ['vim'],
        \ })
  doautocmd <nomodeline> User lsp_server_init

"   augroup asyncomplete_lsp
"     au!
"     au User lsp_server_init call s:server_initialized()
"     au User lsp_server_exit call s:server_exited()
"   augroup END
  call s:server_initialized()
endfunction

function! easycomplete#sources#vim#completor(opt, ctx) abort
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
  return v:true
endfunction


function! s:server_initialized() abort
  let l:server_names = lsp#get_server_names()
  for l:server_name in l:server_names
    if has_key(s:servers, l:server_name)
      continue
    endif
    let l:init_capabilities = lsp#get_server_capabilities(l:server_name)
    " echom s:servers
    " echom l:server_name
    " echom l:init_capabilities
    if !has_key(l:init_capabilities, 'completionProvider')
      continue
    endif

    let l:server = lsp#get_server_info(l:server_name)
    let l:name = s:generate_asyncomplete_name(l:server_name)
    let l:source_opt = {
          \ 'name': l:name,
          \ 'completor': function('s:completor', [l:server]),
          \ }
    if type(l:init_capabilities['completionProvider']) == type({}) && has_key(l:init_capabilities['completionProvider'], 'triggerCharacters')
      let l:source_opt['triggers'] = { '*': l:init_capabilities['completionProvider']['triggerCharacters'] }
    endif
    if has_key(l:server, 'allowlist')
      let l:source_opt['allowlist'] = l:server['allowlist']
    elseif has_key(l:server, 'whitelist')
      let l:source_opt['allowlist'] = l:server['whitelist']
    endif
    if has_key(l:server, 'blocklist')
      let l:source_opt['blocklist'] = l:server['blocklist']
    elseif has_key(l:server, 'blacklist')
      let l:source_opt['blocklist'] = l:server['blacklist']
    endif
    if has_key(l:server, 'priority')
      let l:source_opt['priority'] = l:server['priority']
    endif
    " call asyncomplete#register_source(l:source_opt)
    call add(l:source_opt['allowlist'], "*")
    call easycomplete#RegisterSource(l:source_opt)
    " echom l:source_opt
    let s:servers[l:server_name] = 1
  endfor
endfunction

function! s:server_exited() abort
  let l:server_names = lsp#get_server_names()
  for l:server_name in l:server_names
    if !has_key(s:servers, l:server_name)
      continue
    endif
    let l:name = s:generate_asyncomplete_name(l:server_name)
    if s:servers[l:server_name]
      call asyncomplete#unregister_source(l:name)
    endif
    unlet s:servers[l:server_name]
  endfor
endfunction

function! s:generate_asyncomplete_name(server_name) abort
  return 'asyncomplete_lsp_' . a:server_name
endfunction

function! s:completor(server, opt, ctx) abort
  let l:position = lsp#get_position()
  call lsp#send_request(a:server['name'], {
        \ 'method': 'textDocument/completion',
        \ 'params': {
        \   'textDocument': lsp#get_text_document_identifier(),
        \   'position': l:position,
        \ },
        \ 'on_notification': function('s:handle_completion', [a:server, l:position, a:opt, a:ctx]),
        \ })
  return v:true
endfunction

function! s:handle_completion(server, position, opt, ctx, data) abort
  if lsp#client#is_error(a:data) || !has_key(a:data, 'response') || !has_key(a:data['response'], 'result')
    return
  endif

  let l:options = {
        \ 'server': a:server,
        \ 'position': a:position,
        \ 'response': a:data['response'],
        \ }

  let l:completion_result = lsp#omni#get_vim_completion_items(l:options)

  let l:col = a:ctx['col']
  let l:typed = a:ctx['typed']
  let l:kw = matchstr(l:typed, get(b:, 'asyncomplete_refresh_pattern', '\k\+$'))
  let l:kwlen = len(l:kw)
  let l:startcol = l:col - l:kwlen

  " call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:completion_result['items'], l:completion_result['incomplete'])
  call easycomplete#complete(a:opt['name'],   a:ctx, l:startcol, l:completion_result['items'])
endfunction
