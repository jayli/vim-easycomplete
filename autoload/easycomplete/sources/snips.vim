
function! easycomplete#sources#snips#completor(opt, ctx)

  return v:true


  let l:typing = a:ctx['typing']
  if index(['.','/',':'], a:ctx['char']) >= 0
    return v:true
  endif


  if strlen(l:typing) == 0
    return v:true
  endif


   let suggestions = []
   let snippets = UltiSnips#SnippetsInCurrentScope()

   for trigger in keys(snippets)
      let description = get(snippets, trigger)
      call add(suggestions, {
         \ 'word' : trigger,
         \ 'kind' : 'S',
         \ 'menu' : '[S]' . ' '. description,
         \ 'info' : "sdfdsfdsfs"
         \ })
   endfor

  " 这里异步和非异步都可以
  " call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], suggestions)
  " call timer_start(0, { -> easycomplete#sources#buf#asyncHandler(l:typing, a:opt['name'], a:ctx, a:ctx['startcol'])})
  " call easycomplete#util#AsyncRun(function('s:CompleteHandler'), [l:typing, a:opt['name'], a:ctx, a:ctx['startcol']], 0)
  return v:true
endfunction

