function! easycomplete#sources#vsnip#completor(opt, ctx) abort
  if !easycomplete#VsnipSupports()
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  if index(['.', '/', ':'], a:ctx['char']) >= 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  let l:typing = a:ctx['typing']
  if strlen(l:typing) == 0
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  if len(matchstr(a:ctx['line'], s:GetKeywordPattern() . '$')) < 1
    call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
    return v:true
  endif
  call easycomplete#util#AsyncRun(
        \ function('s:CompleteHandler'),
        \ [l:typing, a:opt['name'], a:ctx, a:ctx['startcol']],
        \ 1)
  return v:true
endfunction

function! s:CompleteHandler(typing, name, ctx, startcol) abort
  let suggestions = vsnip#get_complete_items(a:ctx['bufnr'])
  for snippet in suggestions
    let menu = substitute(snippet.menu, '^\[.*\] ', '', '')
    call extend(snippet, {
          \ 'abbr': snippet.abbr . '~',
          \ 'kind': g:easycomplete_kindflag_vsnip,
          \ 'menu': g:easycomplete_menuflag_vsnip . ' ' . menu,
          \ 'info': ['Snippet: ' . menu, '-----'] + json_decode(snippet.user_data).vsnip.snippet,
          \ })
  endfor
  call easycomplete#complete(a:name, a:ctx, a:startcol, suggestions)
endfunction

function! easycomplete#sources#vsnip#constructor(...) abort
  " Do Nothing
endfunction

function! s:GetKeywordPattern() abort
  let l:keywords = split(&iskeyword, ',')
  let l:keywords = filter(l:keywords, { _, k -> match(k, '\d\+-\d\+') == -1 })
  let l:keywords = filter(l:keywords, { _, k -> k !=# '@' })
  let l:pattern = '\%(' . join(map(l:keywords, { _, v -> '\V' . escape(v, '\') . '\m' }), '\|') . '\|\w\)*'
  return l:pattern
endfunction

function! s:log(...) abort
  return call('easycomplete#util#log', a:000)
endfunction

function! s:once(...) abort
  return call('easycomplete#util#once', a:000)
endfunction

function! s:console(...) abort
  return call('easycomplete#log#log', a:000)
endfunction
