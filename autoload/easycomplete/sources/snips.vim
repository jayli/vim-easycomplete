
function! easycomplete#sources#snips#completor(opt, ctx)
  if !exists("*UltiSnips#SnippetsInCurrentScope")
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  let l:typing = a:ctx['typing']
  if index(['.','/',':'], a:ctx['char']) >= 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif

  if strlen(l:typing) == 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif

  let suggestions = []
  let snippets = UltiSnips#SnippetsInCurrentScope()
  call UltiSnips#SnippetsInCurrentScope(1)

  for trigger in keys(snippets)
    let description = get(snippets, trigger)
    let description = empty(description) ? "Snippet: " . trigger : description
    let snip_object = s:get_snip_object(trigger, g:current_ulti_dict_info)
    " TODO Vim 性能比 Python 快五倍
    if has('python3')
      let code_info = easycomplete#python#GetSnippetsCodeInfo(snip_object)
    else
      let code_info = easycomplete#util#GetSnippetsCodeInfo(snip_object)
    endif
    call add(suggestions, {
          \ 'word' : trigger,
          \ 'abbr' : trigger . '~',
          \ 'kind' : 's',
          \ 'menu' : '[S]',
          \ 'info' : [description, "-----"] + code_info
          \ })
  endfor

  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], suggestions)
  return v:true
endfunction

function! s:get_snip_object(trigger, current_ulti_dict_info)
  let info_str = get(a:current_ulti_dict_info, a:trigger)['location']
  let info_str_array = split(info_str, ":")
  let snip_object = {}
  let snip_object.filepath = info_str_array[0]
  let snip_object.line_number = info_str_array[1]
  return snip_object
endfunction

function! easycomplete#sources#snips#constructor(...)
  " Do Nothing
endfunction

function! s:log(...)
  return call('easycomplete#util#log', a:000)
endfunction

function! s:once(...)
  return call('easycomplete#util#once', a:000)
endfunction

