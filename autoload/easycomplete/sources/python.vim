if get(g:, 'easycomplete_sources_python')
  finish
endif
let g:easycomplete_sources_python = 1

function! easycomplete#sources#python#constructor(opt, ctx)
  if executable('pyls')
    " pip install python-language-server
    call lsp#register_server({
          \ 'name': 'pyls',
          \ 'cmd': {server_info->['pyls']},
          \ 'allowlist': ['python'],
          \ })
  endif
  " if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
endfunction

function! easycomplete#sources#python#completor(opt, ctx) abort
  " call lsp#omni#completor()
  let l:info = s:find_complete_servers()
  " echom l:info['server_names']
  if empty(l:info['server_names'])
    return []
  endif

  call s:send_completion_request(l:info)
  return v:true
endfunction

function! s:find_complete_servers() abort
  let l:server_names = []
  for l:server_name in lsp#get_allowed_servers()
    let l:init_capabilities = lsp#get_server_capabilities(l:server_name)
    if has_key(l:init_capabilities, 'completionProvider')
      " TODO: support triggerCharacters
      call add(l:server_names, l:server_name)
    endif
  endfor

  return { 'server_names': l:server_names }
endfunction

function! s:send_completion_request(info) abort
  let l:server_name = a:info['server_names'][0]
  call lsp#send_request(l:server_name, {
        \ 'method': 'textDocument/completion',
        \ 'params': {
        \   'textDocument': lsp#get_text_document_identifier(),
        \   'position': lsp#get_position(),
        \   'context': { 'triggerKind': 1 },
        \ },
        \ 'on_notification': function('s:handle_omnicompletion', [l:server_name]),
        \ })
endfunction

function! s:handle_omnicompletion(server_name, data) abort
  if lsp#client#is_error(a:data) || !has_key(a:data, 'response') || !has_key(a:data['response'], 'result')
    echom "error jayli"
    return
  endif

  let l:result = s:get_completion_result(a:server_name, a:data)
  let l:matches = l:result['matches']

  let l:ctx = easycomplete#context()
  call easycomplete#complete('python', l:ctx, l:ctx['startcol'], l:matches)
endfunction

function! s:get_completion_result(server_name, data) abort
  let l:result = a:data['response']['result']

  let l:response = a:data['response']

  " 这里包含了 info document 和 matches
  " echom l:response

  " let l:completion_result = lsp#omni#get_vim_completion_items(l:options)
  let l:completion_result = s:GetVimCompletionItems(l:response)

  return {'matches': l:completion_result['items'], 'incomplete': l:completion_result['incomplete'] }
endfunction

function! s:GetVimCompletionItems(response)
  let l:result = a:response['result']
  if type(l:result) == type([])
    let l:items = l:result
    let l:incomplete = 0
  elseif type(l:result) == type({})
    let l:items = l:result['items']
    let l:incomplete = l:result['isIncomplete']
  else
    let l:items = []
    let l:incomplete = 0
  endif

  let l:vim_complete_items = []
  for l:completion_item in l:items
    let l:expandable = get(l:completion_item, 'insertTextFormat', 1) == 2
    let l:vim_complete_item = {
          \ 'kind': get(l:completion_item, 'kind', ''),
          \ 'dup': 1,
          \ 'menu' : "[PY]",
          \ 'empty': 1,
          \ 'icase': 1,
          \ }
    if has_key(l:completion_item, 'textEdit') && type(l:completion_item['textEdit']) == type({}) && has_key(l:completion_item['textEdit'], 'nextText')
      let l:vim_complete_item['word'] = l:completion_item['textEdit']['nextText']
    elseif has_key(l:completion_item, 'insertText') && !empty(l:completion_item['insertText'])
      let l:vim_complete_item['word'] = l:completion_item['insertText']
    else
      let l:vim_complete_item['word'] = l:completion_item['label']
    endif

    if l:expandable
      let l:vim_complete_item['word'] = lsp#utils#make_valid_word(substitute(l:vim_complete_item['word'], '\$[0-9]\+\|\${\%(\\.\|[^}]\)\+}', '', 'g'))
      let l:vim_complete_item['abbr'] = l:completion_item['label'] . '~'
    else
      let l:vim_complete_item['abbr'] = l:completion_item['label']
    endif

    let l:vim_complete_item['info'] = s:NormalizeInfo(get(l:completion_item, "documentation", ""))
    " echom l:vim_complete_item

    let l:vim_complete_items += [l:vim_complete_item]
  endfor

  return { 'items': l:vim_complete_items, 'incomplete': l:incomplete }
endfunction

function! s:NormalizeInfo(info)
  let li = split(a:info, "\n")
  return li
endfunction

function! easycomplete#sources#python#GotoDefinition(...)
  return v:false
  let ext = tolower(easycomplete#util#extention())
  if index(["py"], ext) >= 0
    let l:ctx = easycomplete#context()
    call lsp#tagfunc(expand('<cword>'), mode(), l:ctx['filepath'])
    " call s:GotoDefinition(l:ctx["filepath"], l:ctx["lnum"], l:ctx["col"])
    " return v:true 成功跳转，告知主进程
    return v:true
  endif
  " exec "tag ". expand('<cword>')
  " 未成功跳转，则交给主进程处理
  return v:false
endfunction


function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes
  if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
  " nmap <buffer> gd <plug>(lsp-definition)
  " nmap <buffer> gs <plug>(lsp-document-symbol-search)
  " nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
  " nmap <buffer> gr <plug>(lsp-references)
  " nmap <buffer> gi <plug>(lsp-implementation)
  " nmap <buffer> gt <plug>(lsp-type-definition)
  " nmap <buffer> <leader>rn <plug>(lsp-rename)
  " nmap <buffer> [g <plug>(lsp-previous-diagnostic)
  " nmap <buffer> ]g <plug>(lsp-next-diagnostic)
  " nmap <buffer> K <plug>(lsp-hover)
  " inoremap <buffer> <expr><c-f> lsp#scroll(+4)
  " inoremap <buffer> <expr><c-d> lsp#scroll(-4)

  let g:lsp_format_sync_timeout = 1000
  " autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

  " refer to doc to add more commands
endfunction
