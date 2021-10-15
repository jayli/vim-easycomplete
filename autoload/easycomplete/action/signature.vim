
function! easycomplete#action#signature#do()
  call easycomplete#action#signature#LspRequest()
endfunction

function! easycomplete#action#signature#ShouldFire()
  let typed = s:GetTyped()
  if typed =~ "\\w($" || typed =~ "\\w(.*,$"
    return v:true
  endif
  return v:false
endfunction

function! easycomplete#action#signature#ShouldClose()
  let typed = s:GetTyped()
  if typed =~ ")$"
    return v:true
  endif
  return v:false
endfunction

function! s:GetTyped()
  let ctx = easycomplete#context()
  let linenr = 10
  if line(".") == 1
    let typed = trim(ctx["typed"])
  else
    let start_line_nr = line(".") - linenr <= 0 ? 0 : line(".") - linenr
    let lines = getline(start_line_nr, line(".") - 1)
    let prelines = trim(join(lines, " "))
    let typed = prelines . " " . trim(ctx["typed"])
  endif
  return typed
endfunction

function! easycomplete#action#signature#LspRequest() abort
  call s:console('--->','signature lsprequest')
  let l:servers = filter(easycomplete#lsp#get_allowed_servers(),
        \ 'easycomplete#lsp#has_signature_help_provider(v:val)')
  if len(l:servers) == 0
    return
  endif

  let l:position = easycomplete#lsp#get_position()
  for l:server in l:servers
    call easycomplete#lsp#send_request(l:server, {
          \ 'method': 'textDocument/signatureHelp',
          \ 'params': {
          \   'textDocument': easycomplete#lsp#get_text_document_identifier(),
          \   'position': l:position,
          \ },
          \ 'on_notification': function('s:HandleLspCallback', [l:server]),
          \ })
  endfor
  return
endfunction

function! s:HandleLspCallback(server, data) abort
  call s:console('<---', a:data)
  try
    if easycomplete#lsp#client#is_error(a:data['response'])
      call easycomplete#lsp#utils#error('Failed ' . a:server)
      call s:flush()
      return
    endif

    if !has_key(a:data['response'], 'result')
      call s:flush()
      return
    endif

    if !empty(a:data['response']['result']) && !empty(a:data['response']['result']['signatures'])
      " Get current signature.
      let l:signatures = get(a:data['response']['result'], 'signatures', [])
      let l:signature_index = get(a:data['response']['result'], 'activeSignature', 0)
      let l:signature = get(l:signatures, l:signature_index, {})
      if empty(l:signature)
        call s:flush()
        return
      endif

      " Signature label.
      let l:label = l:signature['label']

      " Mark current parameter.
      if has_key(a:data['response']['result'], 'activeParameter')
        let l:parameters = get(l:signature, 'parameters', [])
        let l:parameter_index = a:data['response']['result']['activeParameter']
        let l:parameter = get(l:parameters, l:parameter_index, {})
        let l:parameter_label = s:GetParameterLabel(l:signature, l:parameter)
        if !empty(l:parameter_label)
          let l:label = substitute(l:label, '\V\(' . escape(l:parameter_label, '\/?') . '\)', '`\1`', 'g')
        endif
      endif

      let l:contents = [l:label]

      if exists('l:parameter')
        let l:parameter_doc = s:GetParameterLabel(l:signature,l:parameter)
        if !empty(l:parameter_doc)
          call add(l:contents, '')
          call add(l:contents, l:parameter_doc)
          call add(l:contents, '')
        endif
      endif

      if has_key(l:signature, 'documentation')
        call add(l:contents, l:signature['documentation'])
      endif

      call s:SignatureCallback(l:contents)
      return
    else
      " signature help is used while inserting. So this must be graceful.
      "call lsp#utils#error('No signature help information found')
    endif
  catch
    call s:console(v:exception)

  endtry
endfunction

function! s:SignatureCallback(response)
  let title = a:response[0]
  let kind = a:response[1]["kind"]
  let content = a:response[1]["value"]
  call s:console(title,kind,content)
  let content = substitute(content, "```", "", "g")
  let content = split(content, "\\n")

  call s:console('<---', 'signature callback', content)
  call easycomplete#popup#float([title,'----'] + content, 'Pmenu', 1, "", [0,0])
endfunction

function! s:GetParameterLabel(signature, parameter) abort
  if has_key(a:parameter, 'label')
    if type(a:parameter['label']) == type([])
      let l:string_range = a:parameter['label']
      return strcharpart(
            \ a:signature['label'],
            \ l:string_range[0],
            \ l:string_range[1] - l:string_range[0])
    endif
    return a:parameter['label']
  endif
  return ''
endfunction

function! s:flush()
  call easycomplete#popup#close("float")
endfunction

function! s:console(...)
  return call('easycomplete#log#log', a:000)
endfunction
