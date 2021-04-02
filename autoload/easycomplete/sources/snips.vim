
function! easycomplete#sources#snips#completor(opt, ctx)
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

  for trigger in keys(snippets)
    let description = get(snippets, trigger)
    call add(suggestions, {
          \ 'word' : trigger,
          \ 'kind' : 'S',
          \ 'menu' : '[S]',
          \ 'info' : description
          \ })
  endfor

  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], suggestions)
  return v:true
endfunction

function! easycomplete#sources#snips#constructor(...)
  " Do Nothing
endfunction

