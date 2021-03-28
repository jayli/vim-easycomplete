if exists('g:easycomplete_gocode')
  finish
endif
let g:easycomplete_gocode = 1

function! easycomplete#sources#go#constructor(opt, ctx)
  "augroup LspGo
  "  au!
  "  autocmd User lsp_setup call lsp#register_server({
  "        \ 'name': 'go-lang',
  "        \ 'cmd': {server_info->['gopls']},
  "        \ 'whitelist': ['go'],
  "        \ })
  "  autocmd FileType go setlocal omnifunc=lsp#complete
  "  "autocmd FileType go nmap <buffer> gd <plug>(lsp-definition)
  "  "autocmd FileType go nmap <buffer> ,n <plug>(lsp-next-error)
  "  "autocmd FileType go nmap <buffer> ,p <plug>(lsp-previous-error)
  "augroup END
endfunction

function! easycomplete#sources#go#completor(opt, ctx) abort
  call easycomplete#util#AsyncRun(function("s:DoComplete"), [a:opt, a:ctx], 2)
  return v:true
endfunction

function! s:DoComplete(opt, ctx)
  let res_str = s:GocodeAutocomplete()
  execute "silent let result = " . res_str
  if len(result) < 2
    call s:done(a:opt, a:ctx)
    return
  endif
  let complete_result = s:normalize(result[1])
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], complete_result)
endfunction

function! s:normalize(items)
  let res = []
  for item in a:items
    let info = []
    if !empty(item.abbr)
      call add(info, item.abbr)
    endif
    if has_key(item, "info") && !empty(item.info) && item.info != item.abbr
      call add(info, "----")
      call add(info, item.info)
    endif
    call add(res, {
          \ "word": item.word,
          \ "menu": "[GO]",
          \ "kind": "",
          \ "info": info
          \ })
  endfor
  return res
endfunction

function! s:done(opt, ctx)
  call easycomplete#complete(a:opt['name'], a:ctx, a:ctx['startcol'], [])
endfunction

function! s:GocodeCurrentBuffer()
  let buf = getline(1, '$')
  if &encoding != 'utf-8'
    let buf = map(buf, 'iconv(v:val, &encoding, "utf-8")')
  endif
  if &l:fileformat == 'dos'
    " XXX: line2byte() depend on 'fileformat' option.
    " so if fileformat is 'dos', 'buf' must include '\r'.
    let buf = map(buf, 'v:val."\r"')
  endif
  let file = tempname()
  call writefile(buf, file)
  return file
endfunction

function! s:system(str, ...)
  return call("system", [a:str] + a:000)
endfunction

function! s:GocodeShellescape(arg)
  try
    let ssl_save = &shellslash
    set noshellslash
    return shellescape(a:arg)
  finally
    let &shellslash = ssl_save
  endtry
endfunction

function! s:GocodeCommand(cmd, preargs, args)
  for i in range(0, len(a:args) - 1)
    let a:args[i] = s:GocodeShellescape(a:args[i])
  endfor
  for i in range(0, len(a:preargs) - 1)
    let a:preargs[i] = s:GocodeShellescape(a:preargs[i])
  endfor
  let result = s:system(printf('gocode %s %s %s', join(a:preargs), a:cmd, join(a:args)))
  echom result
  if v:shell_error != 0
    return "[\"0\", []]"
  else
    if &encoding != 'utf-8'
      let result = iconv(result, 'utf-8', &encoding)
    endif
    return result
  endif
endfunction

function! s:GocodeCurrentBufferOpt(filename)
  return '-in=' . a:filename
endfunction

fu! s:GocodeCursor()
  if &encoding != 'utf-8'
    let c = col('.')
    let buf = line('.') == 1 ? "" : (join(getline(1, line('.')-1), "\n") . "\n")
    let buf .= c == 1 ? "" : getline('.')[:c-2]
    return printf('%d', len(iconv(buf, &encoding, "utf-8")))
  endif
  return printf('%d', line2byte(line('.')) + (col('.')-2))
endf

function! s:GocodeAutocomplete()
  let filename = s:GocodeCurrentBuffer()
  let result = s:GocodeCommand('autocomplete',
        \ [s:GocodeCurrentBufferOpt(filename), '-f=vim'],
        \ [expand('%:p'), s:GocodeCursor()])
  echom result
  call delete(filename)
  return result
endfunction

function! s:Complete(findstart, base)
  "findstart = 1 when we need to get the text length
  if a:findstart == 1
    execute "silent let g:gocomplete_completions = " . s:GocodeAutocomplete()
    return col('.') - g:gocomplete_completions[0] - 1
    "findstart = 0 when we need to return the list of completions
  else
    return g:gocomplete_completions[1]
  endif
endfunction
